from __future__ import annotations

from enum import Enum
from uuid import UUID, uuid4

from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel


class AiOutputStatus(str, Enum):
    SUPPORTED = "SUPPORTED"
    PARTIALLY_SUPPORTED = "PARTIALLY_SUPPORTED"
    INSUFFICIENT_EVIDENCE = "INSUFFICIENT_EVIDENCE"
    CONFLICTING_EVIDENCE = "CONFLICTING_EVIDENCE"
    PROVIDER_FAILURE = "PROVIDER_FAILURE"


class AiConfidence(str, Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"


class AiRecommendation(str, Enum):
    USE = "USE"
    FIX = "FIX"
    IGNORE = "IGNORE"
    REVIEW_REQUIRED = "REVIEW_REQUIRED"


class EvidenceStatus(str, Enum):
    CURRENT = "CURRENT"
    STALE = "STALE"
    PARTIAL = "PARTIAL"
    CONFLICT = "CONFLICT"
    UNKNOWN = "UNKNOWN"


class EvidenceSource(str, Enum):
    OSV = "OSV"
    NVD = "NVD"
    GITHUB_ADVISORY = "GITHUB_ADVISORY"
    CISA_KEV = "CISA_KEV"
    MITRE_CWE = "MITRE_CWE"
    OWASP = "OWASP"


class _CamelModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class DependencyCoordinate(_CamelModel):
    ecosystem: str
    name: str
    version: str


class RiskAnalyzeRequest(_CamelModel):
    verification_id: UUID | None = None
    code: str | None = None
    dependencies: list[DependencyCoordinate] = Field(default_factory=list)
    input_type: str | None = None
    repo_url: str | None = None


class RiskFinding(_CamelModel):
    finding_id: str
    risk_type: str = "VULNERABILITY"
    severity: str
    description: str
    cve_id: str | None = None
    cwe_id: str | None = None
    ghsa_id: str | None = None
    package_name: str | None = None
    package_version: str | None = None
    cvss_score: float | None = None
    kev_known_exploited: bool = False
    source: EvidenceSource
    source_url: str | None = None
    evidence_status: EvidenceStatus = EvidenceStatus.UNKNOWN


class RiskAnalyzeResponse(_CamelModel):
    analysis_run_id: UUID = Field(default_factory=uuid4)
    model_version: str
    prompt_version: str
    output_status: AiOutputStatus
    confidence: AiConfidence
    recommendation: AiRecommendation
    risks: list[RiskFinding] = Field(default_factory=list)
    explanation: str | None = None


class ExplainRequest(_CamelModel):
    verification_id: UUID | None = None
    risks: list[RiskFinding] = Field(default_factory=list)
    code_summary: str | None = None
    input_type: str | None = None


class ExplainResponse(_CamelModel):
    analysis_run_id: UUID = Field(default_factory=uuid4)
    model_version: str
    prompt_version: str
    output_status: AiOutputStatus
    confidence: AiConfidence
    recommendation: AiRecommendation
    explanation: str
