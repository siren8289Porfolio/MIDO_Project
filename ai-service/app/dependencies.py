from functools import lru_cache

from app.services.llm_explainer import ExplanationService
from app.services.risk_analyzer import RiskAnalyzerService


@lru_cache
def get_risk_analyzer() -> RiskAnalyzerService:
    return RiskAnalyzerService()


@lru_cache
def get_explanation_service() -> ExplanationService:
    return ExplanationService()
