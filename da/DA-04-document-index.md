# DA-04 Document Index

실제로 확인된 데이터 분석/DB 효율화 산출물을 한곳에서 보도록 정리한 인덱스 문서다.

## 1. 상위 `da/`로 모은 DA 문서

| 문서 | 설명 |
| --- | --- |
| `DA-01-data-performance-guide.md` | 데이터 모델링, OLTP/OLAP 분리, ETL, Airflow, 모니터링 가이드 |
| `DA-02-db-efficiency-summary.md` | PostgreSQL 운영 DB/분석 DB, 인덱스, 쿼리 최적화 요약 |
| `DA-03-efficiency-summary.md` | 코드/DB 효율화 내용을 한 번에 보는 통합 요약 |

## 2. 실제 구현된 DA 작업물 (코드)

DA-02/DA-03에서 "다음 할 일"로 문서화만 되어 있던 목록 API(Projection + Pagination + status 필터)를 구현했다.

| 파일 | 설명 |
| --- | --- |
| `../spring/src/main/verification/list/controller/VerificationListController.java` | `GET /api/verifications` — status/page/size 파라미터 |
| `../spring/src/main/verification/list/service/VerificationListService.java` | status 파싱, 페이지 크기 상한(100) 처리 |
| `../spring/src/main/verification/list/dto/VerificationSummaryResponse.java` | `code` LOB을 포함하지 않는 목록 전용 Projection |
| `../spring/src/main/verification/common/repository/VerificationDataRepository.java` | `findSummaries` — JPQL Projection 쿼리, `idx_verification_status_created` 인덱스 활용 |
| `../spring/src/test/verification/list/controller/VerificationListControllerTest.java` | 목록 응답에 `code` 필드가 없음을 검증하는 컨트롤러 테스트 |

## 3. 실제 DA 작업물로 확인된 SQL 산출물

아래 파일들은 Flyway가 읽는 실제 마이그레이션이라 `da/`로 옮기지 않고 원래 위치를 유지한다.

| 파일 | 설명 |
| --- | --- |
| `../spring/src/main/resources/db/migration/V1__analytics_requirements.sql` | analytics grain, segment, business question, metric definition |
| `../spring/src/main/resources/db/migration/V2__kpi_definition.sql` | KPI contract, responsible decision completion view, guardrail/operational metric 정의 |
| `../spring/src/main/resources/db/migration/V3__analysis_design.sql` | analysis framework, funnel, cohort, experiment design, failure taxonomy |
| `../spring/src/main/resources/db/migration/V4__event_data_architecture.sql` | event schema, event property, metric trace, contract test, schema change 정의 |
| `../spring/src/main/resources/db/migration/V5__data_requirements.sql` | `verification_data.status` 컬럼, DA-02 §6에서 설계한 인덱스 전체(§6.1) 실제 적용 |

## 4. 상위 기준 문서

- `../docs/PRD.md`
- `../docs/SRS.md`
- `../docs/ENGINEERING_GUIDE.md`
