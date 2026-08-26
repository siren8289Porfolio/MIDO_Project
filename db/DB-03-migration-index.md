# DB-03 Migration Index

Flyway 마이그레이션(`spring/src/main/resources/db/migration`) 역할 정리.
실행 위치는 Flyway `classpath:db/migration` 고정이라 최상위 `db/`로 파일을 옮기지 않는다.

## 1. 버전 목록

| Version | 파일 | 역할 |
| --- | --- | --- |
| V1 | `V1__analytics_requirements.sql` | Analytics grain, segment, business question, metric definition, requirement trace |
| V2 | `V2__kpi_definition.sql` | Metric contract, KPI/guardrail/operational metric, decision completion view |
| V3 | `V3__analysis_design.sql` | Analysis framework, funnel, cohort, experiment, failure taxonomy |
| V4 | `V4__event_data_architecture.sql` | Event schema/property, metric trace, contract test, schema change |
| V5 | `V5__data_requirements.sql` | OLTP 코어 테이블 정합 + 운영/분석 보조 테이블 + 인덱스 |
| V6 | `V6__vulnerability_risk_evidence.sql` | Vulnerability source, risk evidence 기본 스키마 |
| V7 | `V7__ai_risk_evidence_contract.sql` | AI risk evidence 계약 컬럼·제약 확장 (MITRE/OWASP 등) |

## 2. 레이어 구분

```text
V1~V4  Analytics / Metric / Event 계약 (분석 스키마)
V5     OLTP 운영 스키마 + 인덱스
V6~V7  Risk Evidence / Vulnerability 계약
```

DA 대시보드가 읽는 `mart_daily_product_metrics` 등은 V1~V5 계열에 정의되며,
경로 인덱스는 `../da/DA-04-document-index.md`에도 있다.

## 3. 적용 방식

| 항목 | 값 |
| --- | --- |
| 위치 | `spring/src/main/resources/db/migration/` |
| 설정 | `spring.flyway.locations: classpath:db/migration` |
| JPA | `spring.jpa.hibernate.ddl-auto: validate` |
| 원칙 | 스키마 변경은 migration SQL만 — 앱이 운영 DDL을 임의 변경하지 않음 |

## 4. 관련 코드

| 구분 | 경로 |
| --- | --- |
| OLTP 엔티티 | `../spring/src/main/verification/{common,manual,upload,context}/entity/` |
| Risk evidence 파서/계약 타입 | `../spring/src/main/verification/de/{dependency,risk}/` |
| Analytics 서빙 API | `../spring/src/main/verification/da/` |
