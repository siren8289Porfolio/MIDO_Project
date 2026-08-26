# DB-01 Document Index

MIDO DB(스키마·마이그레이션·인덱스·엔티티) 역할 폴더다.  
**클릭해서 바로 볼 실제 SQL은 `migration/` 아래에 있다.**

## 폴더 구조

```text
db/
├── DB-01-document-index.md      ← 본 문서
├── DB-02-schema-overview.md     ← OLTP 테이블·엔티티 개요
├── DB-03-migration-index.md     ← V1~V7 역할 정리
└── migration/                   ← Flyway 실행 SQL (단일 소스)
    ├── V1__analytics_requirements.sql
    ├── V2__kpi_definition.sql
    ├── V3__analysis_design.sql
    ├── V4__event_data_architecture.sql
    ├── V5__data_requirements.sql
    ├── V6__vulnerability_risk_evidence.sql
    └── V7__ai_risk_evidence_contract.sql
```

빌드 시 `spring/build.gradle.kts`의 `processResources`가
`db/migration/*` → classpath `db/migration/*` 로 복사한다.
`spring.flyway.locations: classpath:db/migration` 은 그대로다.

## 1. 문서

| 문서 | 설명 |
| --- | --- |
| `DB-01-document-index.md` | 본 문서 — DB 폴더 인덱스 |
| `DB-02-schema-overview.md` | 운영 테이블·JPA 엔티티 매핑 개요 |
| `DB-03-migration-index.md` | Flyway V1~V7 마이그레이션 역할 정리 |

## 2. Flyway migrations (`./migration/`)

| 파일 | 설명 |
| --- | --- |
| `migration/V1__analytics_requirements.sql` | Analytics grain/segment/BQ/metric 계약 |
| `migration/V2__kpi_definition.sql` | KPI contract, responsible decision completion |
| `migration/V3__analysis_design.sql` | Funnel / cohort / experiment / failure taxonomy |
| `migration/V4__event_data_architecture.sql` | Event schema / property / contract test |
| `migration/V5__data_requirements.sql` | OLTP 코어 테이블 + 운영 인덱스 |
| `migration/V6__vulnerability_risk_evidence.sql` | Vulnerability source / risk evidence 스키마 |
| `migration/V7__ai_risk_evidence_contract.sql` | AI risk evidence 계약 확장 |

## 3. JPA entities (OLTP) — Spring sourceSet 안

| 파일 | 테이블 |
| --- | --- |
| `../spring/src/main/verification/common/entity/VerificationData.java` | `verification_data` |
| `../spring/src/main/verification/common/entity/VerificationStatus.java` | status enum |
| `../spring/src/main/verification/manual/entity/ManualInput.java` | `manual_input` |
| `../spring/src/main/verification/upload/entity/UploadedFile.java` | `uploaded_file` |
| `../spring/src/main/verification/context/entity/WorkContext.java` | `work_context` |

## 4. 관련 문서

| 문서 | 설명 |
| --- | --- |
| `../da/DA-02-db-efficiency-summary.md` | DB/쿼리 효율화 설계·현황 (DA 관점) |
| `../da/DA-03-efficiency-summary.md` | 코드+DB 효율화 통합 요약 |
| `../docs/ENGINEERING_GUIDE.md` | Flyway·트랜잭션·인덱스 엔지니어링 가이드 |
| `../docs/SRS.md` | 스키마/상태 전이 요구사항 |

## 5. 설정

| 파일 | 설명 |
| --- | --- |
| `../spring/src/main/resources/application.yml` | `spring.flyway.locations: classpath:db/migration`, `ddl-auto: validate` |
| `../spring/src/main/resources/application-prod.yml` | 운영 DB 연결 |
| `../spring/build.gradle.kts` | `processResources` → root `db/migration` 패키징 |
| `../Dockerfile` | `COPY db /db` (Gradle이 `../db`를 읽도록) |
