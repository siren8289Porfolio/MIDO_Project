# QA-02 Quality Requirements & Traceability

> **정합성 기준:** PRD_v0 · SRS_v0 · SDD_v0

> **판정 원칙:** 실행 증거 없는 기능·테스트는 PASS가 아니라 PLANNED 또는 NOT RUN이다. AI는 승인자가 아니며 사람의 Use/Fix/Ignore 및 리뷰 승인을 우회할 수 없다.

---

## 1. 목적

요구사항 누락과 “문서에는 있으나 테스트되지 않은 기능”을 방지한다. 각 항목은 requirement → design → implementation status → test → evidence → release decision으로 연결한다.

---

## 2. 핵심 추적 매트릭스

| ID | Requirement | Design / Implementation Target | Test / Evidence Target | Status |
| --- | --- | --- | --- | --- |
| F-001 | Manual Input | ManualInputController / Service / DTO / Entity | TC-001 정상 생성, TC-002 validation, TC-003 transaction rollback | IMPLEMENTED |
| F-002 | File Upload | UploadController / Service / UploadedFile | TC-004 size / MIME / empty / invalid ID, partial update | IMPLEMENTED |
| F-003 | Work Context | ContextController / WorkContextService / Response | TC-005 not found, LOB 제외, query count | IMPLEMENTED |
| F-004 | Use / Fix / Ignore | DecisionLog + decision API | duplicate / action / rationale / authorization | PLANNED |
| F-005 | DecisionLog | immutable log + 조회 API | audit / duplicate / concurrency | PLANNED |
| F-006 | AI Risk | analysis / RiskAssessment | schema, evidence, timeout, safety | PLANNED |
| F-007 | TeamGuideline | version / scope / ACL | effective version / retrieval | PLANNED |
| F-008 | RBAC | security roles | 401 / 403 / team isolation | PLANNED |
| F-009 | Git | commit / PR input | invalid repo / SHA / PR / auth | PLANNED |

---

## 3. 비기능 추적

| ID | Requirement | Test / Evidence Target |
| --- | --- | --- |
| NFR-TRX | create 3-table atomic transaction | integration rollback |
| NFR-PERF | list / context projection, open-in-view=false, N+1 <= 2 queries | performance regression |
| NFR-DB | Flyway + ddl-auto validate, index / EXPLAIN ANALYZE | migration / plan test |
| NFR-ERR | GlobalExceptionHandler, common response / error | contract snapshots |
| NFR-SEC | upload validation, redaction, RBAC, immutable audit | security suite |
| NFR-AI | human final decision, grounded evidence, versioning | AI evaluation / safety |

---

## 4. 상태 규칙

`DRAFT → READY → RUNNING → DONE|FAILED`를 표준으로 사용한다. `PROCESSING`은 허용하지 않는다.

불가능 전이, 동시 실행, 재시도 정책을 BE service와 DB constraint / test에 연결한다.

---

## 5. 데이터 추적

다음 관계와 속성을 검증한다.

| 대상 | 검증 기준 |
| --- | --- |
| FK | VerificationData ↔ ManualInput / UploadedFile / WorkContext / RiskAssessment / DecisionLog / Approval |
| Timestamp | creation / update timestamps |
| Source / Version | source, model version, prompt version |
| LOB | code LOB 비노출 |
| Immutability | DecisionLog 불변성 |

---

## 6. Coverage 규칙

P0 요구사항은 positive / negative / boundary / security / failure 중 해당 유형을 모두 가져야 한다.

구현되지 않은 요구사항도 test design은 가질 수 있으나 execution status는 `NOT RUN`이다.

Coverage는 requirement 수와 test 연결 수를 모두 표시한다.

---

## 7. 변경 통제

PRD / SRS / SDD / API / schema 변경 시 impact review를 실시하고 매트릭스, test fixture, dashboard contract를 갱신한다.

`status enum`, endpoint, grain, error code 변경은 breaking change로 취급한다.

---

## 8. 완료 기준

모든 in-scope requirement에 owner, design, implementation status, test case, evidence link 또는 명시적 waiver가 존재해야 한다.

고위험 orphan requirement가 있으면 QA-07은 NO-GO다.

