# MIDO SRS

## Software Requirements Specification

---

## 1. 문서 목적

이 문서는 MIDO PRD의 제품 요구사항을 개발 가능한 시스템 요구사항으로 정리한 SRS 문서다.

```
PRD → SRS → SDD / ERD / API / DB Schema → Development → Test
```

MIDO는 AI가 생성한 코드 또는 작업 결과물에 대해 실무자가 **"이 결과를 써도 되는가?"**를 판단하고, 그 근거를 남기는 Verification Workflow 시스템이다.

---

## 2. 시스템 범위

| 구분 | 포함 기능 | 상태 |
| --- | --- | --- |
| MVP-1 | 판단 대상 입력, 파일 업로드, Work Context 조회 | 구현 |
| MVP-2 | AI 리스크 분석, Use/Fix/Ignore 판단, DecisionLog 생성 | 예정 |
| v1.0 | 팀 가이드라인, Git/PR 연동, RBAC, 시니어 승인 | 예정 |

### 제외 범위

| 제외 항목 | 사유 |
| --- | --- |
| AI 모델 자체 개발 | 목적은 모델 개선이 아니라 판단 과정 관리 |
| 완전 자동 승인 | 최종 판단은 사람이 수행 |
| 멀티 테넌트 과금 | MVP 이후 검토 |
| IDE 플러그인 | 초기 MVP에서는 웹 기반 흐름 우선 |

---

## 3. 사용자 유형

| 사용자 | 설명 | 주요 권한 |
| --- | --- | --- |
| 실무자 | AI 결과물을 업무에 적용하는 사용자 | Verification 생성, 파일 업로드, 판단 제출 |
| 시니어 | 판단 결과를 검토·승인하는 사용자 | DecisionLog 조회, 승인 |
| 관리자 | AI 활용 이력과 권한을 관리하는 사용자 | 전체 이력 조회, 권한 관리 |
| 시스템 | 자동 분석을 수행하는 내부 행위자 | Risk 분석, Guideline 추천 |

---

## 4. 주요 유스케이스

| UC ID | 유스케이스 | 결과 | 상태 |
| --- | --- | --- | --- |
| UC-001 | 판단 대상 입력 | DRAFT Verification 생성 | 구현 |
| UC-002 | 파일 업로드 | UploadedFile 저장, code 갱신 | 구현 |
| UC-003 | Work Context 조회 | 판단 맥락 반환 | 구현 |
| UC-004 | AI 리스크 분석 | 위험 요소 목록 반환 | 예정 |
| UC-005 | 판단 제출 | DecisionLog 생성, DONE 처리 | 예정 |
| UC-006 | 시니어 승인 | Approval 기록 | 예정 |

---

## 5. 기능 요구사항

| ID | 기능 | 요구사항 | 우선순위 | 상태 |
| --- | --- | --- | --- | --- |
| FR-001 | Verification 생성 | 시스템은 inputType과 필수값을 받아 VerificationData, ManualInput, WorkContext를 생성해야 한다. | P0 | 구현 |
| FR-002 | 입력값 검증 | 시스템은 inputType별 필수값 누락 시 400 오류를 반환해야 한다. | P0 | 구현 |
| FR-003 | 파일 업로드 | 시스템은 FILE 모드에서 파일을 저장하고 VerificationData.code를 갱신해야 한다. | P0 | 구현 |
| FR-004 | Work Context 조회 | 시스템은 Verification ID 기준으로 repo, commit, PR, fileName 등 판단 맥락을 반환해야 한다. | P0 | 구현 |
| FR-005 | AI 리스크 분석 | 시스템은 code 기반으로 위험 요소 목록을 반환해야 한다. | P0 | 예정 |
| FR-006 | 판단 제출 | 시스템은 USE/FIX/IGNORE 판단을 저장하고 Verification 상태를 DONE으로 변경해야 한다. | P0 | 예정 |
| FR-007 | DecisionLog 불변성 | 시스템은 DecisionLog 수정·삭제 API를 제공하지 않아야 한다. | P1 | 예정 |
| FR-008 | 팀 가이드라인 | 시스템은 유사 사례와 팀 기준 기반 가이드라인을 반환해야 한다. | P1 | 예정 |
| FR-009 | Git/PR 연동 | 시스템은 외부 Git API로 commit, PR, diff를 조회해야 한다. | P1 | 예정 |
| FR-010 | RBAC | 시스템은 역할별 API 접근을 제한해야 한다. | P1 | 예정 |

---

## 6. 주요 입력 규칙

| inputType | 필수값 | nextAction |
| --- | --- | --- |
| PASTE | rawInput | VIEW_CONTEXT |
| FILE | inputMethod | UPLOAD_FILE |
| COMMIT | repoUrl, commitHash | VIEW_CONTEXT |
| PR | repoUrl, prNumber | VIEW_CONTEXT |

---

## 7. 데이터 요구사항

| 데이터 객체 | 설명 | 주요 필드 |
| --- | --- | --- |
| VerificationData | 판단 세션 중심 데이터 | id, inputType, repoUrl, commitHash, prNumber, code, status |
| ManualInput | 사용자가 입력한 원본 데이터 | id, verificationDataId, inputMethod, rawInput |
| UploadedFile | 업로드 파일 정보 | id, verificationDataId, fileName, fileType, fileContent |
| WorkContext | 작업 맥락 정보 | id, verificationDataId, repoUrl, commitHash, prNumber |
| RiskAssessment | AI 리스크 분석 결과 | id, verificationDataId, riskType, severity, description |
| DecisionLog | 판단 결과와 근거 | id, verificationDataId, decision, rationale, decidedAt |
| TeamGuideline | 팀 기준 가이드라인 | id, teamId, pattern, recommendation |
| Approval | 시니어 승인 기록 | id, decisionLogId, approvedBy, approvedAt |

### 데이터 관계

```
VerificationData 1:N ManualInput
VerificationData 1:N UploadedFile
VerificationData 1:1 WorkContext
VerificationData 1:N RiskAssessment
VerificationData 1:1 DecisionLog
DecisionLog 1:1 Approval
```

---

## 8. API 요구사항

| Method | Endpoint | 목적 | 상태 |
| --- | --- | --- | --- |
| POST | `/api/verifications/manual` | Verification 생성 | 구현 |
| POST | `/api/verifications/{id}/upload` | 파일 업로드 | 구현 |
| GET | `/api/verifications/{id}/context` | Work Context 조회 | 구현 |
| POST | `/api/verifications/{id}/analyze` | AI 리스크 분석 | 예정 |
| POST | `/api/verifications/{id}/decision` | 판단 제출 | 예정 |
| GET | `/api/verifications/{id}/decision` | 판단 기록 조회 | 예정 |
| POST | `/api/verifications/{id}/approve` | 시니어 승인 | 예정 |

---

## 9. 비기능 요구사항

| ID | 구분 | 요구사항 |
| --- | --- | --- |
| NFR-001 | 성능 | 주요 API는 95% 요청 기준 1초 이내 응답해야 한다. |
| NFR-002 | 보안 | MVP-2 이후 인증된 사용자만 보호 API에 접근할 수 있어야 한다. |
| NFR-003 | 권한 | 역할별 API 접근을 제한해야 한다. |
| NFR-004 | 감사 | Verification 생성, 판단, 승인 시점과 주체를 기록해야 한다. |
| NFR-005 | 무결성 | DecisionLog는 수정·삭제할 수 없어야 한다. |
| NFR-006 | 사용성 | 판단 완료까지 입력 → 맥락 → 판단 → 기록 4단계 이내여야 한다. |
| NFR-007 | 예외 처리 | 예외는 표준 오류 응답으로 반환해야 한다. |
| NFR-008 | API 문서화 | 구현 API와 OpenAPI 명세가 일치해야 한다. |

---

## 10. 예외 처리 요구사항

| Error ID | 상황 | HTTP Status |
| --- | --- | --- |
| ERR-001 | 필수 입력값 누락 | 400 |
| ERR-002 | 지원하지 않는 inputType | 400 |
| ERR-003 | Verification 없음 | 404 |
| ERR-004 | WorkContext 없음 | 404 |
| ERR-005 | 파일 읽기 실패 | 500 |
| ERR-006 | 이미 판단 완료 | 409 |
| ERR-007 | 인증 실패 | 401 |
| ERR-008 | 권한 없음 | 403 |
| ERR-009 | 외부 Git 또는 LLM API 실패 | 502 |

---

## 11. 테스트 기준

| TC ID | 검증 내용 | 관련 요구사항 |
| --- | --- | --- |
| TC-001 | PASTE 입력 시 Verification 생성 | FR-001 |
| TC-002 | inputType 누락 시 400 반환 | FR-002 |
| TC-003 | COMMIT 필수값 누락 시 400 반환 | FR-002 |
| TC-004 | 파일 업로드 후 code 갱신 | FR-003 |
| TC-005 | Work Context 조회 시 맥락 정보 반환 | FR-004 |
| TC-006 | AI 리스크 분석 시 risks 배열 반환 | FR-005 |
| TC-007 | 판단 제출 시 DecisionLog 생성 | FR-006 |
| TC-008 | 중복 판단 제출 시 409 반환 | FR-006 |
| TC-009 | 미인증 요청 시 401 반환 | NFR-002 |
| TC-010 | 권한 없는 요청 시 403 반환 | NFR-003 |

---

## 12. 현재 구현 갭

| Gap ID | 현재 상태 | 개선 필요 |
| --- | --- | --- |
| G-001 | VerificationData.status가 응답 DTO에만 존재 | DB 컬럼 추가 |
| G-002 | GlobalExceptionHandler 미구현 | 표준 오류 응답 적용 |
| G-003 | OpenAPI와 실제 응답 일부 불일치 | openapi.yaml 갱신 |
| G-004 | DecisionLog 미구현 | DecisionLog Entity/API 구현 |
| G-005 | AI Risk Check 미구현 | RiskAssessment 구현 |
| G-006 | 인증/권한 미구현 | JWT + RBAC 도입 |
| G-007 | 파일 업로드 제한 미구현 | 크기, 확장자, MIME 타입 검증 추가 |

---

## 13. 최종 요약

MIDO SRS는 AI 결과물을 자동 승인하는 요구사항이 아니라, 사람이 AI 결과물을 판단하고 근거를 남기는 Verification Workflow 요구사항을 정의한다.

MVP-1은 판단 대상 입력, 파일 업로드, Work Context 조회를 구현한다.

MVP-2는 AI Risk Check, Use/Fix/Ignore 판단, DecisionLog를 구현한다.

v1.0은 팀 가이드라인, Git 연동, RBAC, 시니어 승인으로 확장한다.
