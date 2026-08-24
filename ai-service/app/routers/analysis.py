from fastapi import APIRouter, Depends

from app.dependencies import get_explanation_service, get_risk_analyzer
from app.schemas.risk import ExplainRequest, ExplainResponse, RiskAnalyzeRequest, RiskAnalyzeResponse
from app.services.llm_explainer import ExplanationService
from app.services.risk_analyzer import RiskAnalyzerService

router = APIRouter(prefix="/api/v1/risk", tags=["risk"])


@router.post("/analyze", response_model=RiskAnalyzeResponse)
async def analyze_risk(
    request_body: RiskAnalyzeRequest,
    analyzer: RiskAnalyzerService = Depends(get_risk_analyzer),
) -> RiskAnalyzeResponse:
    return await analyzer.analyze(request_body)


@router.post("/explain", response_model=ExplainResponse)
async def explain_risk(
    request_body: ExplainRequest,
    explainer: ExplanationService = Depends(get_explanation_service),
) -> ExplainResponse:
    return await explainer.explain(request_body)
