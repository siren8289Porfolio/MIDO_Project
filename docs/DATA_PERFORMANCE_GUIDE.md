# MIDO Data & Performance Guide

데이터 모델링, DB 최적화, 분석 파이프라인, 모니터링을 MIDO Verification Workflow에 적용하기 위한 가이드.

```
운영 DB (OLTP)          분석 DB (OLAP / Star Schema)
     ↓                           ↓
API 응답 최적화              대시보드 / 리포트
     ↓                           ↓
인덱스 / 쿼리 튜닝    →    ETL / CDC / Summary Table
```

---

## 1. 효율화 지표 잡기

측정하지 않으면 개선할 수 없다. MIDO에서 우선 추적할 지표:

| 지표 | 설명 | MIDO 적용 | 목표 (NFR-001) |
| --- | --- | --- | --- |
| **응답 시간** | API 요청 ~ 응답 (p50, p95, p99) | `POST /manual`, `GET /context` | p95 < 1초 |
| **쿼리 실행 시간** | DB 단일 쿼리 소요 | Hibernate SQL 로그, pg_stat_statements | < 100ms |
| **읽은 데이터 양** | rows read, bytes scanned | EXPLAIN ANALYZE `rows` | 불필요한 LOB 읽기 제거 |
| **CPU / 메모리** | JVM heap, GC pause, pod CPU | Actuator metrics, K8s | CPU < 70% 평균 |
| **스토리지 비용** | DB 용량, LOB(code) 증가율 | `verification_data.code`, `uploaded_file.file_content` | 월별 추이 모니터링 |
| **배치 처리 시간** | ETL/집계 job 소요 | 일별 decision 집계 DAG | SLA 내 완료 |
| **데이터 품질 오류 수** | unique/not_null 위반 건수 | DecisionLog 중복, status null | 0건 |

### 측정 도구

```yaml
# application.yml — 쿼리 통계 (PostgreSQL)
# pg_stat_statements extension 활성화 후
# SELECT query, calls, mean_exec_time, rows FROM pg_stat_statements ORDER BY mean_exec_time DESC;
```

```java
// API 응답 시간 — Micrometer
@Timed(value = "verification.create", percentiles = {0.95, 0.99})
public VerificationCreateResponse create(ManualInputRequest request) { ... }
```

---

## 2. 데이터 모델 정리

### 2.1 테이블 책임 분리 (MIDO 현재 구조)

| 테이블 | 단일 책임 | 넣지 말아야 할 것 |
| --- | --- | --- |
| `verification_data` | 판단 세션 메타 + code | rawInput 전체, fileContent 전체 |
| `manual_input` | 사용자 입력 원본 | 판단 결과, 승인 정보 |
| `uploaded_file` | 파일 메타 + 내용 | work context 표시용 중복 |
| `work_context` | 맥락 요약 (표시용) | code 본문 |
| `decision_log` | 판단 결과 (불변) | code, fileContent |
| `risk_assessment` | AI 분석 결과 | 판단 rationale |

### 2.2 중복 데이터 제거

**현재 중복:**

```
verification_data: repo_url, commit_hash, pr_number
work_context:      display_repo_url, display_commit_hash, display_pr_number
```

**개선 방향:**

- `work_context`는 **표시용 스냅샷**으로 유지하되, 생성 시점에만 복사 (BR-001)
- 목록 API에서는 `work_context` JOIN 없이 `verification_data`만 조회
- `code`는 `verification_data`에만 저장, `uploaded_file.file_content`는 **이력 보관용**으로 분리 검토

### 2.3 PK / FK 명확화

```sql
-- PK: 모든 테이블 UUID
verification_data     PK(id)
manual_input          PK(id), FK(verification_data_id) → verification_data(id)
work_context          PK(id), FK(verification_data_id) UNIQUE
decision_log          PK(id), FK(verification_data_id) UNIQUE
```

### 2.4 반복 컬럼 제거

| 반복 패턴 | 처리 |
| --- | --- |
| `created_at` 모든 테이블 | 공통 BaseEntity 추출 (선택) |
| repo/commit/pr 양쪽 존재 | work_context는 denormalized snapshot으로 문서화 |
| `code` LOB가 여러 테이블 | 단일 소스(verification_data) 원칙 |

### 2.5 업무 단위별 Entity 분리

```
[입력 단계]  ManualInput, UploadedFile
[맥락 단계]  WorkContext
[분석 단계]  RiskAssessment
[판단 단계]  DecisionLog
[승인 단계]  Approval
[기준 데이터] TeamGuideline
```

---

## 3. 운영 DB 정규화

### 3.1 원칙

| 정규화 목표 | MIDO 적용 |
| --- | --- |
| 한 테이블에 모든 데이터 넣지 않기 | code(LOB)를 목록 API에서 제외 |
| 중복 최소화 | 판단 근거는 decision_log에만 |
| 데이터 무결성 | FK + NOT NULL + UNIQUE 제약 |
| 수정/삭제 이상 방지 | DecisionLog append-only (FR-007) |

### 3.2 정규화 vs 성능 트레이드오프

```
목록 조회 (자주)  → verification_data 핵심 컬럼만 (정규화 유지)
상세 조회 (가끔)  → JOIN으로 manual_input, work_context
대시보드 (집계)   → 분석 DB / summary table (비정규화 허용)
```

### 3.3 무결성 제약 예시

```sql
ALTER TABLE decision_log
  ADD CONSTRAINT fk_decision_verification
  FOREIGN KEY (verification_data_id) REFERENCES verification_data(id);

ALTER TABLE decision_log
  ADD CONSTRAINT chk_decision_value
  CHECK (decision IN ('USE', 'FIX', 'IGNORE'));

-- 중복 판단 방지 (TC-008)
CREATE UNIQUE INDEX uq_decision_per_verification
  ON decision_log(verification_data_id);
```

---

## 4. 분석 DB Star Schema

### 4.1 운영 DB vs 분석 DB를 다르게 설계하는 이유

| 구분 | 운영 DB (OLTP) | 분석 DB (OLAP) |
| --- | --- | --- |
| 목적 | Verification 생성·판단·승인 | 팀별 판단 통계, 리스크 트렌드 |
| 쓰기 패턴 | 단건 INSERT/UPDATE | 대량 INSERT (배치) |
| 읽기 패턴 | PK 조회, 최근 N건 | 기간·팀·상태별 집계 |
| 정규화 | 높음 (3NF) | 낮음 (Star Schema) |
| 변경 | 실시간 | 일/시간 단위 반영 |

### 4.2 MIDO Star Schema 예시

```
                    ┌─────────────────┐
                    │  dim_date       │
                    │  date_key       │
                    │  year, month    │
                    └────────┬────────┘
                             │
┌──────────────┐    ┌────────┴────────────────────────┐    ┌──────────────┐
│ dim_team     │    │  fact_verification_decision     │    │ dim_input_   │
│ team_id      │───→│  verification_id                │←───│ type         │
│ team_name    │    │  decision (USE/FIX/IGNORE)      │    │ input_type   │
└──────────────┘    │  risk_count                     │    └──────────────┘
                    │  time_to_decide_sec             │
┌──────────────┐    │  approved_flag                  │
│ dim_user     │───→│  decided_by_key                 │
│ user_id      │    └─────────────────────────────────┘
│ role         │
└──────────────┘
```

### 4.3 Fact / Dimension 정의

| 유형 | MIDO 예시 | 역할 |
| --- | --- | --- |
| **Fact Table** | `fact_verification_decision` | 측정값: 판단 건수, 소요 시간, 리스크 수 |
| **Dimension** | `dim_date`, `dim_team`, `dim_user`, `dim_input_type` | 필터·그룹핑 축 |

**Fact Table에 넣을 측정값 (PRD M-001~M-005):**

- `decision_count`
- `time_to_decide_sec` (생성 ~ 판단)
- `time_to_approve_sec` (판단 ~ 승인)
- `risk_high_count`
- `rework_flag` (동일 repo+유사 code 재검증)

---

## 5. 실행계획 확인

### 5.1 EXPLAIN vs EXPLAIN ANALYZE

```sql
-- 계획만 (실행 안 함)
EXPLAIN SELECT * FROM verification_data WHERE input_type = 'PASTE';

-- 실제 실행 + 실측 시간/row 수
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT v.id, v.input_type, v.status, v.created_at
FROM verification_data v
WHERE v.status = 'DONE'
  AND v.created_at >= '2026-07-01'
ORDER BY v.created_at DESC
LIMIT 20;
```

### 5.2 실행계획 읽는 법

| 항목 | 주의 신호 |
| --- | --- |
| **Seq Scan** | 대용량 테이블 전체 읽기 → 인덱스 검토 |
| **Index Scan** | WHERE/JOIN 컬럼에 인덱스 활용 |
| **Nested Loop** | 작은 집합에 유리, N+1 패턴 주의 |
| **Hash Join** | 대용량 JOIN 시 메모리 사용 |
| **Sort** | `ORDER BY` 비용, 인덱스로 Sort 제거 가능 |
| **rows** | 예상 vs 실제 차이 크면 통계 갱신 (`ANALYZE`) |

### 5.3 MIDO 점검 쿼리

```sql
-- Work Context 조회 (FR-004) — Index Scan 기대
EXPLAIN ANALYZE
SELECT w.* FROM work_context w
WHERE w.verification_data_id = '550e8400-e29b-41d4-a716-446655440000';

-- 목록 API (향후) — Seq Scan이면 인덱스 추가
EXPLAIN ANALYZE
SELECT id, input_type, status, created_at
FROM verification_data
WHERE status = 'DRAFT'
ORDER BY created_at DESC
LIMIT 20;
```

---

## 6. SQL 최적화

### 6.1 원칙별 MIDO 적용

| 원칙 | ❌ 나쁜 예 | ✅ 좋은 예 |
| --- | --- | --- |
| SELECT * 제거 | `SELECT * FROM verification_data` | `SELECT id, input_type, status, created_at` |
| 필요한 컬럼만 | 목록에서 `code` LOB 조회 | 상세 API에서만 code 조회 |
| WHERE 명확화 | `WHERE status IS NOT NULL` | `WHERE status = 'DONE'` |
| 불필요한 JOIN 제거 | 목록에 work_context JOIN | FK로 verification_data만 |
| 중복 서브쿼리 제거 | 매 row마다 scalar subquery | JOIN 또는 윈도우 함수 |
| ORDER BY 최소화 | 인덱스 없이 대량 Sort | `(status, created_at DESC)` 인덱스 |
| Pagination | `findAll()` 후 메모리 slice | `LIMIT/OFFSET` 또는 커서 |

### 6.2 LOB 최적화 (MIDO 핵심)

```java
// ❌ 목록 조회 시 Entity 전체 로드 → code LOB까지 읽음
List<VerificationData> all = repository.findAll();

// ✅ Projection / DTO 조회
@Query("SELECT new com.mido.verification.VerificationSummary(v.id, v.inputType, v.status, v.createdAt) FROM VerificationData v WHERE v.status = :status")
Page<VerificationSummary> findSummaries(@Param("status") String status, Pageable pageable);
```

### 6.3 N+1 제거

```java
// ❌ Verification 100건 + WorkContext 100번 조회
// ✅ Fetch Join (상세 1건) 또는 Batch Size (목록)
@Query("SELECT v FROM VerificationData v JOIN FETCH v.workContext WHERE v.id = :id")
Optional<VerificationData> findWithContext(@Param("id") UUID id);
```

---

## 7. 인덱스 설계

### 7.1 인덱스 대상 컬럼 (MIDO)

| 조건 유형 | 컬럼 | API/쿼리 |
| --- | --- | --- |
| WHERE | `status` | DRAFT/DONE 목록 필터 |
| WHERE | `input_type` | 유형별 통계 |
| WHERE | `created_at` | 기간 조회, 최신순 |
| JOIN | `verification_data_id` | work_context, decision_log, manual_input |
| ORDER BY | `created_at DESC` | 목록 정렬 |
| 날짜 범위 | `(created_at)` | 월별 리포트 |
| 상태 필터 | `(status, created_at)` | 복합 조건 목록 |

### 7.2 권장 인덱스 DDL

```sql
-- 목록 API: status + 최신순
CREATE INDEX idx_verification_status_created
  ON verification_data(status, created_at DESC);

-- inputType별 통계
CREATE INDEX idx_verification_input_type_created
  ON verification_data(input_type, created_at);

-- FK 조회 (work_context 1:1)
CREATE UNIQUE INDEX uq_work_context_verification
  ON work_context(verification_data_id);

-- 최신 업로드 파일 (FR-004 FILE 모드)
CREATE INDEX idx_uploaded_file_verification_uploaded
  ON uploaded_file(verification_data_id, uploaded_at DESC);

-- 판단 이력 조회
CREATE INDEX idx_decision_log_decided_at
  ON decision_log(decided_at DESC);
```

---

## 8. Partial Index / Composite Index

### 8.1 Composite Index

여러 조건이 **항상 함께** 쓰일 때:

```sql
-- 자주 쓰는 패턴: status='DONE' + created_at 정렬
CREATE INDEX idx_verification_done_created
  ON verification_data(created_at DESC)
  WHERE status = 'DONE';
```

**컬럼 순서 원칙:** equality(`=`) → range(`>`, `<`) → ORDER BY

```
WHERE status = 'DONE' AND created_at >= '2026-07-01' ORDER BY created_at DESC
→ (status, created_at DESC) 또는 Partial Index on created_at WHERE status='DONE'
```

### 8.2 Partial Index

**일부 데이터만** 자주 조회할 때:

```sql
-- DRAFT만 목록에 자주 노출 (미완료 건 관리)
CREATE INDEX idx_verification_draft
  ON verification_data(created_at DESC)
  WHERE status = 'DRAFT';

-- 미승인 건만 시니어 대시보드
CREATE INDEX idx_decision_pending_approval
  ON decision_log(decided_at)
  WHERE decision IS NOT NULL;  -- approval 테이블 LEFT JOIN 조건과 맞춤
```

### 8.3 트레이드오프

| 이점 | 비용 |
| --- | --- |
| 조회 속도 향상 | INSERT/UPDATE 시 인덱스 갱신 비용 |
| Partial은 작은 인덱스 | 쿼리 조건이 Partial 조건과 정확히 맞아야 함 |
| Composite는 복합 필터에 유리 | 안 쓰는 컬럼이 앞에 있으면 인덱스 무용 |

**원칙:** 인덱스는 **실제 EXPLAIN으로 확인 후** 추가. unused index는 제거.

---

## 9. 파티셔닝

### 9.1 개념

대용량 테이블을 **논리적으로 분할**해 조회 범위를 줄인다.

```
verification_data (전체 1억 row)
  ├── verification_data_2026_01  (1월)
  ├── verification_data_2026_02  (2월)
  └── verification_data_2026_03  (3월)
```

### 9.2 MIDO 적용 시점

| 시점 | 권장 |
| --- | --- |
| MVP~v1.0 | 파티셔닝 불필요 (단일 DB, 소량) |
| 월 100만+ Verification | `created_at` 월별 RANGE 파티션 검토 |
| decision_log / audit | 연도별 파티션 + 아카이브 |

### 9.3 PostgreSQL 예시

```sql
CREATE TABLE verification_data (
  id UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  ...
) PARTITION BY RANGE (created_at);

CREATE TABLE verification_data_2026_07
  PARTITION OF verification_data
  FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
```

**효과:** `WHERE created_at >= '2026-07-01' AND created_at < '2026-08-01'` → 해당 월 파티션만 스캔

---

## 10. 클러스터링

### 10.1 개념

파티션 **내부**에서 비슷한 값을 물리적으로 인접 배치 → 스캔 범위·I/O 감소.

### 10.2 DB별 적용

| DB | 기능 |
| --- | --- |
| PostgreSQL | `CLUSTER` 명령 (일회성), 또는 파티션 + 인덱스 설계 |
| BigQuery | `CLUSTER BY team_id, input_type` |
| Snowflake | `CLUSTER BY (decided_at)` |

### 10.3 MIDO + BigQuery (분석 DB)

```sql
-- 분석용 fact 테이블
CREATE TABLE analytics.fact_verification_decision
PARTITION BY DATE(decided_at)
CLUSTER BY team_id, input_type AS
SELECT ...;
```

**효과:** `WHERE team_id = 'X' AND input_type = 'PR'` 쿼리 시 스캔 바이트 감소 → **비용 절감**

---

## 11. Materialized View / Summary Table

### 11.1 목적

자주 쓰는 집계를 **미리 계산**해 대시보드 응답을 빠르게 한다.

### 11.2 MIDO Summary Table 예시

```sql
-- 일별 판단 통계 (PRD M-001, M-004)
CREATE TABLE summary_daily_decision (
  summary_date     DATE PRIMARY KEY,
  total_count      BIGINT NOT NULL DEFAULT 0,
  done_count       BIGINT NOT NULL DEFAULT 0,
  use_count        BIGINT NOT NULL DEFAULT 0,
  fix_count        BIGINT NOT NULL DEFAULT 0,
  ignore_count     BIGINT NOT NULL DEFAULT 0,
  avg_decide_sec   NUMERIC(10,2),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Materialized View (PostgreSQL)
CREATE MATERIALIZED VIEW mv_monthly_verification AS
SELECT
  date_trunc('month', created_at) AS month,
  input_type,
  status,
  COUNT(*) AS cnt
FROM verification_data
GROUP BY 1, 2, 3;

-- 갱신 (배치 job)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_verification;
```

### 11.3 언제 쓰는가

| 상황 | 방식 |
| --- | --- |
| 실시간에 가까운 집계 | 증분 summary update (§12) |
| 일/주 단위 리포트 | Materialized View + REFRESH |
| 복잡한 다차원 분석 | Star Schema Fact + ETL |

---

## 12. 증분 처리 (Incremental Load)

### 12.1 Full Load vs Incremental Load

| 방식 | 설명 | 비용 |
| --- | --- | --- |
| **Full Load** | 매번 전체 테이블 재적재 | 높음 |
| **Incremental Load** | 변경분만 적재 | 낮음 |

### 12.2 updated_at 기준 변경분

```sql
-- 운영 DB → 분석 DB (마지막 동기화 이후 변경분만)
SELECT id, input_type, status, created_at, updated_at
FROM verification_data
WHERE updated_at > :last_synced_at
ORDER BY updated_at
LIMIT 10000;
```

**MIDO 적용:**

```
last_synced_at 저장 (etl_watermark 테이블)
  ↓
증분 Extract (verification_data, decision_log)
  ↓
Transform → fact_verification_decision upsert
  ↓
watermark 갱신
```

### 12.3 DecisionLog는 append-only

- UPDATE 없음 → `decided_at > :last_synced_at`로 INSERT만 추출
- 중복 방지: fact 테이블 PK = `verification_id`

---

## 13. CDC 처리

### 13.1 Polling vs CDC

| 방식 | 동작 | 장단점 |
| --- | --- | --- |
| **Polling** | `updated_at > ?` 주기적 조회 | 구현 간단, 실시간성 낮음, DB 부하 |
| **CDC** | WAL/binlog 이벤트 스트림 | 실시간, 정확, 인프라 복잡 |

### 13.2 CDC 이벤트 처리

```
PostgreSQL WAL
  ↓ (Debezium)
Kafka topic: mido.verification_data
  ↓
Consumer: insert/update/delete 이벤트별 처리
  ↓
분석 DB / Elasticsearch / 캐시 갱신
```

### 13.3 MIDO 이벤트 예시

| 이벤트 | 후속 처리 |
| --- | --- |
| verification INSERT | 대시보드 total_count +1 |
| status → DONE | summary_daily_decision.done_count +1 |
| decision_log INSERT | fact 테이블 적재, 알림 (시니어) |

---

## 14. Spark / 분산 처리 튜닝

대용량 Git 이력·팀 패턴 분석(FR-008, UC-008) 시 적용.

| 기법 | 설명 | MIDO 적용 |
| --- | --- | --- |
| **cache** | 반복 사용 DataFrame 캐시 | 팀별 PR diff 재사용 |
| **partition 조정** | `repartition(N)` / `coalesce` | team_id 기준 shuffle 균형 |
| **shuffle 최소화** | broadcast join (작은 dim 테이블) | dim_team broadcast |
| **serialization** | Kryo 등 | 기본 Java serializer보다 빠름 |
| **memory tuning** | executor memory, spill 모니터링 | OOM 방지 |
| **작은 파일 문제** | `coalesce` / `OPTIMIZE` | 일별 parquet 병합 |

```python
# 팀 패턴 분석 예시 (PySpark)
commits = spark.read.parquet("s3://mido/git/commits")
guidelines = spark.read.parquet("s3://mido/dim/guidelines")

# 작은 테이블 broadcast
from pyspark.sql.functions import broadcast
patterns = commits.join(broadcast(guidelines), "team_id")
patterns.write.mode("overwrite").partitionBy("team_id").parquet("s3://mido/out/patterns")
```

---

## 15. 데이터 품질 테스트

잘못된 데이터가 파이프라인을 타고 퍼지면 **대시보드·가이드라인·감사** 전체가 오염된다.

### 15.1 테스트 유형

| 테스트 | MIDO 적용 | SQL/도구 예시 |
| --- | --- | --- |
| **unique** | verification id, decision per verification | `UNIQUE(verification_data_id)` |
| **not_null** | input_type, status, decision | `NOT NULL` 제약 |
| **accepted_values** | inputType, decision, status enum | `CHECK` 또는 dbt test |
| **relationships** | FK 존재 | orphan row 0건 |
| **날짜 역전** | decided_at >= created_at | `WHERE decided_at < created_at` → 0건 |
| **row count 급감/급증** | 일별 INSERT 건수 ±50% 이상 | Airflow sensor + alert |

### 15.2 dbt test 예시

```yaml
# models/decision_log.yml
columns:
  - name: decision
    tests:
      - not_null
      - accepted_values:
          values: ['USE', 'FIX', 'IGNORE']
  - name: verification_data_id
    tests:
      - unique
      - relationships:
          to: ref('verification_data')
          field: id
```

### 15.3 API 레벨 품질 (TC 연계)

- TC-008: 중복 판단 409 → DB unique와 이중 방어
- status null 0건 (G-001 해결 후)
- DecisionLog without Verification 0건

---

## 16. Airflow DAG 오케스트레이션

### 16.1 MIDO 일별 분석 DAG

```
midо_daily_analytics
  │
  ├─ extract_verification_delta    (증분 Extract)
  ├─ extract_decision_delta
  ├─ transform_to_fact             (Star Schema 적재)
  ├─ refresh_summary_daily         (Summary Table)
  ├─ test_data_quality             (§15 테스트)
  ├─ publish_dashboard             (Metabase/BI 갱신)
  └─ alert_on_failure              (Slack/PagerDuty)
```

### 16.2 DAG 코드 스케치

```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

default_args = {"retries": 2, "retry_delay": timedelta(minutes=5)}

with DAG(
    "mido_daily_analytics",
    schedule_interval="0 2 * * *",  # 매일 02:00
    start_date=datetime(2026, 7, 1),
    catchup=False,
    default_args=default_args,
) as dag:

    extract = PythonOperator(task_id="extract_verification_delta", python_callable=extract_fn)
    transform = PythonOperator(task_id="transform_to_fact", python_callable=transform_fn)
    summary = PythonOperator(task_id="refresh_summary_daily", python_callable=summary_fn)
    test = PythonOperator(task_id="test_data_quality", python_callable=quality_test_fn)
    alert = PythonOperator(task_id="alert_on_failure", python_callable=alert_fn, trigger_rule="one_failed")

    extract >> transform >> summary >> test
    [extract, transform, summary, test] >> alert
```

---

## 17. 모니터링 / 비용 관리

### 17.1 Job 메트릭

| 메트릭 | 설명 | 저장 위치 |
| --- | --- | --- |
| `job_start_time` | 배치 시작 | etl_job_log |
| `job_end_time` | 배치 종료 | etl_job_log |
| `processed_row_count` | 처리 건수 | etl_job_log |
| `failed_row_count` | 실패 건수 | etl_job_log |
| `query_runtime` | 주요 쿼리 소요 | pg_stat_statements |
| `data_freshness` | now() - last_synced_at | watermark 테이블 |
| `error_message` | 실패 원인 | etl_job_log |

### 17.2 etl_job_log 테이블

```sql
CREATE TABLE etl_job_log (
  id              UUID PRIMARY KEY,
  job_name        VARCHAR(100) NOT NULL,
  started_at      TIMESTAMPTZ NOT NULL,
  ended_at        TIMESTAMPTZ,
  status          VARCHAR(20) NOT NULL,  -- RUNNING, SUCCESS, FAILED
  processed_rows  BIGINT DEFAULT 0,
  failed_rows     BIGINT DEFAULT 0,
  error_message   TEXT,
  watermark_before TIMESTAMPTZ,
  watermark_after  TIMESTAMPTZ
);
```

### 17.3 알림 기준

| 조건 | 조치 |
| --- | --- |
| `data_freshness` > 25시간 | 일별 DAG 실패 의심 |
| `failed_row_count` > 0 | 품질 테스트 실패, 파이프라인 중단 |
| API p95 > 1초 (NFR-001) | 느린 쿼리 EXPLAIN 점검 |
| DB storage 주간 +20% | LOB(code) 아카이브 정책 검토 |

---

## 18. MIDO 프로젝트 적용 순서

SRS 구현과 함께 **아래 순서로** 적용한다.

```
Phase 1 — 데이터 모델 (지금)
─────────────────────────────
① 테이블 책임 분리 확인 (verification / manual_input / work_context / uploaded_file)
② PK / FK / status / created_at / updated_at 정리 (G-001 Flyway)
③ DecisionLog, RiskAssessment 테이블 설계 (MVP-2)

Phase 2 — API / 쿼리 (MVP-2)
─────────────────────────────
④ list API 추가 시 EXPLAIN ANALYZE로 실행계획 확인
⑤ WHERE 조건(status, created_at)에 맞는 인덱스 추가
⑥ 저장 후 전체 list 재조회 제거 → 생성 응답에 id/status/nextAction 반환 (현재 ✅)
⑦ 변경된 row만 patch (upload는 code만 UPDATE, 전체 Entity reload 금지)
⑧ 목록 API pagination 적용 (Pageable, LIMIT 20)

Phase 3 — 이력 / 통계 분리 (v1.0)
─────────────────────────────────
⑨ 이력 / 로그 테이블 분리 (decision_log append-only, audit_log)
⑩ 보고 / 통계는 summary_daily_decision으로 분리
⑪ 운영 DB → 분석 DB 증분 ETL (updated_at watermark)

Phase 4 — 검증 / 운영 (v1.0+)
─────────────────────────────
⑫ TC에 API 호출 수·쿼리 수 assertion 추가 (N+1 회귀 방지)
⑬ Airflow DAG + 데이터 품질 테스트
⑭ 모니터링 대시보드 (freshness, job runtime, API p95)
```

### 18.1 단계별 체크리스트

| 단계 | 작업 | 완료 기준 |
| --- | --- | --- |
| ① | 테이블 책임 문서화 | SRS §7과 ERD 일치 |
| ② | status 컬럼 + 인덱스 | G-001 해결, Flyway V3 |
| ④⑤ | list API EXPLAIN | Index Scan 확인 |
| ⑥ | create 후 list 재조회 없음 | 프론트가 응답 id만 사용 |
| ⑧ | pagination | `Page<VerificationSummary>` |
| ⑫ | 쿼리 수 테스트 | `@SqlCount` 또는 datasource-proxy ≤ N |

### 18.2 쿼리 수 테스트 예시

```java
@Test
void getContext_executesSingleQuery() {
    // datasource-proxy 또는 @DataJpaTest + statistics
    workContextService.get(verificationId);
    assertThat(queryCount).isLessThanOrEqualTo(2); // context + optional file
}
```

---

## 부록: MIDO 테이블별 최적화 요약

| 테이블 | 조회 패턴 | 인덱스 | 주의 |
| --- | --- | --- | --- |
| verification_data | PK, status+날짜 목록 | (status, created_at DESC) | code LOB 목록 제외 |
| work_context | verification_data_id | UNIQUE(verification_data_id) | — |
| uploaded_file | 최신 1건 | (verification_data_id, uploaded_at DESC) | file_content LOB |
| manual_input | verification_data_id | (verification_data_id) | — |
| decision_log | decided_at, verification_id | UNIQUE(verification_id), (decided_at) | append-only |
| summary_daily_decision | summary_date PK | PK만 | 배치 갱신 |

---

## 참고 문서

- [docs/SRS.md](./SRS.md) — 데이터 요구사항, NFR-001
- [docs/PRD.md](./PRD.md) — 성공 지표 M-001~M-005
- [docs/ENGINEERING_GUIDE.md](./ENGINEERING_GUIDE.md) — JPA, EXPLAIN, Flyway
