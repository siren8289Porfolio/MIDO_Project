# Approval Audit Log Template

**상태:** PLANNED / NOT EXECUTED

AI 산출물, 검토 근거, 사람 승인, 의사결정 이력을 분리해 기록한다.

---

## Audit Record

| 항목 | 내용 |
| --- | --- |
| Audit ID | AUD-YYYYMMDD-001 |
| Verification ID | UUID |
| 요청 맥락 | 사용자 요청, 업무 목적, 관련 Requirement / TC |
| 입력 source | PASTE / FILE / COMMIT / PR |
| Code lineage | 원본 코드, 생성 코드, commit hash, PR 번호 |
| AI 산출물 | 생성 코드, 분석 결과, 리스크 요약 |
| 모델 정보 | model name/version |
| Prompt 정보 | prompt version/hash, template ID |
| Secret masking | PASS / FAIL / NOT EXECUTED |
| 검토 근거 | 테스트 결과, 코드 리뷰 근거, 위험 분석 |
| 사람 판단 | USE / FIX / IGNORE / HOLD |
| 승인자 | 이름 또는 계정 |
| 승인 일시 | ISO-8601 timestamp |
| 승인 상태 | NOT APPROVED / APPROVED / REJECTED |
| Evidence | 링크, 로그, 스크린샷, API 응답, DB 조회 결과 |

---

## 분리 기록 원칙

| 구분 | 기록 원칙 |
| --- | --- |
| AI 산출물 | AI가 만든 코드와 분석 결과를 원문 기준으로 보존 |
| 사람 검토 | 사람이 추가한 판단 근거와 수정 의견을 별도 기록 |
| 사람 승인 | 최종 승인자, 승인 일시, 승인 범위를 명시 |
| 의사결정 | USE / FIX / IGNORE 같은 판단 결과와 이유를 남김 |
| 감사 추적 | 생성부터 승인까지 이벤트 순서를 보존 |

실행 근거가 없으면 승인 상태를 `APPROVED`로 바꾸지 않는다.

