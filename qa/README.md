# AI Review Governance

<aside>

**프로젝트:** Mido  
**범위:** AI 생성 코드·요청 맥락 → 검토 근거·리스크 → 사람 승인·의사결정 이력  
**상태:** PLANNED / NOT EXECUTED

</aside>

이 폴더는 Mido에서 AI가 생성한 코드나 작업 결과물을 사람이 검토하고 승인할 때 남겨야 하는 기록 기준을 정의한다.

실행 근거가 없는 항목은 완료로 표시하지 않는다. 실제 테스트, 재검증, 승인 기록이 없으면 상태는 `PLANNED / NOT EXECUTED`로 유지한다.

---

## 1. 목적

Mido의 검증 흐름은 AI 산출물을 자동으로 승인하는 구조가 아니라, 사람이 AI 산출물을 검토하고 근거를 남긴 뒤 사용 여부를 결정하는 구조다.

이 문서는 다음 이력을 남기기 위한 기준이다.

| 구분 | 기록 대상 |
| --- | --- |
| Defect | 결함, 재현 절차, 기대/실제 결과, 수정·재검증 이력 |
| Severity | 결함 영향도와 우선순위 판단 기준 |
| Regression | 수정 영향 범위, 의존 API/DB, AI 산출물·사람 승인 분리 |
| Audit | 모델·프롬프트 버전, code lineage, secret masking, 승인자 |

---

## 2. 공식 기준

| 기준 | 적용 목적 |
| --- | --- |
| ISO/IEC 25010:2023 | 품질 특성, 리스크 분류 기준 |
| ISO/IEC/IEEE 29119 | 테스트 프로세스와 증거 관리 |
| ISTQB CTFL v4.0.1 | 결함, 테스트, 회귀 검증 용어 정합성 |
| NIST SP 800-218 SSDF | 보안 개발, 공급망, secret 관리, 검토 추적 |

---

## 3. 문서 구성

| 파일 | 목적 |
| --- | --- |
| `defect-log-template.md` | Defect 기록 템플릿 |
| `QA-02-quality-requirements-traceability.md` | 요구사항·설계·구현·테스트·증거 추적성 기준 |
| `QA-03-review-inspection-report.md` | 정적 리뷰·정합성 검사·후속 조치 보고서 |
| `QA-05-test-case-execution.md` | 테스트 케이스와 실행 기록 형식 |
| `QA-06-defect-regression-report.md` | 결함·회귀 위험·root cause 관리 기준 |
| `severity-policy.md` | S1~S4 severity 기준 |
| `regression-checklist.md` | 수정 후 회귀 검증 체크리스트 |
| `approval-audit-log-template.md` | 사람 승인, AI 산출물, 모델·prompt, secret masking 감사 기록 |

---

## 4. 상태 원칙

| 상태 | 의미 |
| --- | --- |
| PLANNED / NOT EXECUTED | 계획만 있고 실행 증거가 없음 |
| EXECUTED / PASS | 실행했고 기대 결과를 만족함 |
| EXECUTED / FAIL | 실행했고 결함 또는 불일치를 확인함 |
| BLOCKED | 실행 조건이 충족되지 않아 검증하지 못함 |
| APPROVED | 사람 승인자가 근거를 확인하고 승인함 |

재현 불가만으로 defect를 close하지 않는다. 수정 build, retest evidence, 승인자를 함께 기록해야 한다.
