# QA-05 Test Case & Execution

> **정합성 기준:** PRD_v0 · SRS_v0 · SDD_v0

> **판정 원칙:** 실행 증거 없는 기능·테스트는 PASS가 아니라 PLANNED 또는 NOT RUN이다. AI는 승인자가 아니며 사람의 Use/Fix/Ignore 및 리뷰 승인을 우회할 수 없다.

---

## 1. 실행 상태

이 문서는 상세 test case와 실행 기록 형식을 정의한다. 현재 connector에서 CI·코드 실행 증거를 확인하지 않았으므로 전체 상태는 **NOT RUN**이다.

---

## 2. 핵심 테스트 케이스

- TC-MAN-001 정상 manual 생성 → 201, 3개 연관 row, status DRAFT
- TC-MAN-002 필수값 누락 → 400, 저장 0
- TC-MAN-003 세 번째 insert 실패 → 전체 rollback
- TC-UP-001 정상 upload → metadata 저장 + code 부분 update
- TC-UP-002 empty / oversize / MIME mismatch → 4xx, 저장 0
- TC-CTX-001 context 조회 → 계약 필드, code LOB 없음
- TC-CTX-002 없는 id → 표준 404 error
- TC-LIST-001 pagination / projection → entity / LOB 미노출
- TC-LIST-002 N+1 회귀 → query count ≤2
- TC-STS-001 정상 상태 전이 → DRAFT → READY → RUNNING → DONE
- TC-STS-002 불가능 전이 → 409, 상태 불변
- TC-AI-001 valid analysis output → schema / evidence / version 저장
- TC-AI-002 provider timeout → retry 정책 후 FAILED
- TC-AI-003 injection / secret → 지시 무시, secret 미전송 / 미로그
- TC-DEC-001 Use / Fix / Ignore → DecisionLog 1건
- TC-DEC-002 중복 decision → 정책상 차단 / 버전 처리
- TC-APR-001 reviewer 승인 → 권한·감사 기록
- TC-SEC-001 다른 팀 verification / guideline → 403 / 404와 누출 0
- TC-DB-001 clean / upgrade migration → validate 성공
- TC-DB-002 status / input_type index → 계획 검증
- TC-RES-001 재시도 / backfill → 중복 결과 0

---

## 3. 실행 기록 필수 필드

run_id, case_id, requirement_id, build / commit, environment, data_version, executed_at, executor, expected, actual, status(PASS / FAIL / BLOCKED / NOT RUN), evidence URL, defect ID.

---

## 4. 판정 규칙

실행하지 않은 case는 `NOT RUN`, 환경 / 의존성 문제는 `BLOCKED`, expected와 actual 불일치는 `FAIL`이다.

Screenshot만으로 DB 정합성·보안·성능을 PASS하지 않는다.

---

## 5. 현재 기록

- Manual / Upload / Context 구현 근거: 확인됨
- 실제 automated test report: 미첨부
- DB migration / EXPLAIN 실제 출력: 미첨부
- AI / Decision / Approval / RBAC / Git 구현 및 실행: 미확인

따라서 release PASS 수치와 defect-free 주장을 작성하지 않는다.

---

## 6. 재실행

FAIL 수정 후 원 case와 인접 risk regression을 재실행한다.

Flaky는 PASS로 덮지 않고 재현율·원인·격리 기간을 기록한다.

Environment와 fixture가 달라지면 새 run_id를 사용한다.

---

## 7. 완료 조건

P0 / P1 case에 실제 evidence가 있고, QA-02 trace coverage와 QA-06 defect 상태가 일치해야 QA-07에서 GO 검토가 가능하다.

