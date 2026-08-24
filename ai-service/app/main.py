from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.config import settings
from app.routers import analysis, health
from app.services.risk_analyzer import RiskAnalyzerService


@asynccontextmanager
async def lifespan(app: FastAPI):
    analyzer = RiskAnalyzerService()
    app.state.risk_analyzer = analyzer
    yield
    await analyzer.close()


app = FastAPI(title=settings.app_name, lifespan=lifespan)
app.include_router(health.router)
app.include_router(analysis.router)
