# DB-01 Document Index

MIDO DB(스키마·마이그레이션·인덱스·엔티티) 산출물을 한곳에서 보도록 정리한 인덱스 문서다.

## 1. 상위 `db/`로 모은 DB 문서

| 문서 | 설명 |
| --- | --- |
| `DB-01-document-index.md` | 본 문서 — DB 산출물 위치 인덱스 |
| `DB-02-schema-overview.md` | 운영 테이블·JPA 엔티티 매핑 개요 |
| `DB-03-migration-index.md` | Flyway V1~V7 마이그레이션 역할 정리 |

## 2. 실제 구현된 DB 작업물 (코드)

> Flyway는 `classpath:db/migration`을 읽도록 고정돼 있고, JPA 엔티티는 Spring sourceSet
> (`src/main/verification`) 아래에 있어야 한다. 그래서 SQL/엔티티를 최상위 `db/`로 옮기면
> 빌드·마이그레이션이 깨진다. 최상위 `db/`에는 **문서**를 두고, 실행 산출물은 원래 위치를 유지한다.

### Flyway migrations

| 파일 | 설명 |
| --- | --- |
| `../spring/src/main/resources/db/migration/V1__analytics_requirements.sql` | Analytics grain/segment/BQ/metric 계약 |
| `../spring/src/main/resources/db/migration/V2__kpi_definition.sql` | KPI contract, responsible decision completion |
| `../spring/src/main/resources/db/migration/V3__analysis_design.sql` | Funnel / cohort / experiment / failure taxonomy |
| `../spring/src/main/resources/db/migration/V4__event_data_architecture.sql` | Event schema / property / contract test |
| `../spring/src/main/resources/db/migration/V5__data_requirements.sql` | OLTP 코어 테이블 + 운영 인덱스 |
| `../spring/src/main/resources/db/migration/V6__vulnerability_risk_evidence.sql` | Vulnerability source / risk evidence 스키마 |
| `../spring/src/main/resources/db/migration/V7__ai_risk_evidence_contract.sql` | AI risk evidence 계약 확장 |

### JPA entities (OLTP)

| 파일 | 테이블 |
| --- | --- |
| `../spring/src/main/verification/common/entity/VerificationData.java` | `verification_data` |
| `../spring/src/main/verification/common/entity/VerificationStatus.java` | status enum |
| `../spring/src/main/verification/manual/entity/ManualInput.java` | `manual_input` |
| `../spring/src/main/verification/upload/entity/UploadedFile.java` | `uploaded_file` |
| `../spring/src/main/verification/context/entity/WorkContext.java` | `work_context` |

## 3. 관련 문서 (다른 직군 폴더)

| 문서 | 설명 |
| --- | --- |
| `../da/DA-02-db-efficiency-summary.md` | DB/쿼리 효율화 설계·현황 (DA 관점) |
| `../da/DA-03-efficiency-summary.md` | 코드+DB 효율화 통합 요약 |
| `../docs/ENGINEERING_GUIDE.md` | Flyway·트랜잭션·인덱스 엔지니어링 가이드 |
| `../docs/SRS.md` | 스키마/상태 전이 요구사항 |

## 4. 설정

| 파일 | 설명 |
| --- | --- |
| `../spring/src/main/resources/application.yml` | `spring.flyway.locations: classpath:db/migration`, `ddl-auto: validate` |
| `../spring/src/main/resources/application-prod.yml` | 운영 DB 연결 |
