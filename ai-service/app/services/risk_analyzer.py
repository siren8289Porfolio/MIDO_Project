from __future__ import annotations

from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

import httpx

from app.config import settings
from app.schemas.risk import (
    AiConfidence,
    AiOutputStatus,
    AiRecommendation,
    DependencyCoordinate,
    EvidenceSource,
    EvidenceStatus,
    RiskAnalyzeRequest,
    RiskAnalyzeResponse,
    RiskFinding,
)
from app.services.dependency_extractor import extract_dependencies_from_code, merge_dependencies
from app.services.llm_explainer import build_explanation


class RiskAnalyzerService:
    def __init__(self) -> None:
        self._client = httpx.AsyncClient(timeout=settings.request_timeout_seconds)

    async def close(self) -> None:
        await self._client.aclose()

    async def analyze(self, request: RiskAnalyzeRequest) -> RiskAnalyzeResponse:
        dependencies = merge_dependencies(
            request.dependencies,
            extract_dependencies_from_code(request.code),
        )

        if not dependencies and not request.code:
            return RiskAnalyzeResponse(
                model_version=settings.model_version,
                prompt_version=settings.prompt_version,
                output_status=AiOutputStatus.INSUFFICIENT_EVIDENCE,
                confidence=AiConfidence.LOW,
                recommendation=AiRecommendation.REVIEW_REQUIRED,
                risks=[],
                explanation="No code or dependency coordinates were provided for analysis.",
            )

        findings: list[RiskFinding] = []
        provider_failures = 0

        for dependency in dependencies:
            dependency_findings, failed = await self._lookup_osv(dependency)
            findings.extend(dependency_findings)
            provider_failures += failed

        output_status = self._resolve_output_status(findings, provider_failures, len(dependencies))
        confidence = self._resolve_confidence(findings, output_status)
        recommendation = self._resolve_recommendation(findings, output_status)
        explanation = build_explanation(findings, request.input_type)

        return RiskAnalyzeResponse(
            model_version=settings.model_version,
            prompt_version=settings.prompt_version,
            output_status=output_status,
            confidence=confidence,
            recommendation=recommendation,
            risks=findings,
            explanation=explanation,
        )

    async def _lookup_osv(self, dependency: DependencyCoordinate) -> tuple[list[RiskFinding], int]:
        ecosystem = _map_ecosystem(dependency.ecosystem)
        payload = {
            "package": {
                "name": dependency.name,
                "ecosystem": ecosystem,
            },
            "version": dependency.version,
        }

        try:
            response = await self._client.post(f"{settings.osv_api_base_url}/query", json=payload)
            response.raise_for_status()
            body: dict[str, Any] = response.json()
        except httpx.HTTPError:
            return [
                RiskFinding(
                    finding_id=str(uuid4()),
                    risk_type="DEPENDENCY_EVIDENCE",
                    severity="UNKNOWN",
                    description=(
                        f"Could not retrieve vulnerability evidence for {dependency.name}@{dependency.version}."
                    ),
                    package_name=dependency.name,
                    package_version=dependency.version,
                    source=EvidenceSource.OSV,
                    evidence_status=EvidenceStatus.UNKNOWN,
                )
            ], 1

        vulns = body.get("vulns") or []
        if not vulns:
            return [], 0

        findings: list[RiskFinding] = []
        for vuln in vulns:
            cve_ids = [alias for alias in vuln.get("aliases", []) if alias.startswith("CVE-")]
            ghsa_ids = [alias for alias in vuln.get("aliases", []) if alias.startswith("GHSA-")]
            severity = _map_severity(vuln)
            findings.append(
                RiskFinding(
                    finding_id=vuln.get("id") or str(uuid4()),
                    risk_type="VULNERABILITY",
                    severity=severity,
                    description=vuln.get("summary") or vuln.get("details") or "Known vulnerability reported by OSV.",
                    cve_id=cve_ids[0] if cve_ids else None,
                    ghsa_id=ghsa_ids[0] if ghsa_ids else None,
                    package_name=dependency.name,
                    package_version=dependency.version,
                    source=EvidenceSource.OSV,
                    source_url=f"https://osv.dev/vulnerability/{vuln.get('id')}",
                    evidence_status=EvidenceStatus.CURRENT,
                )
            )
        return findings, 0

    def _resolve_output_status(
        self,
        findings: list[RiskFinding],
        provider_failures: int,
        dependency_count: int,
    ) -> AiOutputStatus:
        if provider_failures == dependency_count and dependency_count > 0:
            return AiOutputStatus.PROVIDER_FAILURE
        if provider_failures > 0:
            return AiOutputStatus.PARTIALLY_SUPPORTED
        if not findings:
            return AiOutputStatus.INSUFFICIENT_EVIDENCE
        if any(finding.evidence_status == EvidenceStatus.CONFLICT for finding in findings):
            return AiOutputStatus.CONFLICTING_EVIDENCE
        return AiOutputStatus.SUPPORTED

    def _resolve_confidence(self, findings: list[RiskFinding], output_status: AiOutputStatus) -> AiConfidence:
        if output_status in {AiOutputStatus.PROVIDER_FAILURE, AiOutputStatus.INSUFFICIENT_EVIDENCE}:
            return AiConfidence.LOW
        if output_status == AiOutputStatus.PARTIALLY_SUPPORTED:
            return AiConfidence.MEDIUM
        if any(finding.severity in {"CRITICAL", "HIGH"} for finding in findings):
            return AiConfidence.HIGH
        return AiConfidence.MEDIUM

    def _resolve_recommendation(
        self,
        findings: list[RiskFinding],
        output_status: AiOutputStatus,
    ) -> AiRecommendation:
        if output_status in {AiOutputStatus.PROVIDER_FAILURE, AiOutputStatus.INSUFFICIENT_EVIDENCE}:
            return AiRecommendation.REVIEW_REQUIRED
        if any(finding.severity in {"CRITICAL", "HIGH"} for finding in findings):
            return AiRecommendation.FIX
        if findings:
            return AiRecommendation.REVIEW_REQUIRED
        return AiRecommendation.USE


def _map_ecosystem(ecosystem: str) -> str:
    normalized = ecosystem.strip().lower()
    if normalized in {"maven", "gradle"}:
        return "Maven"
    if normalized == "npm":
        return "npm"
    if normalized == "pypi":
        return "PyPI"
    return ecosystem


def _map_severity(vuln: dict[str, Any]) -> str:
    database_specific = vuln.get("database_specific") or {}
    severity = database_specific.get("severity")
    if isinstance(severity, str) and severity:
        return severity.upper()
    for item in vuln.get("severity") or []:
        score = item.get("score")
        if isinstance(score, str) and score.startswith("CVSS:"):
            numeric = _extract_cvss_numeric(score)
            if numeric is not None:
                if numeric >= 9.0:
                    return "CRITICAL"
                if numeric >= 7.0:
                    return "HIGH"
                if numeric >= 4.0:
                    return "MEDIUM"
                return "LOW"
    modified = vuln.get("modified")
    if modified:
        modified_at = datetime.fromisoformat(modified.replace("Z", "+00:00"))
        age_days = (datetime.now(timezone.utc) - modified_at).days
        if age_days > 365:
            return "MEDIUM"
    return "UNKNOWN"


def _extract_cvss_numeric(score: str) -> float | None:
    parts = score.split("/")
    for part in parts:
        if part.startswith("CVSS:"):
            continue
        try:
            return float(part)
        except ValueError:
            continue
    return None
