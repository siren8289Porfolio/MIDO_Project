# MIDO PRD

## 0. 사용 목적

이 문서는 MIDO 제품/기능을 만들기 전에 다음 내용을 명확히 정리하기 위한 PRD이다.

```
왜 만드는가?
누가 쓰는가?
무엇을 제공하는가?
어디까지 만들 것인가?
어떤 기준으로 성공을 판단할 것인가?
개발팀은 무엇을 구현해야 하는가?
```

---

# 1. 문서 기본 정보

| 항목 | 내용 |
| --- | --- |
| 문서명 | MIDO PRD |
| 버전 | v0.1 |
| 작성일 | 2026-07-03 |
| 작성자 | MIDO 팀 |
| 제품/서비스명 | MIDO (AI Code Responsibility Layer) |
| 대상 릴리즈 | MVP |
| 문서 상태 | Draft |
| 관련 문서 | `spring/docs/openapi.yaml`, `spring/README.md`, SRS(예정), ERD(예정) |

---

# 2. 제품 한 줄 소개

## 2.1 One-liner

```
MIDO는 AI 협업 실무자가 "이 결과를 써도 되는가?"라는 판단을 작업 중에 즉시 내릴 수 있도록,
팀 기준 가이드라인·유사 사례·판단 근거 자동 기록을 제공하는 과정 중심 업무 효율화 서비스다.
```

**핵심 한 문장**

> 이 제품은 AI의 결과를 관리하는 시스템이 아니라, **인간의 판단 과정을 가속하는 시스템**이다.

---

# 3. 배경 및 문제 정의

## 3.1 현재 상황

- AI 도입으로 코드·문서·디자인 시안 등 **결과물 생성 속도는 크게 향상**되었으나, 실제 기업 현장의 **업무 리드타임은 크게 줄어들지 않음**
- 실무자는 AI 결과물을 빠르게 선택·수정해야 하지만, 팀 기준이 명확하지 않아 매번 눈치 판단을 함
- 시니어/리뷰어는 반복적인 검토·수정·설명에 리소스를 소모하며, 같은 피드백을 계속 반복함
- 관리자는 AI 활용 리스크 관리, 책임 소재·감사 대응을 위해 판단 근거를 시스템적으로 남길 필요가 있음
- 기존 업무 흐름: `결과 생성 → 검토 → 수정 → 설명 → 승인` (사후 검토 중심)

## 3.2 핵심 문제

| 문제 ID | 문제 내용 | 영향을 받는 사용자 | 현재 영향 |
| --- | --- | --- | --- |
| P-001 | AI 결과물 증가에 따른 **사후 검토(Post-hoc Judgment) 비용 증가** | 실무자, 시니어 | AI로 절약한 시간이 검증 단계에서 재소모 |
| P-002 | "이 결과를 써도 되는가?"에 대한 **신뢰 불확실성** | 실무자 | 판단 지연, 재작업, 불안 증가 |
| P-003 | 시니어 판단이 **항상 결과 이후에만 개입** → 병목 발생 | 시니어, 실무자 | 승인 대기 시간 증가, 리드타임 정체 |
| P-004 | 판단 근거가 남지 않아 **책임 소재·설명 비용 증가** | 관리자, 시니어 | 감사·설명 요청 시 추가 작업 발생 |
| P-005 | 팀의 암묵적 판단 기준이 **문서화·전파되지 않음** | 실무자, 시니어 | 동일 유형 재작업 반복 |

## 3.3 해결해야 할 핵심 질문

```
사용자가 어떤 상황에서 멈추는가?
→ AI 결과를 받았을 때 "팀 기준에 맞는지" 확신하지 못해 판단을 미루거나, 시니어 승인을 기다릴 때

어떤 데이터가 흩어져 있는가?
→ Git 커밋/PR/Diff, 팀 승인·반려 이력, 인간 개입 시점, 판단 근거가 각 도구에 분산

어떤 판단을 시스템이 도와줘야 하는가?
→ "이 AI 결과를 그대로 쓸지, 수정할지, 무시할지"를 작업 중 즉시 판단할 수 있도록 팀 기준·유사 사례 제시

어떤 업무를 자동화해야 하는가?
→ 판단 근거 기록, 유사 과거 사례 매칭, 팀 패턴 기반 가이드라인 추천, 승인 흐름 단축
```

---

# 4. 목표와 성공 지표

## 4.1 제품 목표

| 목표 ID | 목표 | 설명 |
| --- | --- | --- |
| G-001 | 사후 검증 중심 구조 해체 | "다 만들고 나서 검토" → "만드는 중에 판단"으로 전환 |
| G-002 | 팀 기준에 맞는 결과물 생성 확률 증가 | Git/PR 패턴 기반 가이드라인으로 실무자 자율 판단 지원 |
| G-003 | 판단 근거 자동 기록 | 승인·의사결정 속도 단축, 설명 비용 감소 |
| G-004 | 팀 암묵적 기준의 시스템 자산화 | 반복 수정·승인/반려 패턴을 가이드라인으로 축적 |

## 4.2 성공 지표

| 지표 ID | 성공 지표 | 측정 방식 | 목표값 (MVP 이후) |
| --- | --- | --- | --- |
| M-001 | 판단 근거 자동 기록률 | DecisionLog 생성 건수 / 판단 완료 건수 | 90% 이상 |
| M-002 | 시니어 승인 소요 시간 | 판단 완료 ~ 승인 완료 시간 | 30% 감소 |
| M-003 | 동일 유형 재작업 비율 | 동일 contextType·유사 코드 재검증 건수 | 20% 감소 |
| M-004 | Verification 완료율 | DONE 상태 / 생성 건수 | 70% 이상 |
| M-005 | 감사 대응 추가 작업 건수 | 감사 요청 시 수동 자료 작성 건수 | 50% 감소 |

---

# 5. 사용자 및 이해관계자

## 5.1 주요 사용자

| 사용자 유형 | 설명 | 주요 니즈 |
| --- | --- | --- |
| Primary User (실무자) | 개발자, 디자이너, 기획자 | AI 결과를 빠르게 선택·수정; 팀 기준에 맞는지 즉시 확인 |
| Secondary User (시니어/리뷰어) | 시니어 개발자, 테크 리드 | 반복 검토·설명 감소; 근거가 자동으로 남는 승인 흐름 |
| Admin (관리자) | 조직 운영자, 컴플라이언스 담당 | AI 리스크 관리; 판단 이력 감사 조회 |

## 5.2 이해관계자

| 이해관계자 | 관심사 | 영향도 |
| --- | --- | --- |
| 기획/PM | 범위, 우선순위, 일정 | 높음 |
| 개발 | 요구사항 명확성, API, DB, 예외처리 | 높음 |
| 디자인 | 4단계 위저드 UX, 판단 흐름 | 중간 |
| QA | 테스트 가능성, 수용 기준 | 높음 |
| 운영/CS | 장애 대응, 로그 조회 | 중간 |

---

# 6. 범위 정의

## 6.1 In Scope

이번 버전(MVP)에 포함되는 기능:

| 기능 ID | 기능명 | 설명 | 우선순위 |
| --- | --- | --- | --- |
| F-001 | 판단 대상 입력 (Manual Input) | PASTE/FILE/COMMIT/PR 4가지 입력 모드로 Verification 세션 생성 | P0 |
| F-002 | 파일 업로드 | FILE 모드 시 소스 코드 파일 업로드 및 code 필드 반영 | P0 |
| F-003 | 작업 컨텍스트 조회 | repo/commit/PR/파일명 기반 판단 맥락 요약 제공 | P0 |
| F-004 | 판단 수행 UI | AI 리스크·팀 가이드라인 기반 Use/Fix/Ignore 결정 | P0 |
| F-005 | 판단 기록 (Decision Log) | 결정 내용·시각·근거 자동 저장 | P0 |
| F-006 | 팀 코드/작업 패턴 분석 | Git 커밋, PR, Diff 기반 암묵적 기준 추출 | P1 |
| F-007 | 실시간 AI 가이드라인 제공 | 과거 팀 기준 기반 데이터 추천 | P1 |
| F-008 | 역할 기반 접근 제어 (RBAC) | 실무자/시니어/관리자 권한 분리 | P1 |

## 6.2 Out of Scope

이번 버전에 포함하지 않는 기능:

| 제외 항목 | 제외 이유 | 향후 검토 시점 |
| --- | --- | --- |
| AI 모델 자체 정확도/성능 개선 | 제품 목적이 아님 (비목표) | 해당 없음 |
| 완전 자동 의사결정 | 인간 판단 우선 원칙 | 해당 없음 |
| 조직 문화·평가 제도 개편 | 제품 범위 외 | 해당 없음 |
| 인간 판단 제거 | 제품 철학과 상충 | 해당 없음 |
| 멀티 테넌트 SaaS 과금/결제 | MVP 범위 초과 | v2.0 |
| IDE 플러그인 통합 | 기술 리스크·일정 | v1.1 |

---

# 7. 가정, 제약, 의존성

## 7.1 Assumptions

| ID | 가정 | 검증 방법 |
| --- | --- | --- |
| A-001 | 팀은 Git 기반 협업을 하며 커밋/PR 이력이 충분히 존재한다 | 파일럿 팀 Git 이력 분석 |
| A-002 | 실무자는 AI 결과에 대해 Use/Fix/Ignore 3가지 판단으로 충분하다 | 사용자 인터뷰 |
| A-003 | 가이드라인은 권고 수준이면 맹신 리스크를 줄일 수 있다 | UX 테스트 |
| A-004 | PostgreSQL 단일 DB로 MVP 트래픽을 처리할 수 있다 | 부하 테스트 |

## 7.2 Constraints

| ID | 제약사항 | 영향 |
| --- | --- | --- |
| C-001 | 백엔드: Java 21, Spring Boot 3.5, PostgreSQL | 기술 스택 고정 |
| C-002 | 프론트엔드: Next.js + TypeScript (기존 프로토타입 기반) | UI 재연결 필요 |
| C-003 | Git/PR 외부 API 연동 미구현 (MVP 1차) | COMMIT/PR 모드는 메타데이터만 저장 |
| C-004 | 인증/인가 미구현 | MVP 1차는 단일 사용자 가정 |

## 7.3 Dependencies

| ID | 의존 대상 | 설명 | 담당 |
| --- | --- | --- | --- |
| D-001 | PostgreSQL | Verification 데이터 영속화 | 인프라 |
| D-002 | GitHub/GitLab API (향후) | COMMIT/PR 모드 실제 코드·Diff 조회 | 백엔드 |
| D-003 | LLM API (향후) | AI 리스크 분석, 가이드라인 추천 | 백엔드/AI |

---

# 8. 사용자 시나리오 / 유스케이스

## 8.1 대표 사용자 시나리오

```
실무자는 AI가 생성한 코드를 검토해야 하는 상황에서,
팀 기준에 맞는지 즉시 판단하기 위해 MIDO에 판단 대상을 입력한다.
시스템은 작업 컨텍스트(저장소, 커밋, 유사 사례)를 제공하고,
실무자는 Use/Fix/Ignore 중 하나를 선택한다.
시스템은 판단 근거를 자동 기록하여 시니어가 추가 설명 없이 승인할 수 있게 한다.
```

## 8.2 유스케이스 목록

| UC ID | 유스케이스명 | Actor | Trigger | Main Flow | 결과 |
| --- | --- | --- | --- | --- | --- |
| UC-001 | 판단 대상 수동 입력 | 실무자 | 입력 완료 버튼 클릭 | 1. inputType 선택 2. 필수값 입력 3. 검증 4. Verification 생성 | DRAFT 상태 세션 생성 |
| UC-002 | 파일 업로드 | 실무자 | FILE 모드에서 파일 선택 | 1. Verification ID 확인 2. multipart 업로드 3. code 필드 반영 | 업로드 완료 |
| UC-003 | 작업 컨텍스트 조회 | 실무자 | 컨텍스트 화면 진입 | 1. Verification ID로 조회 2. repo/commit/PR/파일명 요약 반환 | 맥락 확인 |
| UC-004 | 판단 수행 | 실무자 | 판단 화면에서 결정 선택 | 1. AI 리스크·가이드라인 확인 2. Use/Fix/Ignore 선택 3. 근거 기록 | 판단 완료 |
| UC-005 | 판단 기록 조회 | 시니어 | Decision Log 화면 진입 | 1. 판단 이력 조회 2. 근거·시각 확인 3. 승인 | 승인 완료 |
| UC-006 | 팀 패턴 분석 (향후) | 시스템 | Git 연동 완료 시 | 1. 커밋/PR 수집 2. 패턴 분석 3. 가이드라인 생성 | 팀 가이드라인 갱신 |

---

# 9. 기능 요구사항

## 9.1 기능 요구사항 작성 규칙

각 기능은 아래 형식으로 작성한다.

```
FR-[번호]
시스템은 [사용자/조건]이 [행동]할 때 [결과]를 제공해야 한다.
```

## 9.2 기능 요구사항 목록

| ID | 기능명 | 요구사항 | 우선순위 | 관련 유스케이스 | 구현 상태 |
| --- | --- | --- | --- | --- | --- |
| FR-001 | 판단 대상 수동 입력 | 시스템은 실무자가 inputType·inputMethod와 유형별 필수값을 제출할 때 VerificationData·ManualInput·WorkContext를 생성하고 id·status·nextAction을 반환해야 한다. | P0 | UC-001 | ✅ 구현됨 |
| FR-002 | 입력 유형별 검증 | 시스템은 PASTE 시 rawInput, COMMIT 시 repoUrl+commitHash, PR 시 repoUrl+prNumber(≥1)가 없으면 400 에러를 반환해야 한다. | P0 | UC-001 | ✅ 구현됨 |
| FR-003 | 파일 업로드 | 시스템은 FILE 모드 Verification에 대해 multipart 파일을 수신하여 UploadedFile을 저장하고 VerificationData.code를 갱신해야 한다. | P0 | UC-002 | ✅ 구현됨 |
| FR-004 | 작업 컨텍스트 조회 | 시스템은 Verification ID로 repoUrl·commitHash·prNumber·fileName·contextType 요약을 반환해야 한다. | P0 | UC-003 | ✅ 부분 구현 |
| FR-005 | 판단 수행 | 시스템은 실무자가 Use/Fix/Ignore를 선택할 때 DecisionLog를 생성하고 Verification 상태를 DONE으로 변경해야 한다. | P0 | UC-004 | ❌ 미구현 |
| FR-006 | AI 리스크 분석 | 시스템은 code 기반으로 리스크 항목(심각도·설명)을 반환해야 한다. | P0 | UC-004 | ❌ 미구현 |
| FR-007 | 팀 가이드라인 제시 | 시스템은 유사 과거 사례·팀 판단 패턴을 기반으로 권고 가이드라인을 반환해야 한다. | P1 | UC-003, UC-004 | ❌ 미구현 |
| FR-008 | Git/PR 코드 조회 | 시스템은 COMMIT/PR 모드에서 외부 Git API로 실제 코드·Diff를 가져와 code 필드를 채워야 한다. | P1 | UC-001 | ❌ 미구현 |
| FR-009 | 판단 로그 불변성 | 시스템은 생성된 DecisionLog를 수정·삭제할 수 없어야 한다. | P1 | UC-005 | ❌ 미구현 |
| FR-010 | RBAC | 시스템은 역할(실무자/시니어/관리자)에 따라 API 접근을 제한해야 한다. | P1 | UC-005 | ❌ 미구현 |

## 9.3 기능 상세

### FR-001. 판단 대상 수동 입력

#### 설명

실무자가 AI 결과물 또는 검토 대상 코드를 4가지 방식(PASTE, FILE, COMMIT, PR) 중 하나로 입력하여 Verification 세션을 시작한다.

#### 입력값

| 필드 | 타입 | 필수 여부 | 설명 |
| --- | --- | --- | --- |
| inputType | string | Y | `PASTE`, `FILE`, `COMMIT`, `PR` |
| inputMethod | string | Y | `TEXTAREA`, `FILE_UPLOAD` 등 |
| rawInput | string | PASTE 시 Y | 붙여넣기 텍스트 |
| repoUrl | string | COMMIT/PR 시 Y | Git 저장소 URL |
| commitHash | string | COMMIT 시 Y | 커밋 해시 |
| prNumber | integer | PR 시 Y | PR 번호 (≥1) |
| code | string | N | 정규화된 코드 (선택 입력) |

#### 처리 규칙

| 규칙 ID | 규칙 |
| --- | --- |
| BR-001 | VerificationData, ManualInput, WorkContext를 단일 트랜잭션으로 생성한다 |
| BR-002 | 초기 status는 `DRAFT`이다 |
| BR-003 | inputType이 `FILE`이면 nextAction은 `UPLOAD_FILE`, 그 외는 `VIEW_CONTEXT`이다 |

#### 예외 상황

| 예외 ID | 상황 | 시스템 동작 |
| --- | --- | --- |
| E-001 | inputType 누락 | 400, "inputType is required" |
| E-002 | 유형별 필수값 누락 | 400, 필드별 에러 메시지 |
| E-003 | 지원하지 않는 inputType | 400, "Unsupported inputType" |

#### 수용 기준

```
Given 실무자가 PASTE 모드로 rawInput을 입력했을 때
When POST /api/verifications/manual을 호출하면
Then HTTP 201, id·status=DRAFT·nextAction=VIEW_CONTEXT가 반환되고 DB에 3개 엔티티가 저장된다.
```

---

### FR-003. 파일 업로드

#### 설명

FILE 모드에서 생성된 Verification에 텍스트 기반 소스 파일을 업로드한다.

#### 입력값

| 필드 | 타입 | 필수 여부 | 설명 |
| --- | --- | --- | --- |
| id | UUID (path) | Y | VerificationData ID |
| file | binary (multipart) | Y | 업로드 파일 |

#### 처리 규칙

| 규칙 ID | 규칙 |
| --- | --- |
| BR-004 | 파일 내용을 UploadedFile.fileContent에 저장한다 |
| BR-005 | 파일 내용을 VerificationData.code에 복사한다 |

#### 수용 기준

```
Given FILE 모드 Verification이 존재할 때
When POST /api/verifications/{id}/upload로 파일을 업로드하면
Then UploadedFile이 저장되고 VerificationData.code가 파일 내용으로 갱신된다.
```

---

### FR-005. 판단 수행 (미구현)

#### 설명

실무자가 AI 리스크·팀 가이드라인을 참고하여 Use/Fix/Ignore 중 하나를 선택하고 판단을 완료한다.

#### 입력값

| 필드 | 타입 | 필수 여부 | 설명 |
| --- | --- | --- | --- |
| verificationId | UUID | Y | 대상 Verification |
| decision | enum | Y | `USE`, `FIX`, `IGNORE` |
| rationale | string | N | 추가 판단 근거 (자동 생성 + 수동 보완) |

#### 처리 규칙

| 규칙 ID | 규칙 |
| --- | --- |
| BR-006 | DecisionLog는 생성 후 수정·삭제 불가 |
| BR-007 | 판단 완료 시 Verification status를 `DONE`으로 변경 |
| BR-008 | rationale에 참조한 가이드라인·리스크 ID를 포함 |

#### 수용 기준

```
Given READY 상태 Verification이 존재할 때
When 실무자가 decision=USE로 판단을 제출하면
Then DecisionLog가 생성되고 status=DONE이며 rationale이 자동 기록된다.
```

---

# 10. 비기능 요구사항

| ID | 구분 | 요구사항 | 기준 |
| --- | --- | --- | --- |
| NFR-001 | 성능 | 주요 API 응답 시간 | 95% 요청 1초 이내 (MVP) |
| NFR-002 | 보안 | 인증/인가/권한 | MVP 2차: JWT + RBAC; 관리자만 이력 삭제 불가 정책 설정 |
| NFR-003 | 가용성 | 서비스 운영 기준 | 장애 시 에러 로그 기록, DB 트랜잭션 롤백 |
| NFR-004 | 사용성 | 판단 완료까지 단계 수 | 4단계 이내 (입력 → 컨텍스트 → 판단 → 기록) |
| NFR-005 | 호환성 | 브라우저 | Chrome, Safari, Firefox 최신 2버전 |
| NFR-006 | 감사/로그 | 중요 행위 기록 | Verification 생성/판단/승인 시점·주체·근거 불변 저장 |
| NFR-007 | 데이터 무결성 | 판단 로그 변경 불가 | DecisionLog UPDATE/DELETE API 미제공 |

---

# 11. 데이터 요구사항

## 11.1 주요 데이터

| 데이터 객체 | 설명 | 주요 필드 |
| --- | --- | --- |
| VerificationData | 판단 세션 (중심 애그리거트) | id, inputType, repoUrl, commitHash, prNumber, code, status, createdAt, updatedAt |
| ManualInput | 수동 입력 원본 | id, verificationDataId, inputMethod, rawInput, createdAt |
| UploadedFile | 업로드 파일 | id, verificationDataId, fileName, fileType, fileContent, uploadedAt |
| WorkContext | 작업 맥락 요약 | id, verificationDataId, displayRepoUrl, displayCommitHash, displayPrNumber, createdAt |
| DecisionLog (예정) | 판단 기록 | id, verificationDataId, decision, rationale, decidedBy, decidedAt |
| TeamGuideline (예정) | 팀 가이드라인 | id, teamId, pattern, recommendation, sourceCases |
| Approval (예정) | 시니어 승인 | id, decisionLogId, approvedBy, approvedAt, comment |

## 11.2 데이터 관계 초안

```
VerificationData 1:N ManualInput
VerificationData 1:N UploadedFile
VerificationData 1:1 WorkContext
VerificationData 1:1 DecisionLog
VerificationData N:1 Team (향후)
TeamGuideline N:1 Team (향후)
DecisionLog 1:1 Approval (향후)
```

## 11.3 DB 설계로 넘길 항목

| 항목 | 설명 |
| --- | --- |
| Entity 후보 | verification_data, manual_input, uploaded_file, work_context, decision_log, team_guideline, approval |
| Key 후보 | PK: UUID; FK: verification_data_id |
| Index 후보 | verification_data(input_type, created_at), decision_log(verification_data_id), decision_log(decided_at) |
| 상태값 | VerificationData.status: DRAFT, READY, PROCESSING, DONE, FAILED |
| 이력 관리 | created_at, updated_at; DecisionLog는 append-only |

---

# 12. 화면 및 사용자 흐름

## 12.1 주요 화면

| 화면 ID | 화면명 | 목적 |
| --- | --- | --- |
| UI-001 | Manual Input (판단 대상 입력) | taskTitle, purpose, 입력 방식·코드 입력 |
| UI-002 | Work Context (판단 맥락 고정) | 대상 요약, 유사 사례, 팀 판단 패턴 확인 |
| UI-003 | Judgment Action (판단 수행) | AI 리스크, 팀 가이드라인, Use/Fix/Ignore 선택 |
| UI-004 | Decision Log (판단 기록 완료) | 결정 요약, 시각, 감사용 로그 확인 |

## 12.2 사용자 흐름

```
진입 (UI-001)
 ↓
판단 대상 입력 (PASTE/FILE/COMMIT/PR)
 ↓
[FILE 모드] 파일 업로드
 ↓
작업 컨텍스트 확인 (UI-002)
 ↓
AI 리스크·가이드라인 검토 (UI-003)
 ↓
Use / Fix / Ignore 판단
 ↓
판단 기록 확인 (UI-004)
 ↓
[시니어] 승인
```

## 12.3 화면별 기능 매핑

| 화면 | 관련 기능 | 관련 API | 비고 |
| --- | --- | --- | --- |
| UI-001 | FR-001, FR-002 | POST /api/verifications/manual | ✅ 연동 필요 (프론트 재구축) |
| UI-001 (FILE) | FR-003 | POST /api/verifications/{id}/upload | ✅ |
| UI-002 | FR-004, FR-007 | GET /api/verifications/{id}/context | ✅ 부분 |
| UI-003 | FR-005, FR-006 | POST /api/verifications/{id}/decision (예정) | ❌ |
| UI-004 | FR-005, FR-009 | GET /api/verifications/{id}/decision (예정) | ❌ |

---

# 13. API 요구사항 초안

| API ID | Method | Endpoint | 목적 | 관련 기능 | 상태 |
| --- | --- | --- | --- | --- | --- |
| API-001 | POST | /api/verifications/manual | Verification 생성 | FR-001 | ✅ |
| API-002 | POST | /api/verifications/{id}/upload | 파일 업로드 | FR-003 | ✅ |
| API-003 | GET | /api/verifications/{id}/context | 작업 컨텍스트 조회 | FR-004 | ✅ |
| API-004 | POST | /api/verifications/{id}/analyze | AI 리스크 분석 | FR-006 | ❌ |
| API-005 | GET | /api/verifications/{id}/guidelines | 팀 가이드라인 조회 | FR-007 | ❌ |
| API-006 | POST | /api/verifications/{id}/decision | 판단 제출 | FR-005 | ❌ |
| API-007 | GET | /api/verifications/{id}/decision | 판단 기록 조회 | FR-005 | ❌ |
| API-008 | POST | /api/verifications/{id}/approve | 시니어 승인 | FR-010 | ❌ |

---

# 14. 정책 및 비즈니스 규칙

| 정책 ID | 정책명 | 설명 | 관련 기능 |
| --- | --- | --- | --- |
| POL-001 | 인간 판단 우선 | AI 가이드라인은 권고 수준이며, 최종 결정은 항상 인간이 한다 | FR-005, FR-007 |
| POL-002 | 입력 유형별 필수값 | PASTE→rawInput, COMMIT→repoUrl+commitHash, PR→repoUrl+prNumber | FR-002 |
| POL-003 | FILE 2단계 흐름 | FILE 모드는 manual 생성 후 별도 upload API 호출이 필요하다 | FR-001, FR-003 |
| POL-004 | 판단 로그 불변 | DecisionLog 생성 후 수정·삭제 불가 | FR-009, NFR-007 |
| POL-005 | 상태 전이 | DRAFT → READY → PROCESSING → DONE / FAILED | FR-001, FR-005 |

---

# 15. 우선순위

| 우선순위 | 의미 |
| --- | --- |
| P0 | MVP에 반드시 포함. 없으면 핵심 가치(판단 가속)가 성립하지 않음 |
| P1 | 중요하지만 P0 이후 개발 가능 |
| P2 | 있으면 좋지만 후순위 |
| P3 | 이번 범위에서 제외 가능 |

---

# 16. 릴리즈 계획

| 단계 | 목표 | 포함 기능 |
| --- | --- | --- |
| MVP-1 (현재) | 입력 파이프라인 검증 | FR-001~004 (Manual Input, Upload, Context) |
| MVP-2 | 핵심 판단 흐름 완성 | FR-005~006, UI-001~004 백엔드 연동, DecisionLog |
| v1.0 | 기본 운영 가능 | FR-007~010, RBAC, Git 연동, 팀 패턴 분석 |
| v1.1 | 개선 및 자동화 | 실시간 가이드라인 고도화, IDE 연동 검토 |
| v2.0 | 확장 | 멀티 테넌트, 조직 대시보드, 감사 리포트 |

---

# 17. 리스크 및 대응 방안

| 리스크 ID | 리스크 | 영향도 | 대응 방안 |
| --- | --- | --- | --- |
| R-001 | 팀 Git 데이터 부족 (초기 단계) | 높음 | 수동 가이드라인 시드 데이터, 파일럿 팀 선정 |
| R-002 | 특정 시니어 기준에 과도 편향 | 중간 | 다수 리뷰어 패턴 가중, 권고 수준 명시 |
| R-003 | AI 가이드 맹신 | 중간 | POL-001 인간 판단 우선, UI에 권고 문구 표시 |
| R-004 | 프론트엔드-백엔드 단절 | 높음 | MVP-2에서 API 연동 우선, OpenAPI 스펙 정합 |
| R-005 | OpenAPI와 구현 불일치 | 낮음 | openapi.yaml을 VerificationCreateResponse 기준으로 갱신 |

---

# 18. 오픈 질문

| 질문 ID | 질문 | 담당자 | 상태 |
| --- | --- | --- | --- |
| Q-001 | GitHub vs GitLab 우선 연동 대상은? | 백엔드 | Open |
| Q-002 | LLM 제공자 및 온프레미스 요구 여부? | AI/인프라 | Open |
| Q-003 | MVP에서 인증 없이 파일럿할지, JWT부터 도입할지? | PM/보안 | Open |
| Q-004 | DecisionLog에 PII(작성자 이메일) 포함 범위? | PM/법무 | Open |
| Q-005 | 기존 Next.js 프론트를 복원할지 새로 작성할지? | 프론트 | Open |

---

# 19. SRS로 넘길 요구사항

| PRD 항목 | SRS 변환 항목 |
| --- | --- |
| 기능 요구사항 (FR-001~010) | 시스템 기능 요구사항 |
| 비기능 요구사항 (NFR-001~007) | 품질 속성 요구사항 |
| 유스케이스 (UC-001~006) | 상세 시나리오 |
| 데이터 요구사항 (§11) | 데이터 모델 / DB 요구사항 |
| API 초안 (§13) | 인터페이스 요구사항 |
| 정책/규칙 (POL-001~005) | 비즈니스 룰 명세 |
| 수용 기준 (FR별 Given/When/Then) | 테스트 기준 |

---

# 20. 품질 체크리스트

| 체크 항목 | 확인 |
| --- | --- |
| 사용자가 누구인지 명확한가? | ☑ |
| 해결할 문제가 구체적인가? | ☑ |
| 목표와 성공 지표가 연결되는가? | ☑ |
| MVP 범위가 P0 중심으로 정리되었는가? | ☑ |
| 기능 요구사항이 FR 단위로 나뉘었는가? | ☑ |
| 각 기능에 유스케이스가 연결되는가? | ☑ |
| 기능별 입력값, 처리 규칙, 예외 상황이 있는가? | ☑ (P0 상세) |
| 비기능 요구사항이 있는가? | ☑ |
| 주요 데이터와 DB 후보가 보이는가? | ☑ |
| API 초안으로 변환 가능한가? | ☑ |
| SRS로 넘길 수 있을 정도로 모호하지 않은가? | ☑ |
| Out of Scope가 명확한가? | ☑ |
| 리스크와 오픈 질문이 정리되었는가? | ☑ |
| 현재 구현 상태가 반영되었는가? | ☑ |
