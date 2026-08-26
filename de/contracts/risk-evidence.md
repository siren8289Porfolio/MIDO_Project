# DE Risk Evidence Contract

파서 이후 AI 리스크 분석이 쓰는 증거·권고 enum 계약이다.
실행 타입은 `spring/src/main/verification/de/risk/` 에 있다.

## Enums

| Type | Values (요약) | 용도 |
| --- | --- | --- |
| `EvidenceSource` | OSV, NVD, GHSA, … | 취약점 출처 |
| `EvidenceStatus` | FOUND / NOT_FOUND / ERROR … | 증거 수집 상태 |
| `AiConfidence` | HIGH / MEDIUM / LOW | AI 확신도 |
| `AiOutputStatus` | OK / DEGRADED / FAILED … | AI 응답 상태 |
| `AiRecommendation` | USE / FIX / IGNORE | 최종 권고 |

## DB 매핑

- `db/migration/V6__vulnerability_risk_evidence.sql`
- `db/migration/V7__ai_risk_evidence_contract.sql`
