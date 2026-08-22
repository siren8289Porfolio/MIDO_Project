ALTER TABLE vulnerability_source
    DROP CONSTRAINT IF EXISTS chk_vulnerability_source_value;

ALTER TABLE vulnerability_source
    ADD CONSTRAINT chk_vulnerability_source_value
    CHECK (source IN ('OSV', 'NVD', 'GITHUB_ADVISORY', 'CISA_KEV', 'MITRE_CWE', 'OWASP'));

ALTER TABLE risk_evidence
    DROP CONSTRAINT IF EXISTS chk_risk_evidence_source;

ALTER TABLE risk_evidence
    ADD CONSTRAINT chk_risk_evidence_source
    CHECK (source IN ('OSV', 'NVD', 'GITHUB_ADVISORY', 'CISA_KEV', 'MITRE_CWE', 'OWASP'));

ALTER TABLE risk_evidence ADD COLUMN IF NOT EXISTS source_record_id VARCHAR(128);
ALTER TABLE risk_evidence ADD COLUMN IF NOT EXISTS canonical_vulnerability_id VARCHAR(128);
ALTER TABLE risk_evidence ADD COLUMN IF NOT EXISTS ecosystem VARCHAR(64);
ALTER TABLE risk_evidence ADD COLUMN IF NOT EXISTS affected_version_range TEXT;
ALTER TABLE risk_evidence ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ;
ALTER TABLE risk_evidence ADD COLUMN IF NOT EXISTS source_modified_at TIMESTAMPTZ;
ALTER TABLE risk_evidence ADD COLUMN IF NOT EXISTS source_snapshot_version VARCHAR(128);
ALTER TABLE risk_evidence ADD COLUMN IF NOT EXISTS evidence_status VARCHAR(32) NOT NULL DEFAULT 'UNKNOWN';

UPDATE risk_evidence
SET source_record_id = external_id
WHERE source_record_id IS NULL;

UPDATE risk_evidence
SET canonical_vulnerability_id = COALESCE(cve_id, ghsa_id, external_id)
WHERE canonical_vulnerability_id IS NULL;

UPDATE risk_evidence
SET ecosystem = package_ecosystem
WHERE ecosystem IS NULL;

UPDATE risk_evidence
SET source_modified_at = source_updated_at
WHERE source_modified_at IS NULL;

UPDATE risk_evidence
SET evidence_status = 'UNKNOWN'
WHERE evidence_status IS NULL;

ALTER TABLE risk_evidence
    ALTER COLUMN evidence_status SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_risk_evidence_status'
    ) THEN
        ALTER TABLE risk_evidence
            ADD CONSTRAINT chk_risk_evidence_status
            CHECK (evidence_status IN ('CURRENT', 'STALE', 'PARTIAL', 'CONFLICT', 'UNKNOWN'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_risk_evidence_source_modified_time'
    ) THEN
        ALTER TABLE risk_evidence
            ADD CONSTRAINT chk_risk_evidence_source_modified_time
            CHECK (source_modified_at IS NULL OR published_at IS NULL OR published_at <= source_modified_at);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_risk_evidence_fetched_time'
    ) THEN
        ALTER TABLE risk_evidence
            ADD CONSTRAINT chk_risk_evidence_fetched_time
            CHECK (source_modified_at IS NULL OR source_modified_at <= fetched_at + INTERVAL '5 minutes');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_risk_evidence_canonical_id'
    ) THEN
        ALTER TABLE risk_evidence
            ADD CONSTRAINT chk_risk_evidence_canonical_id
            CHECK (
                canonical_vulnerability_id IS NULL
                OR canonical_vulnerability_id ~ '^(CVE-[0-9]{4}-[0-9]{4,}|GHSA-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}|OSV-.+|CWE-[0-9]+|OWASP-.+|[A-Za-z0-9._:-]+)$'
            );
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_risk_evidence_canonical
    ON risk_evidence(canonical_vulnerability_id)
    WHERE canonical_vulnerability_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_risk_evidence_status
    ON risk_evidence(evidence_status, fetched_at DESC);

DROP VIEW IF EXISTS mart_vulnerability_exposure;
DROP VIEW IF EXISTS int_risk_evidence_enrichment;
DROP VIEW IF EXISTS stg_risk_evidence;

CREATE OR REPLACE VIEW stg_risk_evidence AS
SELECT
    id AS risk_evidence_id,
    risk_assessment_id,
    dependency_package_id,
    source,
    external_id,
    source_record_id,
    canonical_vulnerability_id,
    cve_id,
    ghsa_id,
    cwe_id,
    COALESCE(ecosystem, package_ecosystem) AS ecosystem,
    package_name,
    package_ecosystem,
    package_version,
    affected_version_range,
    fixed_version,
    severity,
    cvss_score,
    known_exploited,
    source_url,
    published_at,
    COALESCE(source_modified_at, source_updated_at) AS source_modified_at,
    source_updated_at,
    fetched_at,
    source_snapshot_version,
    evidence_status,
    source_system,
    schema_version,
    created_at,
    updated_at
FROM risk_evidence;

CREATE OR REPLACE VIEW int_risk_evidence_enrichment AS
SELECT
    r.risk_assessment_id,
    ra.verification_data_id AS verification_id,
    r.package_name,
    r.ecosystem,
    r.package_version,
    COALESCE(r.canonical_vulnerability_id, r.cve_id, r.ghsa_id, r.external_id) AS vulnerability_id,
    bool_or(r.source = 'OSV') AS has_osv_evidence,
    bool_or(r.source = 'NVD') AS has_nvd_evidence,
    bool_or(r.source = 'GITHUB_ADVISORY') AS has_github_advisory_evidence,
    bool_or(r.source = 'CISA_KEV') AS has_cisa_kev_evidence,
    bool_or(r.source = 'MITRE_CWE') AS has_mitre_cwe_evidence,
    bool_or(r.source = 'OWASP') AS has_owasp_evidence,
    bool_or(r.known_exploited) AS known_exploited,
    bool_or(r.evidence_status = 'STALE') AS has_stale_evidence,
    bool_or(r.evidence_status = 'CONFLICT') AS has_conflicting_evidence,
    bool_or(r.evidence_status = 'PARTIAL') AS has_partial_evidence,
    max(r.cvss_score) AS max_cvss_score,
    max(r.source_modified_at) AS latest_source_modified_at,
    max(r.fetched_at) AS latest_fetched_at
FROM stg_risk_evidence r
JOIN risk_assessment ra ON ra.id = r.risk_assessment_id
GROUP BY
    r.risk_assessment_id,
    ra.verification_data_id,
    r.package_name,
    r.ecosystem,
    r.package_version,
    COALESCE(r.canonical_vulnerability_id, r.cve_id, r.ghsa_id, r.external_id);

CREATE OR REPLACE VIEW mart_vulnerability_exposure AS
SELECT
    date_trunc('day', v.created_at)::date AS metric_date,
    v.input_type,
    e.ecosystem,
    e.package_name,
    e.package_version,
    count(DISTINCT v.id) AS affected_verification_count,
    count(DISTINCT e.vulnerability_id) AS vulnerability_count,
    count(DISTINCT e.vulnerability_id) FILTER (WHERE e.known_exploited) AS known_exploited_count,
    count(DISTINCT e.vulnerability_id) FILTER (WHERE e.has_stale_evidence) AS stale_evidence_count,
    count(DISTINCT e.vulnerability_id) FILTER (WHERE e.has_conflicting_evidence) AS conflicting_evidence_count,
    count(DISTINCT e.vulnerability_id) FILTER (WHERE e.has_partial_evidence) AS partial_evidence_count,
    max(e.max_cvss_score) AS max_cvss_score,
    bool_or(e.has_osv_evidence) AS has_osv_evidence,
    bool_or(e.has_nvd_evidence) AS has_nvd_evidence,
    bool_or(e.has_github_advisory_evidence) AS has_github_advisory_evidence,
    bool_or(e.has_cisa_kev_evidence) AS has_cisa_kev_evidence,
    bool_or(e.has_mitre_cwe_evidence) AS has_mitre_cwe_evidence,
    bool_or(e.has_owasp_evidence) AS has_owasp_evidence
FROM int_risk_evidence_enrichment e
JOIN verification_data v ON v.id = e.verification_id
GROUP BY
    date_trunc('day', v.created_at)::date,
    v.input_type,
    e.ecosystem,
    e.package_name,
    e.package_version;

CREATE TABLE IF NOT EXISTS ai_risk_change_log (
    change_id UUID PRIMARY KEY,
    component VARCHAR(64) NOT NULL,
    previous_version VARCHAR(128),
    new_version VARCHAR(128) NOT NULL,
    changed_by VARCHAR(128) NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    reason TEXT NOT NULL,
    evaluation_run_id UUID,
    release_status VARCHAR(32) NOT NULL DEFAULT 'PLANNED',
    CONSTRAINT chk_ai_risk_change_component
        CHECK (component IN ('MODEL', 'PROMPT', 'SYSTEM_INSTRUCTION', 'RETRIEVAL_LOGIC', 'RISK_RULE', 'SOURCE_SCHEMA', 'EVIDENCE_MAPPER', 'TOOL_PERMISSION', 'EVALUATION_DATASET', 'THRESHOLD')),
    CONSTRAINT chk_ai_risk_change_release_status
        CHECK (release_status IN ('PLANNED', 'EVALUATING', 'APPROVED', 'REJECTED', 'RELEASED', 'ROLLED_BACK'))
);

CREATE TABLE IF NOT EXISTS ai_evaluation_run (
    evaluation_run_id UUID PRIMARY KEY,
    evaluation_set_version VARCHAR(128) NOT NULL,
    target_component VARCHAR(64) NOT NULL,
    target_version VARCHAR(128) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'NOT_RUN',
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    retrieval_hit_rate NUMERIC(5,4),
    unsupported_claim_rate NUMERIC(5,4),
    citation_correctness NUMERIC(5,4),
    known_vulnerable_detection NUMERIC(5,4),
    patched_version_rejection NUMERIC(5,4),
    kev_match_accuracy NUMERIC(5,4),
    p95_latency_ms BIGINT,
    failure_rate NUMERIC(5,4),
    evidence_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_ai_evaluation_status
        CHECK (status IN ('NOT_RUN', 'RUNNING', 'PASSED', 'FAILED', 'BLOCKED')),
    CONSTRAINT chk_ai_evaluation_time_order
        CHECK (started_at IS NULL OR ended_at IS NULL OR started_at <= ended_at)
);

CREATE TABLE IF NOT EXISTS ai_tool_permission_policy (
    permission_name VARCHAR(64) PRIMARY KEY,
    permission_group VARCHAR(64) NOT NULL,
    allowed BOOLEAN NOT NULL DEFAULT false,
    requires_human_approval BOOLEAN NOT NULL DEFAULT true,
    rationale TEXT NOT NULL,
    source_status VARCHAR(32) NOT NULL DEFAULT 'PLANNED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_ai_tool_permission_status
        CHECK (source_status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_ai_tool_permission_timestamp_order CHECK (created_at <= updated_at)
);

INSERT INTO vulnerability_source (
    source,
    display_name,
    base_url,
    auth_mode,
    api_key_env_name,
    request_strategy,
    primary_use,
    rate_limit_policy,
    refresh_policy,
    source_status
)
VALUES
    ('MITRE_CWE', 'MITRE Common Weakness Enumeration', 'https://cwe.mitre.org', 'NONE', NULL, 'ENRICHMENT', 'CWE weakness taxonomy enrichment only; not vulnerability instance discovery', 'No MIDO request-path dependency', 'Periodic taxonomy snapshot or source URL reference', 'PLANNED'),
    ('OWASP', 'OWASP Security Taxonomy', 'https://owasp.org', 'NONE', NULL, 'ENRICHMENT', 'Application and GenAI security taxonomy enrichment only', 'No MIDO request-path dependency', 'Periodic taxonomy snapshot or source URL reference', 'PLANNED')
ON CONFLICT (source) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    base_url = EXCLUDED.base_url,
    auth_mode = EXCLUDED.auth_mode,
    api_key_env_name = EXCLUDED.api_key_env_name,
    request_strategy = EXCLUDED.request_strategy,
    primary_use = EXCLUDED.primary_use,
    rate_limit_policy = EXCLUDED.rate_limit_policy,
    refresh_policy = EXCLUDED.refresh_policy,
    source_status = EXCLUDED.source_status,
    updated_at = now();

INSERT INTO ai_tool_permission_policy (
    permission_name,
    permission_group,
    allowed,
    requires_human_approval,
    rationale,
    source_status
)
VALUES
    ('OSV_READ', 'READ_ONLY_EVIDENCE', true, false, 'OSV is used for package/version vulnerability discovery', 'PLANNED'),
    ('NVD_READ', 'READ_ONLY_EVIDENCE', true, false, 'NVD is used for CVE enrichment', 'PLANNED'),
    ('GITHUB_ADVISORY_READ', 'READ_ONLY_EVIDENCE', true, false, 'GitHub Advisory is used for GHSA and affected version enrichment', 'PLANNED'),
    ('KEV_READ', 'READ_ONLY_EVIDENCE', true, false, 'CISA KEV is used for known exploited signal enrichment', 'PLANNED'),
    ('CWE_READ', 'READ_ONLY_TAXONOMY', true, false, 'MITRE CWE is used as weakness taxonomy', 'PLANNED'),
    ('PROJECT_CONTEXT_READ', 'READ_ONLY_CONTEXT', true, false, 'Project context can ground reviewer-facing explanation', 'PLANNED'),
    ('SOURCE_CODE_WRITE', 'WRITE_OPERATION', false, true, 'AI must not modify source code directly', 'PLANNED'),
    ('GIT_COMMIT', 'WRITE_OPERATION', false, true, 'AI must not create commits as an autonomous risk action', 'PLANNED'),
    ('GIT_PUSH', 'WRITE_OPERATION', false, true, 'AI must not push code as an autonomous risk action', 'PLANNED'),
    ('DEPENDENCY_UPDATE', 'WRITE_OPERATION', false, true, 'AI may propose dependency updates but cannot apply them automatically', 'PLANNED'),
    ('DB_MUTATION', 'WRITE_OPERATION', false, true, 'AI evidence tools start read-only; mutations require separate approved execution layer', 'PLANNED'),
    ('DEPLOY', 'RELEASE_OPERATION', false, true, 'AI must not deploy or release automatically', 'PLANNED'),
    ('DECISION_APPROVE', 'DECISION_OPERATION', false, true, 'Reviewer action is required for USE/FIX/IGNORE', 'PLANNED')
ON CONFLICT (permission_name) DO UPDATE SET
    permission_group = EXCLUDED.permission_group,
    allowed = EXCLUDED.allowed,
    requires_human_approval = EXCLUDED.requires_human_approval,
    rationale = EXCLUDED.rationale,
    source_status = EXCLUDED.source_status,
    updated_at = now();

INSERT INTO data_quality_rule (rule_id, rule_name, layer_name, severity, zero_tolerance, owner)
VALUES
    ('DQ-307', 'risk_evidence canonical vulnerability identity present when evidence exists', 'SOURCE_OLTP', 'P1', false, 'AI'),
    ('DQ-308', 'risk_evidence freshness timestamps present', 'SOURCE_OLTP', 'P1', false, 'AI'),
    ('DQ-309', 'risk_evidence distinguishes no known vulnerability from insufficient evidence', 'CORE_MART', 'P0', true, 'AI')
ON CONFLICT (rule_id) DO UPDATE SET
    rule_name = EXCLUDED.rule_name,
    layer_name = EXCLUDED.layer_name,
    severity = EXCLUDED.severity,
    zero_tolerance = EXCLUDED.zero_tolerance,
    owner = EXCLUDED.owner,
    updated_at = now();
