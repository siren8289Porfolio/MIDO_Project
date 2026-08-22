# Defect Log Template

**상태:** PLANNED / NOT EXECUTED

실행 근거가 없는 defect는 완료 또는 종료로 표시하지 않는다.

---

## Defect Record

| 항목 | 내용 |
| --- | --- |
| DEF-ID | DEF-YYYYMMDD-001 |
| 구분 | build / 환경 / Requirement / TC |
| 발견 build | PLANNED / NOT EXECUTED |
| 발견 환경 | local / dev / staging / prod |
| 관련 Requirement | FR / NFR / BR ID |
| 관련 TC | TC ID |
| 재현 절차 | 1. 2. 3. |
| Expected | 기대 결과 |
| Actual | 실제 결과 |
| Evidence | 로그, 스크린샷, 테스트 결과, API 응답, commit hash |
| Severity | S1 / S2 / S3 / S4 |
| Priority | P0 / P1 / P2 / P3 |
| Owner | 담당자 |
| Root Cause | 분석 전이면 TBD |
| Fix | 수정 전이면 TBD |
| Retest | 재검증 전이면 PLANNED / NOT EXECUTED |
| Approval | 승인 전이면 NOT APPROVED |

---

## Close 조건

Defect는 아래 항목이 모두 채워져야 close할 수 있다.

| 조건 | 필요 기록 |
| --- | --- |
| 수정 build 확인 | build 번호 또는 commit hash |
| 재검증 수행 | retest 실행 일시와 결과 |
| 증거 첨부 | 테스트 로그, API 응답, 스크린샷 등 |
| 승인자 기록 | 사람 승인자, 승인 일시, 판단 근거 |
| 회귀 영향 확인 | `regression-checklist.md` 기준 검토 |

재현 불가 상태만으로 close하지 않는다.

