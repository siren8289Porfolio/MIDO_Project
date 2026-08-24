from __future__ import annotations

from app.schemas.risk import (
    AiConfidence,
    AiOutputStatus,
    AiRecommendation,
    ExplainRequest,
    ExplainResponse,
    RiskFinding,
)
from app.config import settings


def build_explanation(findings: list[RiskFinding], input_type: str | None = None) -> str:
    if not findings:
        return (
            "No confirmed vulnerability evidence was found from external sources. "
            "This does not prove the code is safe; it only means no known vulnerability "
            "was matched for the provided dependency coordinates."
        )

    context = f" for {input_type} input" if input_type else ""
    high_risk = [finding for finding in findings if finding.severity in {"CRITICAL", "HIGH"}]
    if high_risk:
        sample = high_risk[0]
        identifier = sample.cve_id or sample.ghsa_id or sample.finding_id
        return (
            f"MIDO detected {len(high_risk)} high-severity finding(s){context}. "
            f"Example: {identifier} affects {sample.package_name}@{sample.package_version}. "
            "Review the linked evidence and decide whether to FIX, USE with rationale, or IGNORE."
        )

    return (
        f"MIDO found {len(findings)} risk finding(s){context}. "
        "Severity is not critical, but reviewer confirmation is still required before USE."
    )


class ExplanationService:
    async def explain(self, request: ExplainRequest) -> ExplainResponse:
        explanation = build_explanation(request.risks, request.input_type)
        if request.code_summary:
            explanation = f"{explanation} Code context: {request.code_summary[:240]}"

        output_status = AiOutputStatus.SUPPORTED if request.risks else AiOutputStatus.INSUFFICIENT_EVIDENCE
        confidence = AiConfidence.HIGH if request.risks else AiConfidence.LOW
        recommendation = _resolve_recommendation(request.risks)

        return ExplainResponse(
            model_version=settings.model_version,
            prompt_version=settings.prompt_version,
            output_status=output_status,
            confidence=confidence,
            recommendation=recommendation,
            explanation=explanation,
        )


def _resolve_recommendation(findings: list[RiskFinding]) -> AiRecommendation:
    if any(finding.severity in {"CRITICAL", "HIGH"} for finding in findings):
        return AiRecommendation.FIX
    if findings:
        return AiRecommendation.REVIEW_REQUIRED
    return AiRecommendation.USE
