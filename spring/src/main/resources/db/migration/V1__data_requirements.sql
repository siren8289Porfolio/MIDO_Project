CREATE TABLE IF NOT EXISTS verification_data (
    id UUID PRIMARY KEY,
    input_type VARCHAR(20) NOT NULL,
    repo_url TEXT,
    commit_hash VARCHAR(128),
    pr_number INTEGER,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    code TEXT,
    source_system VARCHAR(64) NOT NULL DEFAULT 'MIDO',
    schema_version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS manual_input (
    id UUID PRIMARY KEY,
    verification_data_id UUID NOT NULL REFERENCES verification_data(id),
    input_method VARCHAR(50) NOT NULL,
    raw_input TEXT,
    source_system VARCHAR(64) NOT NULL DEFAULT 'MIDO',
    schema_version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS uploaded_file (
    id UUID PRIMARY KEY,
    verification_data_id UUID NOT NULL REFERENCES verification_data(id),
    file_name TEXT,
    file_type VARCHAR(255),
    file_size_bytes BIGINT,
    mime_type VARCHAR(255),
    checksum_sha256 CHAR(64),
    file_content TEXT,
    source_system VARCHAR(64) NOT NULL DEFAULT 'MIDO',
    schema_version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS work_context (
    id UUID PRIMARY KEY,
    verification_data_id UUID NOT NULL UNIQUE REFERENCES verification_data(id),
    display_repo_url TEXT,
    display_commit_hash VARCHAR(128),
    display_pr_number INTEGER,
    source_system VARCHAR(64) NOT NULL DEFAULT 'MIDO',
    schema_version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE verification_data ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'DRAFT';
ALTER TABLE verification_data ADD COLUMN IF NOT EXISTS source_system VARCHAR(64) NOT NULL DEFAULT 'MIDO';
ALTER TABLE verification_data ADD COLUMN IF NOT EXISTS schema_version INTEGER NOT NULL DEFAULT 1;
ALTER TABLE verification_data ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE verification_data ALTER COLUMN updated_at SET DEFAULT now();
UPDATE verification_data SET status = 'DRAFT' WHERE status IS NULL;
UPDATE verification_data SET source_system = 'MIDO' WHERE source_system IS NULL;
UPDATE verification_data SET schema_version = 1 WHERE schema_version IS NULL;
ALTER TABLE verification_data ALTER COLUMN status SET NOT NULL;
ALTER TABLE verification_data ALTER COLUMN source_system SET NOT NULL;
ALTER TABLE verification_data ALTER COLUMN schema_version SET NOT NULL;

ALTER TABLE manual_input ADD COLUMN IF NOT EXISTS source_system VARCHAR(64) NOT NULL DEFAULT 'MIDO';
ALTER TABLE manual_input ADD COLUMN IF NOT EXISTS schema_version INTEGER NOT NULL DEFAULT 1;
ALTER TABLE manual_input ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE manual_input ALTER COLUMN created_at SET DEFAULT now();
UPDATE manual_input SET source_system = 'MIDO' WHERE source_system IS NULL;
UPDATE manual_input SET schema_version = 1 WHERE schema_version IS NULL;
UPDATE manual_input SET updated_at = COALESCE(created_at, now()) WHERE updated_at IS NULL;
ALTER TABLE manual_input ALTER COLUMN source_system SET NOT NULL;
ALTER TABLE manual_input ALTER COLUMN schema_version SET NOT NULL;
ALTER TABLE manual_input ALTER COLUMN updated_at SET NOT NULL;

ALTER TABLE uploaded_file ADD COLUMN IF NOT EXISTS file_size_bytes BIGINT;
ALTER TABLE uploaded_file ADD COLUMN IF NOT EXISTS mime_type VARCHAR(255);
ALTER TABLE uploaded_file ADD COLUMN IF NOT EXISTS checksum_sha256 CHAR(64);
ALTER TABLE uploaded_file ADD COLUMN IF NOT EXISTS source_system VARCHAR(64) NOT NULL DEFAULT 'MIDO';
ALTER TABLE uploaded_file ADD COLUMN IF NOT EXISTS schema_version INTEGER NOT NULL DEFAULT 1;
ALTER TABLE uploaded_file ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE uploaded_file ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE uploaded_file ALTER COLUMN uploaded_at SET DEFAULT now();
UPDATE uploaded_file SET source_system = 'MIDO' WHERE source_system IS NULL;
UPDATE uploaded_file SET schema_version = 1 WHERE schema_version IS NULL;
UPDATE uploaded_file SET created_at = COALESCE(uploaded_at, now()) WHERE created_at IS NULL;
UPDATE uploaded_file SET updated_at = COALESCE(uploaded_at, created_at, now()) WHERE updated_at IS NULL;
ALTER TABLE uploaded_file ALTER COLUMN source_system SET NOT NULL;
ALTER TABLE uploaded_file ALTER COLUMN schema_version SET NOT NULL;
ALTER TABLE uploaded_file ALTER COLUMN created_at SET NOT NULL;
ALTER TABLE uploaded_file ALTER COLUMN updated_at SET NOT NULL;

ALTER TABLE work_context ADD COLUMN IF NOT EXISTS source_system VARCHAR(64) NOT NULL DEFAULT 'MIDO';
ALTER TABLE work_context ADD COLUMN IF NOT EXISTS schema_version INTEGER NOT NULL DEFAULT 1;
ALTER TABLE work_context ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE work_context ALTER COLUMN created_at SET DEFAULT now();
UPDATE work_context SET source_system = 'MIDO' WHERE source_system IS NULL;
UPDATE work_context SET schema_version = 1 WHERE schema_version IS NULL;
UPDATE work_context SET updated_at = COALESCE(created_at, now()) WHERE updated_at IS NULL;
ALTER TABLE work_context ALTER COLUMN source_system SET NOT NULL;
ALTER TABLE work_context ALTER COLUMN schema_version SET NOT NULL;
ALTER TABLE work_context ALTER COLUMN updated_at SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_verification_status'
    ) THEN
        ALTER TABLE verification_data
            ADD CONSTRAINT chk_verification_status
            CHECK (status IN ('DRAFT', 'READY', 'RUNNING', 'DONE', 'FAILED'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_verification_input_type'
    ) THEN
        ALTER TABLE verification_data
            ADD CONSTRAINT chk_verification_input_type
            CHECK (input_type IN ('PASTE', 'FILE', 'COMMIT', 'PR'));
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_verification_timestamp_order'
    ) THEN
        ALTER TABLE verification_data
            ADD CONSTRAINT chk_verification_timestamp_order
            CHECK (created_at <= updated_at);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_manual_input_timestamp_order'
    ) THEN
        ALTER TABLE manual_input
            ADD CONSTRAINT chk_manual_input_timestamp_order
            CHECK (created_at <= updated_at);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_uploaded_file_timestamp_order'
    ) THEN
        ALTER TABLE uploaded_file
            ADD CONSTRAINT chk_uploaded_file_timestamp_order
            CHECK (created_at <= updated_at AND created_at <= uploaded_at);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_uploaded_file_size'
    ) THEN
        ALTER TABLE uploaded_file
            ADD CONSTRAINT chk_uploaded_file_size
            CHECK (file_size_bytes IS NULL OR file_size_bytes >= 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_uploaded_file_checksum_sha256'
    ) THEN
        ALTER TABLE uploaded_file
            ADD CONSTRAINT chk_uploaded_file_checksum_sha256
            CHECK (checksum_sha256 IS NULL OR checksum_sha256 ~ '^[0-9a-f]{64}$');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_work_context_timestamp_order'
    ) THEN
        ALTER TABLE work_context
            ADD CONSTRAINT chk_work_context_timestamp_order
            CHECK (created_at <= updated_at);
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS data_event (
    event_id UUID PRIMARY KEY,
    event_name VARCHAR(100) NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    producer VARCHAR(100) NOT NULL,
    schema_version INTEGER NOT NULL,
    verification_id UUID NOT NULL REFERENCES verification_data(id),
    actor_id_hash VARCHAR(128),
    team_id VARCHAR(128),
    project_id VARCHAR(128),
    correlation_id VARCHAR(128),
    idempotency_key VARCHAR(128) NOT NULL,
    source_lsn VARCHAR(128),
    batch_id VARCHAR(128),
    loaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT uq_data_event_idempotency UNIQUE (producer, idempotency_key),
    CONSTRAINT chk_data_event_time_order CHECK (occurred_at <= received_at + INTERVAL '5 minutes'),
    CONSTRAINT chk_data_event_no_code_payload CHECK (
        NOT (metadata ? 'raw_code')
        AND NOT (metadata ? 'code_content')
        AND NOT (metadata ? 'access_token')
        AND NOT (metadata ? 'credential')
    )
);

CREATE TABLE IF NOT EXISTS verification_status_transition (
    event_id UUID PRIMARY KEY,
    verification_data_id UUID NOT NULL REFERENCES verification_data(id),
    from_status VARCHAR(20),
    to_status VARCHAR(20) NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL,
    actor_id_hash VARCHAR(128),
    reason TEXT,
    source_system VARCHAR(64) NOT NULL DEFAULT 'MIDO',
    schema_version INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT chk_status_transition_values CHECK (
        (from_status IS NULL OR from_status IN ('DRAFT', 'READY', 'RUNNING', 'DONE', 'FAILED'))
        AND to_status IN ('DRAFT', 'READY', 'RUNNING', 'DONE', 'FAILED')
    ),
    CONSTRAINT chk_status_transition_allowed CHECK (
        (from_status IS NULL AND to_status = 'DRAFT')
        OR (from_status = 'DRAFT' AND to_status IN ('READY', 'FAILED'))
        OR (from_status = 'READY' AND to_status IN ('RUNNING', 'FAILED'))
        OR (from_status = 'RUNNING' AND to_status IN ('DONE', 'FAILED'))
        OR (from_status = 'FAILED' AND to_status IN ('READY', 'RUNNING'))
        OR (from_status = to_status)
    )
);

CREATE TABLE IF NOT EXISTS risk_assessment (
    id UUID PRIMARY KEY,
    verification_data_id UUID NOT NULL REFERENCES verification_data(id),
    analysis_run_id UUID NOT NULL,
    finding_id VARCHAR(128) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    finding TEXT NOT NULL,
    evidence TEXT,
    model_version VARCHAR(128),
    prompt_version VARCHAR(128),
    status VARCHAR(20) NOT NULL DEFAULT 'PLANNED',
    source_system VARCHAR(64) NOT NULL DEFAULT 'MIDO',
    schema_version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_risk_finding UNIQUE (analysis_run_id, finding_id),
    CONSTRAINT chk_risk_status CHECK (status IN ('PLANNED', 'RUNNING', 'DONE', 'FAILED')),
    CONSTRAINT chk_risk_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS decision_log (
    id UUID PRIMARY KEY,
    verification_data_id UUID NOT NULL UNIQUE REFERENCES verification_data(id),
    decision VARCHAR(20) NOT NULL,
    rationale TEXT NOT NULL,
    actor_id_hash VARCHAR(128) NOT NULL,
    source_system VARCHAR(64) NOT NULL DEFAULT 'MIDO',
    schema_version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_decision_value CHECK (decision IN ('USE', 'FIX', 'IGNORE'))
);

CREATE TABLE IF NOT EXISTS team_guideline (
    id UUID PRIMARY KEY,
    team_id VARCHAR(128) NOT NULL,
    version INTEGER NOT NULL,
    scope VARCHAR(255) NOT NULL,
    guideline_ref TEXT NOT NULL,
    effective_from TIMESTAMPTZ NOT NULL,
    effective_to TIMESTAMPTZ,
    approved_by_hash VARCHAR(128),
    source_system VARCHAR(64) NOT NULL DEFAULT 'MIDO',
    schema_version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_team_guideline_version UNIQUE (team_id, scope, version),
    CONSTRAINT chk_guideline_effective_period CHECK (effective_to IS NULL OR effective_from < effective_to),
    CONSTRAINT chk_guideline_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS approval (
    id UUID PRIMARY KEY,
    decision_log_id UUID NOT NULL UNIQUE REFERENCES decision_log(id),
    reviewer_id_hash VARCHAR(128) NOT NULL,
    action VARCHAR(20) NOT NULL,
    reason TEXT,
    approved_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    source_system VARCHAR(64) NOT NULL DEFAULT 'MIDO',
    schema_version INTEGER NOT NULL DEFAULT 1,
    CONSTRAINT chk_approval_action CHECK (action IN ('APPROVED', 'REJECTED', 'REQUEST_CHANGES'))
);

CREATE TABLE IF NOT EXISTS git_metadata (
    id UUID PRIMARY KEY,
    verification_data_id UUID NOT NULL UNIQUE REFERENCES verification_data(id),
    repository TEXT NOT NULL,
    commit_sha VARCHAR(64),
    pr_number INTEGER,
    source_system VARCHAR(64) NOT NULL DEFAULT 'MIDO',
    schema_version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS data_quality_quarantine (
    id UUID PRIMARY KEY,
    rule_id VARCHAR(64) NOT NULL,
    reason_code VARCHAR(128) NOT NULL,
    dataset_name VARCHAR(128) NOT NULL,
    source_pk VARCHAR(128),
    batch_id VARCHAR(128),
    failed_payload_hash VARCHAR(128),
    severity VARCHAR(20) NOT NULL,
    detected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_quarantine_severity CHECK (severity IN ('P0', 'P1', 'P2', 'P3'))
);

CREATE TABLE IF NOT EXISTS data_quality_rule (
    rule_id VARCHAR(64) PRIMARY KEY,
    rule_name VARCHAR(255) NOT NULL,
    layer_name VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    zero_tolerance BOOLEAN NOT NULL DEFAULT false,
    rule_sql TEXT,
    owner VARCHAR(128),
    enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_data_quality_rule_layer
        CHECK (layer_name IN ('SOURCE_OLTP', 'EVENT_RAW', 'CORE_MART')),
    CONSTRAINT chk_data_quality_rule_severity
        CHECK (severity IN ('P0', 'P1', 'P2', 'P3')),
    CONSTRAINT chk_data_quality_rule_timestamp_order
        CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS data_quality_run (
    run_id UUID PRIMARY KEY,
    dataset_name VARCHAR(128) NOT NULL,
    partition_key VARCHAR(128),
    batch_id VARCHAR(128),
    status VARCHAR(20) NOT NULL DEFAULT 'RUNNING',
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at TIMESTAMPTZ,
    owner VARCHAR(128),
    CONSTRAINT chk_data_quality_run_status
        CHECK (status IN ('RUNNING', 'PASSED', 'FAILED', 'BLOCKED')),
    CONSTRAINT chk_data_quality_run_time_order
        CHECK (ended_at IS NULL OR started_at <= ended_at)
);

CREATE TABLE IF NOT EXISTS data_quality_result (
    id UUID PRIMARY KEY,
    run_id UUID NOT NULL REFERENCES data_quality_run(run_id),
    rule_id VARCHAR(64) NOT NULL REFERENCES data_quality_rule(rule_id),
    observed_value TEXT,
    expected_value TEXT,
    failed_count BIGINT NOT NULL DEFAULT 0,
    sample_hash VARCHAR(128),
    severity VARCHAR(20) NOT NULL,
    disposition VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    owner VARCHAR(128),
    ticket VARCHAR(255),
    rerun_result VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_data_quality_result UNIQUE (run_id, rule_id),
    CONSTRAINT chk_data_quality_result_failed_count CHECK (failed_count >= 0),
    CONSTRAINT chk_data_quality_result_severity CHECK (severity IN ('P0', 'P1', 'P2', 'P3')),
    CONSTRAINT chk_data_quality_result_disposition
        CHECK (disposition IN ('OPEN', 'QUARANTINED', 'WAIVED', 'FIXED', 'ACCEPTED')),
    CONSTRAINT chk_data_quality_result_rerun
        CHECK (rerun_result IS NULL OR rerun_result IN ('PASS', 'FAIL', 'BLOCKED', 'NOT_RUN'))
);

CREATE TABLE IF NOT EXISTS data_reconciliation_result (
    id UUID PRIMARY KEY,
    run_id UUID NOT NULL REFERENCES data_quality_run(run_id),
    source_dataset VARCHAR(128) NOT NULL,
    target_dataset VARCHAR(128) NOT NULL,
    source_count BIGINT NOT NULL,
    target_count BIGINT NOT NULL,
    source_checksum VARCHAR(128),
    target_checksum VARCHAR(128),
    difference_count BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_data_reconciliation_counts
        CHECK (source_count >= 0 AND target_count >= 0 AND difference_count >= 0),
    CONSTRAINT chk_data_reconciliation_status
        CHECK (status IN ('PASS', 'FAIL', 'BLOCKED'))
);

CREATE TABLE IF NOT EXISTS pipeline_watermark (
    pipeline_name VARCHAR(128) PRIMARY KEY,
    source_entity VARCHAR(128) NOT NULL,
    last_success_updated_at TIMESTAMPTZ,
    last_success_id UUID,
    last_success_batch_id VARCHAR(128),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pipeline_run (
    pipeline_run_id UUID PRIMARY KEY,
    pipeline_name VARCHAR(128) NOT NULL,
    batch_id VARCHAR(128) NOT NULL UNIQUE,
    source_from_updated_at TIMESTAMPTZ,
    source_from_id UUID,
    source_to_updated_at TIMESTAMPTZ,
    source_to_id UUID,
    rows_read BIGINT NOT NULL DEFAULT 0,
    rows_written BIGINT NOT NULL DEFAULT 0,
    rows_rejected BIGINT NOT NULL DEFAULT 0,
    checksum VARCHAR(128),
    code_version VARCHAR(128) NOT NULL,
    schema_version INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'QUEUED',
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at TIMESTAMPTZ,
    retry_count INTEGER NOT NULL DEFAULT 0,
    error_message TEXT,
    CONSTRAINT chk_pipeline_run_status
        CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'FAILED', 'SKIPPED')),
    CONSTRAINT chk_pipeline_run_counts
        CHECK (rows_read >= 0 AND rows_written >= 0 AND rows_rejected >= 0 AND retry_count >= 0),
    CONSTRAINT chk_pipeline_run_time_order
        CHECK (ended_at IS NULL OR started_at <= ended_at),
    CONSTRAINT chk_pipeline_run_watermark_order
        CHECK (
            source_from_updated_at IS NULL
            OR source_to_updated_at IS NULL
            OR source_from_updated_at <= source_to_updated_at
        )
);

CREATE TABLE IF NOT EXISTS pipeline_task_run (
    task_run_id UUID PRIMARY KEY,
    pipeline_run_id UUID NOT NULL REFERENCES pipeline_run(pipeline_run_id),
    task_name VARCHAR(128) NOT NULL,
    batch_id VARCHAR(128) NOT NULL,
    source_from_updated_at TIMESTAMPTZ,
    source_from_id UUID,
    source_to_updated_at TIMESTAMPTZ,
    source_to_id UUID,
    rows_read BIGINT NOT NULL DEFAULT 0,
    rows_written BIGINT NOT NULL DEFAULT 0,
    rows_rejected BIGINT NOT NULL DEFAULT 0,
    checksum VARCHAR(128),
    code_version VARCHAR(128) NOT NULL,
    schema_version INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'QUEUED',
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at TIMESTAMPTZ,
    retry_count INTEGER NOT NULL DEFAULT 0,
    error_message TEXT,
    CONSTRAINT uq_pipeline_task_run UNIQUE (pipeline_run_id, task_name),
    CONSTRAINT chk_pipeline_task_run_status
        CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'FAILED', 'SKIPPED')),
    CONSTRAINT chk_pipeline_task_run_counts
        CHECK (rows_read >= 0 AND rows_written >= 0 AND rows_rejected >= 0 AND retry_count >= 0),
    CONSTRAINT chk_pipeline_task_run_time_order
        CHECK (ended_at IS NULL OR started_at <= ended_at),
    CONSTRAINT chk_pipeline_task_watermark_order
        CHECK (
            source_from_updated_at IS NULL
            OR source_to_updated_at IS NULL
            OR source_from_updated_at <= source_to_updated_at
        )
);

CREATE TABLE IF NOT EXISTS pipeline_backfill_request (
    id UUID PRIMARY KEY,
    entity_scope VARCHAR(128) NOT NULL,
    source_from TIMESTAMPTZ NOT NULL,
    source_to TIMESTAMPTZ NOT NULL,
    dry_run BOOLEAN NOT NULL DEFAULT true,
    reason TEXT NOT NULL,
    approver_id_hash VARCHAR(128),
    status VARCHAR(20) NOT NULL DEFAULT 'QUEUED',
    requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    CONSTRAINT chk_pipeline_backfill_status
        CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'FAILED', 'SKIPPED')),
    CONSTRAINT chk_pipeline_backfill_range
        CHECK (source_from < source_to),
    CONSTRAINT chk_pipeline_backfill_time_order
        CHECK (
            (started_at IS NULL OR requested_at <= started_at)
            AND (ended_at IS NULL OR started_at IS NULL OR started_at <= ended_at)
        )
);

CREATE INDEX IF NOT EXISTS idx_verification_status_created
    ON verification_data(status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_verification_input_type_created
    ON verification_data(input_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_verification_draft_created
    ON verification_data(created_at DESC)
    WHERE status = 'DRAFT';

CREATE INDEX IF NOT EXISTS idx_manual_input_verification
    ON manual_input(verification_data_id);

CREATE INDEX IF NOT EXISTS idx_uploaded_file_verification_uploaded
    ON uploaded_file(verification_data_id, uploaded_at DESC);

CREATE INDEX IF NOT EXISTS idx_work_context_verification
    ON work_context(verification_data_id);

CREATE INDEX IF NOT EXISTS idx_data_event_verification_occurred
    ON data_event(verification_id, occurred_at);

CREATE INDEX IF NOT EXISTS idx_data_event_batch
    ON data_event(batch_id, loaded_at);

CREATE INDEX IF NOT EXISTS idx_status_transition_verification_occurred
    ON verification_status_transition(verification_data_id, occurred_at);

CREATE INDEX IF NOT EXISTS idx_risk_assessment_verification
    ON risk_assessment(verification_data_id);

CREATE INDEX IF NOT EXISTS idx_data_quality_run_status_started
    ON data_quality_run(status, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_data_quality_result_rule
    ON data_quality_result(rule_id, severity, disposition);

CREATE INDEX IF NOT EXISTS idx_data_quality_quarantine_batch
    ON data_quality_quarantine(batch_id, rule_id);

CREATE INDEX IF NOT EXISTS idx_pipeline_run_status_started
    ON pipeline_run(status, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_pipeline_task_run_batch
    ON pipeline_task_run(batch_id, task_name);

CREATE INDEX IF NOT EXISTS idx_pipeline_backfill_status_requested
    ON pipeline_backfill_request(status, requested_at DESC);

INSERT INTO data_quality_rule (rule_id, rule_name, layer_name, severity, zero_tolerance, owner)
VALUES
    ('DQ-001', 'verification_id PK unique/not null', 'SOURCE_OLTP', 'P0', true, 'BE'),
    ('DQ-002', 'verification status enum', 'SOURCE_OLTP', 'P0', true, 'BE'),
    ('DQ-003', 'input_type allowed values', 'SOURCE_OLTP', 'P0', true, 'BE'),
    ('DQ-004', 'created_at <= updated_at', 'SOURCE_OLTP', 'P0', true, 'BE'),
    ('DQ-005', 'ManualInput/UploadedFile/WorkContext FK orphan 0', 'SOURCE_OLTP', 'P0', true, 'BE'),
    ('DQ-006', 'context projection excludes code LOB', 'SOURCE_OLTP', 'P0', true, 'BE'),
    ('DQ-007', 'DONE requires analysis or completion evidence policy', 'SOURCE_OLTP', 'P1', false, 'QA'),
    ('DQ-101', 'event_id unique', 'EVENT_RAW', 'P0', true, 'DE'),
    ('DQ-102', 'occurred_at clock skew', 'EVENT_RAW', 'P1', false, 'DE'),
    ('DQ-103', 'schema_version exists', 'EVENT_RAW', 'P0', true, 'DE'),
    ('DQ-104', 'raw code/secret/PII detection 0', 'EVENT_RAW', 'P0', true, 'SECURITY'),
    ('DQ-105', 'producer required attributes', 'EVENT_RAW', 'P1', false, 'DE'),
    ('DQ-201', 'source_pk duplicate 0', 'CORE_MART', 'P0', true, 'DE'),
    ('DQ-202', 'invalid status transition 0', 'CORE_MART', 'P0', true, 'BE'),
    ('DQ-203', 'decision/approval orphan 0', 'CORE_MART', 'P0', true, 'BE'),
    ('DQ-204', 'funnel time order', 'CORE_MART', 'P1', false, 'DA'),
    ('DQ-205', 'KPI numerator <= denominator', 'CORE_MART', 'P0', true, 'DA'),
    ('DQ-206', 'source-core-mart reconciliation', 'CORE_MART', 'P0', true, 'DE')
ON CONFLICT (rule_id) DO UPDATE SET
    rule_name = EXCLUDED.rule_name,
    layer_name = EXCLUDED.layer_name,
    severity = EXCLUDED.severity,
    zero_tolerance = EXCLUDED.zero_tolerance,
    owner = EXCLUDED.owner,
    updated_at = now();

CREATE TABLE IF NOT EXISTS analytics_model_catalog (
    model_name VARCHAR(128) PRIMARY KEY,
    model_layer VARCHAR(50) NOT NULL,
    purpose TEXT NOT NULL,
    grain TEXT NOT NULL,
    primary_key_definition TEXT NOT NULL,
    source_objects TEXT NOT NULL,
    refresh_policy VARCHAR(128) NOT NULL,
    owner VARCHAR(128) NOT NULL,
    sensitivity VARCHAR(50) NOT NULL,
    tests TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_analytics_model_layer
        CHECK (model_layer IN ('STAGING', 'INTERMEDIATE', 'MART')),
    CONSTRAINT chk_analytics_model_sensitivity
        CHECK (sensitivity IN ('PUBLIC', 'INTERNAL', 'CONFIDENTIAL', 'RESTRICTED')),
    CONSTRAINT chk_analytics_model_timestamp_order
        CHECK (created_at <= updated_at)
);

CREATE OR REPLACE VIEW stg_verification_data AS
SELECT
    id AS verification_id,
    input_type,
    status,
    repo_url,
    commit_hash,
    pr_number,
    source_system,
    schema_version,
    created_at,
    updated_at
FROM verification_data;

CREATE OR REPLACE VIEW stg_work_context AS
SELECT
    id AS work_context_id,
    verification_data_id AS verification_id,
    display_repo_url,
    display_commit_hash,
    display_pr_number,
    source_system,
    schema_version,
    created_at,
    updated_at
FROM work_context;

CREATE OR REPLACE VIEW stg_risk_assessment AS
SELECT
    id AS risk_assessment_id,
    verification_data_id AS verification_id,
    analysis_run_id,
    finding_id,
    severity,
    status,
    model_version,
    prompt_version,
    source_system,
    schema_version,
    created_at,
    updated_at
FROM risk_assessment;

CREATE OR REPLACE VIEW stg_decision_log AS
SELECT
    id AS decision_log_id,
    verification_data_id AS verification_id,
    decision,
    (rationale IS NOT NULL AND length(trim(rationale)) > 0) AS has_rationale,
    actor_id_hash,
    source_system,
    schema_version,
    created_at
FROM decision_log;

CREATE OR REPLACE VIEW stg_approval AS
SELECT
    a.id AS approval_id,
    d.verification_data_id AS verification_id,
    a.decision_log_id,
    a.reviewer_id_hash,
    a.action,
    (a.reason IS NOT NULL AND length(trim(a.reason)) > 0) AS has_reason,
    a.approved_at,
    a.source_system,
    a.schema_version
FROM approval a
JOIN decision_log d ON d.id = a.decision_log_id;

CREATE OR REPLACE VIEW stg_status_event AS
SELECT
    event_id,
    verification_data_id AS verification_id,
    from_status,
    to_status,
    occurred_at,
    actor_id_hash,
    source_system,
    schema_version
FROM verification_status_transition;

CREATE OR REPLACE VIEW int_verification_lifecycle AS
SELECT
    v.verification_id,
    v.input_type,
    v.status AS current_status,
    v.created_at AS verification_created_at,
    min(e.occurred_at) FILTER (WHERE e.to_status = 'READY') AS first_ready_at,
    min(e.occurred_at) FILTER (WHERE e.to_status = 'RUNNING') AS first_running_at,
    min(e.occurred_at) FILTER (WHERE e.to_status = 'DONE') AS first_done_at,
    min(e.occurred_at) FILTER (WHERE e.to_status = 'FAILED') AS first_failed_at,
    max(e.occurred_at) AS last_status_event_at,
    v.updated_at AS verification_updated_at
FROM stg_verification_data v
LEFT JOIN stg_status_event e ON e.verification_id = v.verification_id
GROUP BY
    v.verification_id,
    v.input_type,
    v.status,
    v.created_at,
    v.updated_at;

CREATE OR REPLACE VIEW int_decision_cycle AS
SELECT
    v.verification_id,
    max(r.updated_at) FILTER (WHERE r.status = 'DONE') AS analysis_completed_at,
    d.created_at AS decision_at,
    a.approved_at,
    d.decision,
    d.has_rationale,
    a.action AS approval_action,
    a.has_reason AS approval_has_reason
FROM stg_verification_data v
LEFT JOIN stg_risk_assessment r ON r.verification_id = v.verification_id
LEFT JOIN stg_decision_log d ON d.verification_id = v.verification_id
LEFT JOIN stg_approval a ON a.verification_id = v.verification_id
GROUP BY
    v.verification_id,
    d.created_at,
    a.approved_at,
    d.decision,
    d.has_rationale,
    a.action,
    a.has_reason;

CREATE OR REPLACE VIEW int_rework_cycle AS
SELECT
    d.verification_id,
    d.decision,
    (d.decision = 'FIX') AS fix_decision_flag,
    EXISTS (
        SELECT 1
        FROM verification_status_transition e
        WHERE e.verification_data_id = d.verification_id
          AND e.from_status = 'FAILED'
          AND e.to_status IN ('READY', 'RUNNING')
    ) AS rework_detected_flag
FROM stg_decision_log d;

CREATE OR REPLACE VIEW int_audit_completeness AS
SELECT
    v.verification_id,
    v.schema_version IS NOT NULL AS has_schema_version,
    d.decision_log_id IS NOT NULL AS has_decision_log,
    COALESCE(d.has_rationale, false) AS has_decision_rationale,
    a.approval_id IS NOT NULL AS has_approval,
    r.risk_assessment_id IS NOT NULL AS has_risk_assessment,
    r.model_version IS NOT NULL AS has_model_version,
    r.prompt_version IS NOT NULL AS has_prompt_version
FROM stg_verification_data v
LEFT JOIN stg_decision_log d ON d.verification_id = v.verification_id
LEFT JOIN stg_approval a ON a.verification_id = v.verification_id
LEFT JOIN stg_risk_assessment r ON r.verification_id = v.verification_id;

CREATE OR REPLACE VIEW fct_verification AS
SELECT
    lifecycle.verification_id,
    lifecycle.input_type,
    lifecycle.current_status,
    lifecycle.verification_created_at,
    lifecycle.first_ready_at,
    lifecycle.first_running_at,
    lifecycle.first_done_at,
    lifecycle.first_failed_at,
    lifecycle.last_status_event_at,
    lifecycle.verification_updated_at
FROM int_verification_lifecycle lifecycle;

CREATE OR REPLACE VIEW fct_decision AS
SELECT
    decision_cycle.verification_id,
    decision_cycle.analysis_completed_at,
    decision_cycle.decision_at,
    decision_cycle.decision,
    decision_cycle.has_rationale,
    EXTRACT(EPOCH FROM (decision_cycle.decision_at - decision_cycle.analysis_completed_at))::BIGINT
        AS analysis_to_decision_seconds
FROM int_decision_cycle decision_cycle;

CREATE OR REPLACE VIEW fct_approval AS
SELECT
    decision_cycle.verification_id,
    decision_cycle.decision_at,
    decision_cycle.approved_at,
    decision_cycle.approval_action,
    decision_cycle.approval_has_reason,
    EXTRACT(EPOCH FROM (decision_cycle.approved_at - decision_cycle.decision_at))::BIGINT
        AS decision_to_approval_seconds
FROM int_decision_cycle decision_cycle
WHERE decision_cycle.approved_at IS NOT NULL;

CREATE OR REPLACE VIEW mart_daily_product_metrics AS
SELECT
    date_trunc('day', v.verification_created_at)::date AS metric_date,
    count(*) AS verification_started_count,
    count(*) FILTER (WHERE v.current_status = 'DONE') AS verification_done_count,
    count(d.verification_id) AS decision_log_count,
    count(*) FILTER (WHERE d.decision = 'FIX') AS fix_decision_count,
    count(*) FILTER (WHERE r.rework_detected_flag) AS rework_count,
    CASE
        WHEN count(*) FILTER (WHERE v.current_status = 'DONE') = 0 THEN NULL
        ELSE count(d.verification_id)::numeric
            / count(*) FILTER (WHERE v.current_status = 'DONE')
    END AS m001_decision_log_rate,
    avg(a.decision_to_approval_seconds) AS m002_avg_approval_seconds,
    CASE
        WHEN count(*) FILTER (WHERE v.current_status = 'DONE') = 0 THEN NULL
        ELSE count(*) FILTER (WHERE r.rework_detected_flag)::numeric
            / count(*) FILTER (WHERE v.current_status = 'DONE')
    END AS m003_rework_rate,
    CASE
        WHEN count(*) = 0 THEN NULL
        ELSE count(*) FILTER (WHERE v.current_status = 'DONE')::numeric / count(*)
    END AS m004_completion_rate,
    NULL::numeric AS m005_audit_manual_time_reduction_rate
FROM fct_verification v
LEFT JOIN fct_decision d ON d.verification_id = v.verification_id
LEFT JOIN fct_approval a ON a.verification_id = v.verification_id
LEFT JOIN int_rework_cycle r ON r.verification_id = v.verification_id
GROUP BY date_trunc('day', v.verification_created_at)::date;

CREATE OR REPLACE VIEW mart_team_quality AS
SELECT
    event.team_id,
    date_trunc('day', event.occurred_at)::date AS metric_date,
    count(DISTINCT event.verification_id) AS verification_event_count,
    count(*) FILTER (WHERE result.severity = 'P0' AND result.failed_count > 0) AS p0_quality_failure_count,
    count(*) FILTER (WHERE result.severity = 'P1' AND result.failed_count > 0) AS p1_quality_failure_count
FROM data_event event
LEFT JOIN data_quality_run run ON run.batch_id = event.batch_id
LEFT JOIN data_quality_result result ON result.run_id = run.run_id
GROUP BY event.team_id, date_trunc('day', event.occurred_at)::date;

CREATE OR REPLACE VIEW mart_ai_operations AS
SELECT
    date_trunc('day', r.created_at)::date AS metric_date,
    r.model_version,
    r.prompt_version,
    count(DISTINCT r.analysis_run_id) AS analysis_run_count,
    count(*) AS finding_count,
    count(*) FILTER (WHERE r.severity IN ('S1', 'S2', 'HIGH', 'CRITICAL')) AS high_risk_finding_count,
    count(*) FILTER (WHERE r.status = 'FAILED') AS failed_finding_count
FROM stg_risk_assessment r
GROUP BY
    date_trunc('day', r.created_at)::date,
    r.model_version,
    r.prompt_version;

INSERT INTO analytics_model_catalog (
    model_name,
    model_layer,
    purpose,
    grain,
    primary_key_definition,
    source_objects,
    refresh_policy,
    owner,
    sensitivity,
    tests
)
VALUES
    ('stg_verification_data', 'STAGING', 'Normalize verification source fields without code LOB', 'verification_id one row', 'verification_id', 'verification_data', 'incremental', 'DE', 'INTERNAL', 'unique, not_null, accepted_values, no_raw_code'),
    ('stg_work_context', 'STAGING', 'Normalize work context display metadata', 'work_context_id one row', 'work_context_id', 'work_context', 'incremental', 'DE', 'INTERNAL', 'unique, relationships, no_raw_code'),
    ('stg_risk_assessment', 'STAGING', 'Normalize AI risk assessment metadata', 'risk_assessment_id one row', 'risk_assessment_id', 'risk_assessment', 'incremental', 'DE', 'CONFIDENTIAL', 'unique, relationships, accepted_values'),
    ('stg_decision_log', 'STAGING', 'Normalize decision log metadata and rationale presence', 'decision_log_id one row', 'decision_log_id', 'decision_log', 'incremental', 'DE', 'CONFIDENTIAL', 'unique, relationships, accepted_values'),
    ('stg_approval', 'STAGING', 'Normalize reviewer approval metadata', 'approval_id one row', 'approval_id', 'approval, decision_log', 'incremental', 'DE', 'CONFIDENTIAL', 'unique, relationships, accepted_values'),
    ('stg_status_event', 'STAGING', 'Normalize verification status transition events', 'event_id one row', 'event_id', 'verification_status_transition', 'incremental', 'DE', 'INTERNAL', 'unique, relationships, accepted_values'),
    ('int_verification_lifecycle', 'INTERMEDIATE', 'Derive first lifecycle timestamps per verification', 'verification_id one row', 'verification_id', 'stg_verification_data, stg_status_event', 'incremental', 'DE', 'INTERNAL', 'unique, timestamp_order'),
    ('int_decision_cycle', 'INTERMEDIATE', 'Derive analysis to decision to approval cycle', 'verification_id one row', 'verification_id', 'stg_verification_data, stg_risk_assessment, stg_decision_log, stg_approval', 'incremental', 'DE', 'CONFIDENTIAL', 'relationships, timestamp_order'),
    ('int_rework_cycle', 'INTERMEDIATE', 'Detect fix and rework cycles', 'verification_id one row', 'verification_id', 'stg_decision_log, verification_status_transition', 'incremental', 'DE', 'INTERNAL', 'relationships, deterministic_rerun'),
    ('int_audit_completeness', 'INTERMEDIATE', 'Track required audit evidence completeness', 'verification_id one row', 'verification_id', 'stg_verification_data, stg_decision_log, stg_approval, stg_risk_assessment', 'incremental', 'QA', 'CONFIDENTIAL', 'relationships, not_null'),
    ('fct_verification', 'MART', 'Verification fact for product metrics', 'verification_id one row', 'verification_id', 'int_verification_lifecycle', 'incremental', 'DA', 'INTERNAL', 'unique, timestamp_order, reconciliation'),
    ('fct_decision', 'MART', 'Decision fact for M-001 and cycle metrics', 'verification_id one row when decision exists', 'verification_id', 'int_decision_cycle', 'incremental', 'DA', 'CONFIDENTIAL', 'relationships, numerator_denominator'),
    ('fct_approval', 'MART', 'Approval fact for M-002', 'verification_id one row when approval exists', 'verification_id', 'int_decision_cycle', 'incremental', 'DA', 'CONFIDENTIAL', 'relationships, timestamp_order'),
    ('mart_daily_product_metrics', 'MART', 'Daily M-001 to M-005 product metrics', 'metric_date one row', 'metric_date', 'fct_verification, fct_decision, fct_approval, int_rework_cycle', 'daily', 'DA', 'INTERNAL', 'numerator_denominator, snapshot_regression'),
    ('mart_team_quality', 'MART', 'Team-level quality failures and verification activity', 'team_id and metric_date one row', 'team_id, metric_date', 'data_event, data_quality_run, data_quality_result', 'daily', 'DA', 'CONFIDENTIAL', 'relationships, reconciliation'),
    ('mart_ai_operations', 'MART', 'AI operation metrics by model and prompt version', 'metric_date, model_version, prompt_version one row', 'metric_date, model_version, prompt_version', 'stg_risk_assessment', 'daily', 'DA', 'CONFIDENTIAL', 'accepted_values, snapshot_regression')
ON CONFLICT (model_name) DO UPDATE SET
    model_layer = EXCLUDED.model_layer,
    purpose = EXCLUDED.purpose,
    grain = EXCLUDED.grain,
    primary_key_definition = EXCLUDED.primary_key_definition,
    source_objects = EXCLUDED.source_objects,
    refresh_policy = EXCLUDED.refresh_policy,
    owner = EXCLUDED.owner,
    sensitivity = EXCLUDED.sensitivity,
    tests = EXCLUDED.tests,
    updated_at = now();
