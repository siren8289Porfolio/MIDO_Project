# DB-02 Schema Overview

MIDO 운영 DB(OLTP) 핵심 테이블과 JPA 엔티티 매핑 개요다. Analytics/리스크 증거 테이블은 `DB-03` 마이그레이션 인덱스를 본다.

## 1. OLTP 코어 ER

```text
verification_data (1)
    ├── manual_input (N)
    ├── uploaded_file (N)
    └── work_context (1)
```

검증 대상(`verification_data`)을 중심으로 입력·파일·표시용 컨텍스트를 분리한다.
대용량 `code` LOB은 목록/컨텍스트 조회에서 Projection으로 제외한다.

## 2. 테이블 ↔ 엔티티

| 테이블 | 엔티티 | 패키지 | 비고 |
| --- | --- | --- | --- |
| `verification_data` | `VerificationData` | `common.entity` | PK UUID, `status`, `code` LOB |
| — | `VerificationStatus` | `common.entity` | DRAFT/READY/RUNNING/DONE/FAILED |
| `manual_input` | `ManualInput` | `manual.entity` | FK → verification_data |
| `uploaded_file` | `UploadedFile` | `upload.entity` | 파일 메타 + content |
| `work_context` | `WorkContext` | `context.entity` | 1:1, display_* 스냅샷 |

엔티티는 Spring sourceSet 제약으로 `spring/src/main/verification/**/entity`에 유지한다.

## 3. 상태 제약

`V5__data_requirements.sql`의 `chk_verification_status`:

| 값 | 의미 |
| --- | --- |
| `DRAFT` | 초안 |
| `READY` | 분석 가능 |
| `RUNNING` | 분석 중 |
| `DONE` | 완료 |
| `FAILED` | 실패 |

## 4. 운영 인덱스 (V5)

| 인덱스 | 용도 |
| --- | --- |
| `idx_verification_status_created` | 목록 status + 최신순 |
| `idx_verification_input_type_created` | input_type 필터 |
| `idx_verification_draft_created` | DRAFT partial index |
| `idx_manual_input_verification` | FK 조인 |
| `idx_uploaded_file_verification_uploaded` | 파일 목록 |
| `idx_work_context_verification` | context 1:1 조회 |

상세 설계·EXPLAIN 근거는 `../da/DA-02-db-efficiency-summary.md`를 본다.

## 5. 설계 원칙

- 운영 DDL은 Flyway만 변경 (`ddl-auto: validate`)
- API DTO와 Entity 분리 — LOB/`code`를 목록 응답에 노출하지 않음
- FK·CHECK·인덱스는 migration SQL에 명시
