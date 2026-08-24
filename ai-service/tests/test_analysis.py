import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from app.schemas.risk import DependencyCoordinate, RiskAnalyzeRequest
from app.services.dependency_extractor import extract_dependencies_from_code, merge_dependencies
from app.services.llm_explainer import build_explanation


@pytest.mark.asyncio
async def test_health_endpoint():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_extract_npm_dependencies():
    code = """
    {
      "dependencies": {
        "lodash": "^4.17.21"
      }
    }
    """
    coordinates = extract_dependencies_from_code(code)
    assert len(coordinates) == 1
    assert coordinates[0].name == "lodash"
    assert coordinates[0].ecosystem == "npm"


def test_merge_dependencies_deduplicates():
    explicit = [DependencyCoordinate(ecosystem="npm", name="lodash", version="4.17.21")]
    from_code = [DependencyCoordinate(ecosystem="npm", name="lodash", version="4.17.21")]
    merged = merge_dependencies(explicit, from_code)
    assert len(merged) == 1


def test_build_explanation_without_findings():
    explanation = build_explanation([])
    assert "does not prove the code is safe" in explanation


@pytest.mark.asyncio
async def test_analyze_without_input_returns_insufficient_evidence():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post("/api/v1/risk/analyze", json={})
    assert response.status_code == 200
    body = response.json()
    assert body["outputStatus"] == "INSUFFICIENT_EVIDENCE"
    assert body["risks"] == []


@pytest.mark.asyncio
async def test_explain_endpoint():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/risk/explain",
            json={"inputType": "PASTE", "risks": []},
        )
    assert response.status_code == 200
    assert "explanation" in response.json()
