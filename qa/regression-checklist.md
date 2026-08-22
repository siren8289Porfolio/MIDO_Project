# Regression Checklist

**상태:** PLANNED / NOT EXECUTED

수정 후에는 수정 component뿐 아니라 의존 API, DB, AI 산출물, 사람 승인, 감사 이력을 함께 확인한다.

---

## Regression 범위

| 항목 | 확인 내용 | 상태 |
| --- | --- | --- |
| 수정 component | 변경된 Controller / Service / Repository / DTO / Entity | PLANNED / NOT EXECUTED |
| 의존 API | 호출 endpoint, request, response, error code 영향 | PLANNED / NOT EXECUTED |
| 의존 DB | table, column, index, migration, transaction 영향 | PLANNED / NOT EXECUTED |
| AI 산출물 분리 | AI generated output과 human decision이 분리 저장되는지 | PLANNED / NOT EXECUTED |
| 사람 승인 | 승인자, 승인 일시, 승인 근거가 기록되는지 | PLANNED / NOT EXECUTED |
| Code lineage | 요청, 입력 코드, 생성 코드, commit, PR 연결성이 유지되는지 | PLANNED / NOT EXECUTED |
| Secret masking | 로그, prompt, evidence, API 응답에 secret이 노출되지 않는지 | PLANNED / NOT EXECUTED |
| 모델 버전 | model name/version이 기록되는지 | PLANNED / NOT EXECUTED |
| Prompt version | prompt template/version/hash가 기록되는지 | PLANNED / NOT EXECUTED |
| Audit | 생성, 분석, 판단, 승인, 재검증 이벤트가 남는지 | PLANNED / NOT EXECUTED |
| 과거 재발 영역 | 동일 defect 또는 유사 defect 재발 여부 | PLANNED / NOT EXECUTED |

---

## Retest 기록 원칙

| 항목 | 기준 |
| --- | --- |
| 수정 build | commit hash 또는 build 번호를 기록 |
| Retest evidence | 테스트 로그, API 응답, 스크린샷, DB 조회 결과 중 하나 이상 기록 |
| 승인자 | 사람 승인자와 승인 일시 기록 |
| 미실행 항목 | `PLANNED / NOT EXECUTED` 유지 |
| 차단 항목 | 차단 사유와 해소 조건 기록 |

재현 불가만으로 close하지 않는다. 수정 build, retest evidence, 승인자를 함께 기록한다.

