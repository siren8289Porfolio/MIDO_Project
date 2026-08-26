# DA-04 Document Index

실제로 확인된 데이터 분석/DB 효율화 산출물을 한곳에서 보도록 정리한 인덱스 문서다.

## 1. 상위 `da/`로 모은 DA 문서

| 문서 | 설명 |
| --- | --- |
| `DA-01-data-performance-guide.md` | 데이터 모델링, OLTP/OLAP 분리, ETL, Airflow, 모니터링 가이드 |
| `DA-02-db-efficiency-summary.md` | PostgreSQL 운영 DB/분석 DB, 인덱스, 쿼리 최적화 요약 |
| `DA-03-efficiency-summary.md` | 코드/DB 효율화 내용을 한 번에 보는 통합 요약 |

## 2. 실제 DA 작업물로 확인된 SQL 산출물

아래 파일들은 Flyway가 읽는 실제 마이그레이션이라 `da/`로 옮기지 않고 원래 위치를 유지한다.

| 파일 | 설명 |
| --- | --- |
| `../spring/src/main/resources/db/migration/V1__analytics_requirements.sql` | analytics grain, segment, business question, metric definition |
| `../spring/src/main/resources/db/migration/V2__kpi_definition.sql` | KPI contract, responsible decision completion view, guardrail/operational metric 정의 |
| `../spring/src/main/resources/db/migration/V3__analysis_design.sql` | analysis framework, funnel, cohort, experiment design, failure taxonomy |
| `../spring/src/main/resources/db/migration/V4__event_data_architecture.sql` | event schema, event property, metric trace, contract test, schema change 정의 |

## 3. 상위 기준 문서

- `../docs/PRD.md`
- `../docs/SRS.md`
- `../docs/ENGINEERING_GUIDE.md`
