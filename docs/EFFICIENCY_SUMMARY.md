# MIDO 코드·데이터 효율화 정리

`ENGINEERING_GUIDE.md`, `DATA_PERFORMANCE_GUIDE.md`, `SRS.md`에 흩어진 효율화 내용을 한곳에 모은 요약 문서.

---

## 1. 목표 지표 (NFR-001)

| 지표 | 목표 |
| --- | --- |
| API 응답 시간 (p95) | **1초 이내** |
| 단일 DB 쿼리 | **100ms 이내** |
| 목록 API 쿼리 수 | **N+1 없음** (건당 ≤ 2~3쿼리) |
| DecisionLog 중복 | **0건** |
| 데이터 품질 오류 | **0건** |

---

## 2. 이미 적용된 것 (코드 ✅)

### 2.1 아키텍처 / 코드 구조

| 항목 | 내용 | 위치 |
| --- | --- | --- |
| 계층 분리 | Controller → Service → Repository | `manual/`, `upload/`, `context/` |
| DI | 생성자 주입, `new`로 Repository 생성 안 함 | 각 Controller, Service |
| DTO / Entity 분리 | API 입출력과 DB 엔티티 분리 | `ManualInputRequest`, `WorkContextResponse` |
| 트랜잭션 원자성 | 3테이블 단일 `@Transactional` | `ManualInputService.create()` |
| 검증 분리 | `validate()`, `requireNotBlank()` | `ManualInputService` |
| 응답만 반환 | 생성 후 list 재조회 없음 | `VerificationCreateResponse` (id, status, nextAction) |
| 부분 갱신 | upload 시 `code` + `updatedAt`만 UPDATE | `UploadService.upload()` |
| Query Method | ID/FK 기준 조회 | `findByVerificationData_Id`, `findTopBy...OrderByUploadedAtDesc` |

### 2.2 API 설계

| 항목 | 효과 |
| --- | --- |
| FILE 2단계 (create → upload) | 대용량 파일을 생성 트랜잭션과 분리 |
| Context API 분리 | 판단 맥락만 조회, code LOB 미포함 |
| nextAction 힌트 | 클라이언트 불필요 호출 감소 |

---

## 3. 문서화만 된 것 (가이드 📋, 미구현)

### 3.1 코드 / API

| ID | 항목 | 내용 |
| --- | --- | --- |
| G-002 | GlobalExceptionHandler | 표준 ERR 응답, 400/404 정합 |
| — | InputType enum | switch 문자열 오타 방지 |
| — | Projection DTO | 목록 API에서 LOB 제외 |
| — | Fetch Join | 상세 조회 N+1 방지 |
| — | `@Timed` / Micrometer | API p95 측정 |

### 3.2 DB / 쿼리

| ID | 항목 | 내용 |
| --- | --- | --- |
| G-001 | `status` DB 컬럼 | DTO만 존재 → Flyway V3 |
| — | 인덱스 | `(status, created_at DESC)`, FK UNIQUE |
| — | Partial Index | `WHERE status = 'DRAFT'` |
| — | EXPLAIN ANALYZE | list API 추가 시 필수 |
| — | Pagination | `Pageable`, LIMIT 20 |
| — | `ddl-auto: update` → Flyway | 스키마 버전 관리 |

### 3.3 데이터 모델

| 항목 | 내용 |
| --- | --- |
| 테이블 책임 분리 | verification / manual_input / work_context / uploaded_file |
| repo 중복 | work_context = 생성 시점 스냅샷으로 문서화 |
| decision_log | append-only, UNIQUE(verification_data_id) |
| summary table | `summary_daily_decision` — 통계는 운영 DB와 분리 |
| Star Schema | fact + dim — 분석 DB 별도 |

### 3.4 파이프라인 / 운영

| 항목 | 내용 |
| --- | --- |
| 증분 ETL | `updated_at` watermark |
| CDC | Debezium → Kafka (v1.0+) |
| Airflow DAG | extract → transform → test → publish |
| 데이터 품질 테스트 | unique, not_null, accepted_values, row count |
| Actuator + K8s Probe | health, graceful shutdown |
| CI | `./gradlew test` 매 PR |

---

## 4. 적용 순서 (우선순위)

```
Phase 1 — 지금 (MVP-1 마무리)
  ① 테이블 책임 / PK·FK 정리          ← 문서 ✅, Flyway ❌
  ② status 컬럼 추가 (G-001)         ← ❌
  ③ GlobalExceptionHandler (G-002)   ← ❌

Phase 2 — MVP-2
  ④ list API + EXPLAIN + 인덱스      ← ❌
  ⑤ Pagination                       ← ❌
  ⑥ Projection (code LOB 제외)       ← ❌
  ⑦ DecisionLog / RiskAssessment     ← ❌
  ⑧ 쿼리 수 테스트 (N+1 회귀 방지)   ← ❌

Phase 3 — v1.0
  ⑨ summary table / 증분 ETL         ← ❌
  ⑩ RBAC, Git 연동                   ← ❌
  ⑪ 모니터링 (p95, freshness)        ← ❌
```

---

## 5. 영역별 한 줄 요약

| 영역 | 핵심 원칙 | MIDO 상태 |
| --- | --- | --- |
| **Java / Clean Code** | 작은 책임, DTO 분리, DI | ✅ 기본 적용 |
| **Spring 계층** | Controller 얇게, Service에 로직 | ✅ 적용 |
| **JPA / Repository** | Query Method, N+1 주의 | ⚠️ 기본만 |
| **SQL** | SELECT 필요 컬럼만, LOB 목록 제외 | ❌ list API 없음 |
| **인덱스** | WHERE·JOIN·ORDER BY 컬럼 | ❌ 미생성 |
| **데이터 모델** | 테이블 책임 분리, 정규화 | ✅ 구조 양호 |
| **분석 DB** | Star Schema, Summary Table | 📋 설계만 |
| **테스트** | TC + 쿼리 수 assertion | ❌ contextLoads만 |
| **운영** | Actuator, CI, Flyway, Docker | ❌ 대부분 미적용 |

---

## 6. 테이블별 최적화 메모

| 테이블 | 조회 시 주의 | 권장 인덱스 |
| --- | --- | --- |
| `verification_data` | 목록에서 `code` LOB 빼기 | `(status, created_at DESC)` |
| `work_context` | 1:1 FK 조회 | `UNIQUE(verification_data_id)` |
| `uploaded_file` | 최신 1건만 | `(verification_data_id, uploaded_at DESC)` |
| `manual_input` | 상세에서만 | `(verification_data_id)` |
| `decision_log` | 수정·삭제 금지 | `UNIQUE(verification_data_id)` |

---

## 7. SRS 갭 ↔ 효율화 매핑

| Gap | 효율화 관점 | Phase |
| --- | --- | --- |
| G-001 status 미영속 | status 필터·인덱스 불가 | 1 |
| G-002 ExceptionHandler | 불필요 재시도·디버깅 비용 | 1 |
| G-003 OpenAPI 불일치 | 잘못된 API 호출 → 중복 요청 | 1 |
| G-004 DecisionLog 미구현 | 판단 이력 별도 테이블 분리 | 2 |
| G-005 Risk 미구현 | 분석 결과 별도 테이블 | 2 |
| G-006 RBAC 미구현 | 무제한 조회 → DB 부하 | 3 |
| G-007 업로드 제한 없음 | 대용량 LOB → 스토리지·응답 지연 | 2 |

---

## 8. 다음에 할 일 (Top 5)

1. **Flyway + `status` 컬럼** — G-001, 인덱스 전제 조건
2. **GlobalExceptionHandler** — G-002, 400/404 정합
3. **list API + Projection + Pagination** — LOB·전체 스캔 방지
4. **인덱스 DDL** — `(status, created_at DESC)` + FK UNIQUE
5. **통합 테스트 + 쿼리 수 검증** — TC-001~008, N+1 회귀 방지

---

## 참고 문서

| 문서 | 내용 |
| --- | --- |
| [ENGINEERING_GUIDE.md](./ENGINEERING_GUIDE.md) | Java, Spring, JPA, 테스트, CI/CD, 운영 |
| [DATA_PERFORMANCE_GUIDE.md](./DATA_PERFORMANCE_GUIDE.md) | DB, 인덱스, ETL, Airflow, 모니터링 |
| [SRS.md](./SRS.md) | NFR, Gap, TC |
