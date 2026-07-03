# MIDO DB 효율화 정리

PostgreSQL 운영 DB·분석 DB·쿼리·인덱스 관련 효율화 내용 요약.

```
운영 DB (OLTP)                    분석 DB (OLAP)
─────────────────                 ─────────────────
단건 CRUD, PK/FK 조회      →      집계, 리포트, 대시보드
정규화, LOB 분리                  Star Schema, Summary Table
인덱스 + EXPLAIN                  증분 ETL / CDC
```

---

## 1. DB 목표 지표

| 지표 | 목표 | 측정 |
| --- | --- | --- |
| 단일 쿼리 실행 시간 | **< 100ms** | `EXPLAIN ANALYZE`, pg_stat_statements |
| 목록 조회 읽기 row | 필요 row만 | EXPLAIN `rows`, LOB 제외 |
| API당 쿼리 수 | **≤ 2~3** (N+1 없음) | datasource-proxy, 테스트 |
| 스토리지 증가 | LOB(code) 월별 추적 | DB 용량 모니터링 |
| 데이터 품질 오류 | **0건** | unique, not_null, FK 위반 |

---

## 2. 현재 DB 구조 (구현 ✅)

### 2.1 테이블 · 관계

```
verification_data (중심)
  ├── 1:N  manual_input
  ├── 1:N  uploaded_file
  └── 1:1  work_context
```

| 테이블 | PK | FK | 책임 |
| --- | --- | --- | --- |
| `verification_data` | id (UUID) | — | 세션 메타, code(LOB) |
| `manual_input` | id | verification_data_id | 입력 원본(rawInput) |
| `uploaded_file` | id | verification_data_id | 파일 메타 + file_content |
| `work_context` | id | verification_data_id (1:1) | 맥락 표시용 스냅샷 |

### 2.2 이미 DB 관점에서 잘 된 것

| 항목 | 효과 |
| --- | --- |
| **테이블 책임 분리** | 입력·파일·맥락이 별도 테이블 → 목록에서 JOIN 선택 가능 |
| **UUID PK** | 분산 생성, URL 노출 안전 |
| **1:1 work_context** | 맥락 조회 시 단일 FK 조회 |
| **upload 시 부분 UPDATE** | `code`, `updated_at`만 갱신 (전 row replace 아님) |
| **Query Method** | `findByVerificationData_Id`, `findTopBy...Desc` — FK 인덱스 전제 |
| **Context API** | `WorkContextResponse`만 반환 — code LOB 미조회 |
| **@Transactional** | 3테이블 insert 원자성 — 부분 저장 방지 |

### 2.3 현재 갭 (DB)

| Gap | 문제 | 영향 |
| --- | --- | --- |
| **G-001** | `status` 컬럼 없음 (DTO만) | status 필터·인덱스 불가 |
| **ddl-auto: update** | Flyway 미사용 | 환경별 스키마 불일치 위험 |
| **인덱스 없음** | Hibernate auto만 | 목록 조회 Seq Scan 예상 |
| **FK 제약 미명시** | JPA 관계만 | DB 레벨 무결성 약함 |
| **code LOB 중복** | verification_data.code + uploaded_file.file_content | 스토리지 2배 |

---

## 3. 데이터 모델 효율화 (정리 ✅ / 적용 일부)

### 3.1 테이블별 넣지 말 것

| 테이블 | 넣으면 안 되는 것 |
| --- | --- |
| verification_data | rawInput 전체, 판단 결과, 승인 정보 |
| manual_input | code, decision |
| work_context | code 본문 |
| decision_log (예정) | code, fileContent |

### 3.2 중복 처리 방침

```
verification_data.repo_url/commit_hash/pr_number  ← 원본
work_context.display_*                              ← 생성 시점 스냅샷 (의도적 비정규화)
```

- **목록 API:** `verification_data`만 조회 (work_context JOIN 생략)
- **code 단일 소스:** 검증용 code는 `verification_data`만. `uploaded_file.file_content`는 이력용

### 3.3 MVP-2 이후 테이블 (예정)

| 테이블 | 관계 | DB 효율 포인트 |
| --- | --- | --- |
| `decision_log` | 1:1 verification | append-only, UNIQUE(verification_data_id) |
| `risk_assessment` | N:1 verification | 분석 결과 분리, code와 분리 |
| `approval` | 1:1 decision_log | 승인 이력 분리 |

---

## 4. 정규화 원칙

| 원칙 | MIDO 적용 |
| --- | --- |
| 한 테이블에 모든 데이터 X | LOB·이력·집계 분리 |
| 중복 최소화 | rationale → decision_log만 |
| 무결성 | FK + NOT NULL + CHECK + UNIQUE |
| 수정 이상 방지 | decision_log UPDATE/DELETE 금지 |

### OLTP vs OLAP 분리

| 용도 | DB | 설계 |
| --- | --- | --- |
| Verification CRUD | 운영 PostgreSQL | 3NF, 정규화 |
| 팀별 판단 통계 | 분석 DB | Star Schema |
| 일별 건수·완료율 | summary table | 비정규화 허용 |

---

## 5. SQL · 쿼리 최적화

### 5.1 원칙

| ❌ 피할 것 | ✅ 할 것 |
| --- | --- |
| `SELECT *` (특히 LOB) | 필요 컬럼만 Projection |
| 목록에서 `code` 조회 | 상세 API에서만 LOB |
| `findAll()` 후 메모리 필터 | `WHERE` + `LIMIT` |
| 불필요 JOIN | 목록은 verification_data 단독 |
| N+1 lazy load | Fetch Join 또는 `@EntityGraph` |

### 5.2 MIDO 쿼리 패턴별 권장

| API | 쿼리 패턴 | 쿼리 수 목표 |
| --- | --- | --- |
| POST /manual | INSERT × 3 (트랜잭션) | 3 |
| POST /upload | SELECT + INSERT + UPDATE | 3 |
| GET /context | work_context 1건 + (FILE 시 file 1건) | ≤ 2 |
| GET /list (예정) | Projection + pagination | 1 |
| GET /{id} 상세 (예정) | Fetch Join 또는 2~3 쿼리 | ≤ 3 |

### 5.3 LOB 핵심 규칙

> **`verification_data.code`, `uploaded_file.file_content`는 목록·통계 쿼리에 절대 포함하지 않는다.**

```java
// 목록용 Projection (예정)
@Query("""
    SELECT new ...VerificationSummary(v.id, v.inputType, v.status, v.createdAt)
    FROM VerificationData v WHERE v.status = :status
    """)
Page<VerificationSummary> findSummaries(...);
```

---

## 6. 인덱스 설계 (📋 설계만, 미적용)

### 6.1 권장 DDL

```sql
-- 목록: status + 최신순 (가장 중요)
CREATE INDEX idx_verification_status_created
  ON verification_data(status, created_at DESC);

-- 유형별 통계
CREATE INDEX idx_verification_input_type_created
  ON verification_data(input_type, created_at);

-- work_context 1:1 FK
CREATE UNIQUE INDEX uq_work_context_verification
  ON work_context(verification_data_id);

-- FILE 모드 최신 파일
CREATE INDEX idx_uploaded_file_verification_uploaded
  ON uploaded_file(verification_data_id, uploaded_at DESC);

-- manual_input FK
CREATE INDEX idx_manual_input_verification
  ON manual_input(verification_data_id);
```

### 6.2 Partial Index (DRAFT 목록 많을 때)

```sql
CREATE INDEX idx_verification_draft_created
  ON verification_data(created_at DESC)
  WHERE status = 'DRAFT';
```

### 6.3 인덱스 설계 기준

| 컬럼 용도 | 인덱스 대상 |
| --- | --- |
| WHERE `status`, `input_type` | ✅ |
| JOIN `verification_data_id` | ✅ UNIQUE 또는 INDEX |
| ORDER BY `created_at DESC` | ✅ 복합 인덱스 뒤쪽 |
| LOB `code` | ❌ 인덱스 불가·불필요 |

**트레이드오프:** 인덱스는 SELECT 빠르게, INSERT/UPDATE 느리게. EXPLAIN으로 확인 후 추가.

---

## 7. 실행계획 (EXPLAIN)

### 점검 명령

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT id, input_type, status, created_at
FROM verification_data
WHERE status = 'DRAFT'
ORDER BY created_at DESC
LIMIT 20;
```

### 판단 기준

| 계획 | 조치 |
| --- | --- |
| **Seq Scan** + rows 많음 | 인덱스 추가 |
| **Index Scan** | ✅ |
| **Sort** 비용 큼 | ORDER BY 컬럼을 인덱스에 포함 |
| **Nested Loop** 반복 | N+1 의심 → Fetch Join |
| 예상 rows ≠ 실제 rows | `ANALYZE verification_data;` |

---

## 8. 분석 DB · Summary (v1.0 예정)

### 8.1 Star Schema

| 유형 | 테이블 | 역할 |
| --- | --- | --- |
| Fact | `fact_verification_decision` | 판단 건수, 소요 시간, 리스크 수 |
| Dim | `dim_date`, `dim_team`, `dim_user`, `dim_input_type` | 필터·그룹핑 |

### 8.2 Summary Table (운영 DB 부하 분리)

```sql
CREATE TABLE summary_daily_decision (
  summary_date   DATE PRIMARY KEY,
  total_count    BIGINT,
  done_count     BIGINT,
  use_count      BIGINT,
  fix_count      BIGINT,
  ignore_count   BIGINT,
  avg_decide_sec NUMERIC(10,2),
  updated_at     TIMESTAMPTZ
);
```

- 대시보드는 **summary 조회** — 매번 verification_data 전체 집계 X

### 8.3 증분 ETL

```sql
SELECT * FROM verification_data
WHERE updated_at > :last_synced_at
ORDER BY updated_at LIMIT 10000;
```

- Full Load X → `updated_at` watermark로 변경분만

---

## 9. 대용량 대비 (데이터 많아질 때)

| 기법 | 적용 시점 | MIDO |
| --- | --- | --- |
| **Pagination** | list API 추가 시 | LIMIT 20, 커서 페이징 |
| **파티셔닝** | 월 100만+ row | `created_at` 월별 RANGE |
| **Materialized View** | 일별 리포트 | `mv_monthly_verification` |
| **아카이브** | code LOB 오래된 건 | cold storage 분리 |
| **CDC** | 실시간 분석 | Debezium (v1.0+) |

---

## 10. 데이터 품질 (DB 제약)

```sql
-- decision_log (MVP-2)
ALTER TABLE decision_log
  ADD CONSTRAINT chk_decision CHECK (decision IN ('USE', 'FIX', 'IGNORE'));

CREATE UNIQUE INDEX uq_decision_per_verification
  ON decision_log(verification_data_id);

-- status (G-001)
ALTER TABLE verification_data
  ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'DRAFT';
```

| 테스트 | 검증 |
| --- | --- |
| unique | verification당 decision 1건 |
| not_null | input_type, status |
| accepted_values | decision, input_type enum |
| relationships | orphan FK 0건 |
| 날짜 역전 | decided_at >= created_at |

---

## 11. 테이블별 최적화 치트시트

| 테이블 | 자주 쓰는 조회 | 인덱스 | LOB 주의 |
| --- | --- | --- | --- |
| verification_data | PK, status+날짜 목록 | (status, created_at DESC) | code 목록 제외 |
| work_context | verification_data_id | UNIQUE(verification_data_id) | — |
| uploaded_file | 최신 1건 | (verification_data_id, uploaded_at DESC) | file_content |
| manual_input | verification_data_id | (verification_data_id) | raw_input |
| decision_log | decided_at, verification_id | UNIQUE(verification_id) | — |

---

## 12. 적용 순서 (DB만)

```
Phase 1 — 스키마 기반
  ① Flyway 도입 (ddl-auto: validate)
  ② status 컬럼 추가 (G-001)
  ③ FK / UNIQUE / CHECK 제약 DB 레벨 추가

Phase 2 — 쿼리 성능
  ④ list API용 인덱스 생성
  ⑤ Projection + Pagination
  ⑥ EXPLAIN ANALYZE로 Index Scan 확인
  ⑦ N+1 제거 (Fetch Join / 쿼리 수 테스트)

Phase 3 — 분리 · 확장
  ⑧ decision_log, risk_assessment 테이블
  ⑨ summary_daily_decision + 증분 ETL
  ⑩ 분석 DB Star Schema
  ⑪ 파티셔닝 / LOB 아카이브 (필요 시)
```

---

## 13. 다음 할 일 Top 5 (DB)

| # | 작업 | 이유 |
| --- | --- | --- |
| 1 | **Flyway V1~V3 migration** | 스키마 버전 관리, status 컬럼 |
| 2 | **인덱스 DDL** | 목록 Seq Scan 방지 |
| 3 | **list API + Projection** | LOB 읽기 제거 |
| 4 | **FK/UNIQUE 제약** | 무결성 + 중복 판단 방지 |
| 5 | **EXPLAIN + 쿼리 수 테스트** | 100ms, N+1 목표 검증 |

---

## 참고

| 문서 | 내용 |
| --- | --- |
| [DATA_PERFORMANCE_GUIDE.md](./DATA_PERFORMANCE_GUIDE.md) | 상세 (파티셔닝, Airflow, Spark) |
| [EFFICIENCY_SUMMARY.md](./EFFICIENCY_SUMMARY.md) | 코드+DB 통합 요약 |
| [SRS.md](./SRS.md) §7 데이터 요구사항 |
