# QA-03 Review & Inspection Report

> **정합성 기준:** PRD_v0 · SRS_v0 · SDD_v0

> **판정 원칙:** 실행 증거 없는 기능·테스트는 PASS가 아니라 PLANNED 또는 NOT RUN이다. AI는 승인자가 아니며 사람의 Use/Fix/Ignore 및 리뷰 승인을 우회할 수 없다.

---

## 1. 검토 범위

PRD, SRS, SDD, AI-01~08, DE-01~05, DA-01~04, QA-01~07, BE 문서와 현재 확인된 구현 정보를 정적 검토한다. 이 문서는 실행 테스트 결과가 아니다.

---

## 2. 정합성 검토 결과

### 확인된 일치

- 제품은 AI 자동 승인 시스템이 아닌 인간 의사결정 지원 계층
- 핵심 흐름 Manual Input → Context → Risk → Decision → Approval
- Controller → Service → Repository, 생성자 DI, DTO / entity 분리
- create에서 VerificationData + ManualInput + WorkContext 원자적 저장
- upload 부분 갱신, read-only 조회, projection, open-in-view=false
- Context 응답에서 code LOB 제외
- persisted verification status와 GlobalExceptionHandler
- Flyway / validate, status / input_type index, DRAFT partial index
- 목록 N+1 회귀 기준 query ≤2

### 문서 정규화 조치

- 상태 용어를 PROCESSING이 아닌 RUNNING으로 통일
- “status가 DTO에만 존재”라는 과거 gap을 현재 구현과 맞게 제거
- GlobalExceptionHandler 미구현 표기를 IMPLEMENTED로 교정
- AI / Decision / Approval / RBAC / Git는 증거 없으므로 PLANNED 유지
- AI·분석·QA의 실제 성과 / 통과 수치는 NOT TESTED / NOT MEASURED로 표기

---

## 3. 잔여 설계 이슈

- 상태 전이와 재시도 / 재개 정책의 DB / Service 강제 방식
- DecisionLog 중복·불변·rationale 정책
- Approval 대상 선정과 reviewer 역할
- TeamGuideline 승인·버전·만료·ACL
- AI provider / RAG / output schema / evaluation threshold
- Git credential·repository authorization
- 데이터 보존·삭제·감사 정책

이들은 구현 전에 ADR 또는 SRS / SDD 개정으로 확정해야 한다.

---

## 4. 정적 코드 / DB 검사 항목

Layer 위반, entity 외부 노출, transaction boundary, null / validation, query projection, lazy load, exception mapping, migration ordering, index selectivity, secret logging, upload path traversal를 검사한다.

---

## 5. 판정

- 문서 정합성: 조건부 적합. 직군 문서 기준은 통일했으나 baseline 문서의 잔여 구식 표현은 개정 필요.
- 구현 검증: 부분 확인. 구현 근거가 있는 기능만 대상.
- 실행 품질: NOT RUN. CI / test report와 실행 환경 증거 필요.
- release: 본 리뷰만으로 GO 판정 불가.

---

## 6. 후속 조치

BE-01~07 생성, SRS / SDD 구현 상태 갱신, QA-05 실제 실행, AI 기능 구현 시 별도 evaluation, P0 / P1 defect closure, QA-07 gate 재검토를 수행한다.
