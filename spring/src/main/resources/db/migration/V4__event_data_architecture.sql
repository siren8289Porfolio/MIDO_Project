CREATE TABLE IF NOT EXISTS analytics_event_schema (
    event_name VARCHAR(128) PRIMARY KEY,
    schema_version VARCHAR(32) NOT NULL,
    event_description TEXT NOT NULL,
    trigger_description TEXT NOT NULL,
    producer VARCHAR(128) NOT NULL,
    owner VARCHAR(128) NOT NULL,
    grain VARCHAR(128) NOT NULL,
    pii_class VARCHAR(64) NOT NULL,
    retry_policy TEXT NOT NULL,
    source_status VARCHAR(32) NOT NULL DEFAULT 'PLANNED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_event_schema_name_past_tense
        CHECK (event_name ~ '^[a-z][a-z0-9_]*ed$' OR event_name IN ('analysis_started', 'approval_requested')),
    CONSTRAINT chk_event_schema_pii_class
        CHECK (pii_class IN ('NONE', 'PSEUDONYMIZED', 'SENSITIVE', 'RESTRICTED')),
    CONSTRAINT chk_event_schema_source_status
        CHECK (source_status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_event_schema_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS analytics_event_property (
    id UUID PRIMARY KEY,
    event_name VARCHAR(128) NOT NULL REFERENCES analytics_event_schema(event_name),
    property_name VARCHAR(128) NOT NULL,
    property_type VARCHAR(64) NOT NULL,
    required BOOLEAN NOT NULL DEFAULT false,
    pii_class VARCHAR(64) NOT NULL DEFAULT 'NONE',
    allowed_values TEXT,
    description TEXT NOT NULL,
    CONSTRAINT uq_event_property UNIQUE (event_name, property_name),
    CONSTRAINT chk_event_property_pii_class
        CHECK (pii_class IN ('NONE', 'PSEUDONYMIZED', 'SENSITIVE', 'RESTRICTED')),
    CONSTRAINT chk_event_property_no_forbidden_payload
        CHECK (property_name NOT IN ('code_content', 'raw_code', 'prompt', 'credential', 'access_token', 'personal_identifier'))
);

CREATE TABLE IF NOT EXISTS analytics_event_metric_trace (
    id UUID PRIMARY KEY,
    event_name VARCHAR(128) NOT NULL REFERENCES analytics_event_schema(event_name),
    downstream_metric_id VARCHAR(32) NOT NULL,
    downstream_model VARCHAR(128) NOT NULL,
    qa_case_id VARCHAR(64) NOT NULL,
    trace_status VARCHAR(32) NOT NULL DEFAULT 'PLANNED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_event_metric_trace UNIQUE (event_name, downstream_metric_id, downstream_model),
    CONSTRAINT chk_event_metric_trace_status
        CHECK (trace_status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED'))
);

CREATE TABLE IF NOT EXISTS analytics_event_contract_test (
    test_id VARCHAR(64) PRIMARY KEY,
    test_name VARCHAR(255) NOT NULL,
    target_event_name VARCHAR(128) REFERENCES analytics_event_schema(event_name),
    test_type VARCHAR(64) NOT NULL,
    expected_result TEXT NOT NULL,
    owner VARCHAR(128) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'NOT_TESTED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_event_contract_test_type
        CHECK (test_type IN ('DUPLICATE_ID', 'REQUIRED_FIELD', 'TIMESTAMP_ORDER', 'ENUM', 'ORPHAN', 'SCHEMA_COMPATIBILITY', 'FRESHNESS', 'SECRET_DETECTION', 'RECONCILIATION')),
    CONSTRAINT chk_event_contract_test_status
        CHECK (status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_event_contract_test_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS analytics_event_schema_change (
    id UUID PRIMARY KEY,
    event_name VARCHAR(128) NOT NULL REFERENCES analytics_event_schema(event_name),
    from_version VARCHAR(32),
    to_version VARCHAR(32) NOT NULL,
    change_type VARCHAR(32) NOT NULL,
    change_description TEXT NOT NULL,
    backward_compatible BOOLEAN NOT NULL,
    dual_read_required BOOLEAN NOT NULL DEFAULT false,
    backfill_plan TEXT,
    approved_by VARCHAR(128),
    effective_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_event_schema_change_type
        CHECK (change_type IN ('OPTIONAL_ADD', 'DELETE', 'RENAME', 'TYPE_CHANGE', 'MAJOR_VERSION')),
    CONSTRAINT chk_event_schema_breaking_plan
        CHECK (backward_compatible OR (dual_read_required AND backfill_plan IS NOT NULL))
);

CREATE TABLE IF NOT EXISTS analytics_bi_serving_contract (
    dashboard_id VARCHAR(128) PRIMARY KEY,
    dashboard_name VARCHAR(255) NOT NULL,
    mart_name VARCHAR(128) NOT NULL,
    dimensions TEXT NOT NULL,
    privacy_threshold INTEGER NOT NULL DEFAULT 10,
    required_metadata TEXT NOT NULL,
    owner VARCHAR(128) NOT NULL,
    measurement_status VARCHAR(32) NOT NULL DEFAULT 'NOT_MEASURED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_bi_serving_privacy_threshold CHECK (privacy_threshold >= 0),
    CONSTRAINT chk_bi_serving_measurement_status
        CHECK (measurement_status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_bi_serving_timestamp_order CHECK (created_at <= updated_at)
);

CREATE OR REPLACE VIEW analytics_event_catalog AS
SELECT
    schema.event_name,
    schema.schema_version,
    schema.event_description,
    schema.trigger_description,
    schema.producer,
    schema.owner,
    schema.grain,
    schema.pii_class,
    schema.retry_policy,
    schema.source_status,
    COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'property_name', prop.property_name,
                'property_type', prop.property_type,
                'required', prop.required,
                'pii_class', prop.pii_class,
                'allowed_values', prop.allowed_values,
                'description', prop.description
            )
            ORDER BY prop.property_name
        ) FILTER (WHERE prop.id IS NOT NULL),
        '[]'::jsonb
    ) AS properties
FROM analytics_event_schema schema
LEFT JOIN analytics_event_property prop ON prop.event_name = schema.event_name
GROUP BY
    schema.event_name,
    schema.schema_version,
    schema.event_description,
    schema.trigger_description,
    schema.producer,
    schema.owner,
    schema.grain,
    schema.pii_class,
    schema.retry_policy,
    schema.source_status;

CREATE OR REPLACE VIEW analytics_event_lineage AS
SELECT
    trace.event_name,
    trace.downstream_model,
    trace.downstream_metric_id,
    trace.qa_case_id,
    trace.trace_status
FROM analytics_event_metric_trace trace;

INSERT INTO analytics_event_schema (
    event_name,
    schema_version,
    event_description,
    trigger_description,
    producer,
    owner,
    grain,
    pii_class,
    retry_policy,
    source_status
)
VALUES
    ('verification_created', '1.0', 'Verification 생성 완료', 'OLTP verification create commit 이후', 'mido-be', 'BE', 'verification', 'PSEUDONYMIZED', 'event_id 멱등 처리', 'IMPLEMENTED'),
    ('manual_input_saved', '1.0', '수동 입력 저장 완료', 'manual_input commit 이후', 'mido-be', 'BE', 'verification', 'PSEUDONYMIZED', 'event_id 멱등 처리', 'IMPLEMENTED'),
    ('file_uploaded', '1.0', '파일 업로드 저장 완료', 'uploaded_file commit 이후', 'mido-be', 'BE', 'verification', 'SENSITIVE', 'event_id 멱등 처리', 'IMPLEMENTED'),
    ('work_context_ready', '1.0', 'Work context 준비 완료', 'work_context commit 이후', 'mido-be', 'BE', 'verification', 'PSEUDONYMIZED', 'event_id 멱등 처리', 'IMPLEMENTED'),
    ('analysis_started', '1.0', 'AI 분석 시작', 'analysis run 시작 시', 'mido-ai', 'AI', 'analysis_run', 'PSEUDONYMIZED', 'event_id 멱등 처리', 'PLANNED'),
    ('analysis_completed', '1.0', 'AI 분석 완료', 'analysis run 성공 완료 시', 'mido-ai', 'AI', 'analysis_run', 'PSEUDONYMIZED', 'event_id 멱등 처리', 'PLANNED'),
    ('analysis_failed', '1.0', 'AI 분석 실패', 'analysis run 실패 시', 'mido-ai', 'AI', 'analysis_run', 'PSEUDONYMIZED', 'event_id 멱등 처리', 'PLANNED'),
    ('risk_finding_produced', '1.0', 'Risk finding 생성 완료', 'risk finding 저장 이후', 'mido-ai', 'AI', 'finding', 'PSEUDONYMIZED', 'event_id 멱등 처리', 'PLANNED'),
    ('guideline_retrieved', '1.0', 'Guideline 조회 완료', 'guideline retrieval 완료 시', 'mido-ai', 'AI', 'guideline_retrieval', 'PSEUDONYMIZED', 'event_id 멱등 처리', 'PLANNED'),
    ('decision_submitted', '1.0', '인간 decision 제출 완료', 'DecisionLog commit 이후', 'mido-be', 'DA', 'decision', 'PSEUDONYMIZED', 'event_id 멱등 처리', 'PLANNED'),
    ('approval_requested', '1.0', '승인 요청', 'approval 필요 대상 생성 시', 'mido-be', 'QA', 'approval', 'PSEUDONYMIZED', 'event_id 멱등 처리', 'PLANNED'),
    ('approval_completed', '1.0', '승인 완료', 'reviewer 승인/반려 commit 이후', 'mido-be', 'QA', 'approval', 'PSEUDONYMIZED', 'event_id 멱등 처리', 'PLANNED'),
    ('verification_status_changed', '1.0', 'Verification 상태 변경 완료', '상태 변경 commit 이후', 'mido-be', 'BE', 'status_event', 'PSEUDONYMIZED', 'event_id 멱등 처리', 'PLANNED'),
    ('verification_reopened', '1.0', 'Verification 재개 완료', '재시도 또는 재개 상태 변경 commit 이후', 'mido-be', 'BE', 'verification', 'PSEUDONYMIZED', 'event_id 멱등 처리', 'PLANNED'),
    ('verification_backfilled', '1.0', 'Verification backfill 완료', 'backfill 작업 완료 이후', 'mido-de', 'DE', 'verification', 'PSEUDONYMIZED', 'event_id 멱등 처리', 'PLANNED')
ON CONFLICT (event_name) DO UPDATE SET
    schema_version = EXCLUDED.schema_version,
    event_description = EXCLUDED.event_description,
    trigger_description = EXCLUDED.trigger_description,
    producer = EXCLUDED.producer,
    owner = EXCLUDED.owner,
    grain = EXCLUDED.grain,
    pii_class = EXCLUDED.pii_class,
    retry_policy = EXCLUDED.retry_policy,
    source_status = EXCLUDED.source_status,
    updated_at = now();

INSERT INTO analytics_event_property (
    id,
    event_name,
    property_name,
    property_type,
    required,
    pii_class,
    allowed_values,
    description
)
VALUES
    ('20000000-0000-0000-0000-000000000001', 'verification_created', 'input_type', 'string', true, 'NONE', 'PASTE,FILE,COMMIT,PR', '입력 유형'),
    ('20000000-0000-0000-0000-000000000002', 'verification_created', 'source_metadata_present', 'boolean', true, 'NONE', 'true,false', 'source metadata 존재 여부'),
    ('20000000-0000-0000-0000-000000000003', 'manual_input_saved', 'artifact_type', 'string', true, 'NONE', 'PASTE,COMMIT,PR', 'manual artifact type'),
    ('20000000-0000-0000-0000-000000000004', 'file_uploaded', 'artifact_type', 'string', true, 'NONE', 'FILE', 'file artifact type'),
    ('20000000-0000-0000-0000-000000000005', 'file_uploaded', 'size_bucket', 'string', true, 'NONE', NULL, '파일 크기 bucket'),
    ('20000000-0000-0000-0000-000000000006', 'file_uploaded', 'mime_category', 'string', true, 'NONE', NULL, 'MIME category'),
    ('20000000-0000-0000-0000-000000000007', 'file_uploaded', 'checksum', 'string', true, 'NONE', NULL, '파일 checksum'),
    ('20000000-0000-0000-0000-000000000008', 'work_context_ready', 'language', 'string', false, 'NONE', NULL, '언어'),
    ('20000000-0000-0000-0000-000000000009', 'work_context_ready', 'framework', 'string', false, 'NONE', NULL, '프레임워크'),
    ('20000000-0000-0000-0000-000000000010', 'work_context_ready', 'work_type', 'string', false, 'NONE', NULL, '작업 유형'),
    ('20000000-0000-0000-0000-000000000011', 'work_context_ready', 'required_fields_complete', 'boolean', true, 'NONE', 'true,false', '필수 필드 완성 여부'),
    ('20000000-0000-0000-0000-000000000012', 'analysis_started', 'run_id', 'uuid', true, 'NONE', NULL, 'analysis run id'),
    ('20000000-0000-0000-0000-000000000013', 'analysis_completed', 'run_id', 'uuid', true, 'NONE', NULL, 'analysis run id'),
    ('20000000-0000-0000-0000-000000000014', 'analysis_completed', 'model_version', 'string', true, 'NONE', NULL, 'model version'),
    ('20000000-0000-0000-0000-000000000015', 'analysis_completed', 'prompt_version', 'string', true, 'NONE', NULL, 'prompt version'),
    ('20000000-0000-0000-0000-000000000016', 'analysis_completed', 'policy_version', 'string', true, 'NONE', NULL, 'policy version'),
    ('20000000-0000-0000-0000-000000000017', 'analysis_completed', 'latency_ms', 'integer', true, 'NONE', NULL, 'analysis latency'),
    ('20000000-0000-0000-0000-000000000018', 'analysis_failed', 'error_category', 'string', true, 'NONE', NULL, 'error category'),
    ('20000000-0000-0000-0000-000000000019', 'risk_finding_produced', 'finding_id', 'string', true, 'NONE', NULL, 'finding id'),
    ('20000000-0000-0000-0000-000000000020', 'risk_finding_produced', 'category', 'string', true, 'NONE', NULL, 'finding category'),
    ('20000000-0000-0000-0000-000000000021', 'risk_finding_produced', 'severity', 'string', true, 'NONE', 'S1,S2,S3,S4,HIGH,CRITICAL', 'finding severity'),
    ('20000000-0000-0000-0000-000000000022', 'risk_finding_produced', 'evidence_count', 'integer', true, 'NONE', NULL, 'evidence count'),
    ('20000000-0000-0000-0000-000000000023', 'guideline_retrieved', 'guideline_id', 'uuid', true, 'NONE', NULL, 'guideline id'),
    ('20000000-0000-0000-0000-000000000024', 'guideline_retrieved', 'version', 'integer', true, 'NONE', NULL, 'guideline version'),
    ('20000000-0000-0000-0000-000000000025', 'guideline_retrieved', 'rank', 'integer', true, 'NONE', NULL, 'retrieval rank'),
    ('20000000-0000-0000-0000-000000000026', 'guideline_retrieved', 'matched', 'boolean', true, 'NONE', 'true,false', 'matched 여부'),
    ('20000000-0000-0000-0000-000000000027', 'decision_submitted', 'action', 'string', true, 'NONE', 'USE,FIX,IGNORE', 'human action'),
    ('20000000-0000-0000-0000-000000000028', 'decision_submitted', 'rationale_present', 'boolean', true, 'NONE', 'true,false', 'rationale presence'),
    ('20000000-0000-0000-0000-000000000029', 'decision_submitted', 'actor_role', 'string', true, 'NONE', NULL, 'actor role'),
    ('20000000-0000-0000-0000-000000000030', 'approval_requested', 'reviewer_role', 'string', true, 'NONE', NULL, 'reviewer role'),
    ('20000000-0000-0000-0000-000000000031', 'approval_completed', 'reviewer_role', 'string', true, 'NONE', NULL, 'reviewer role'),
    ('20000000-0000-0000-0000-000000000032', 'approval_completed', 'result', 'string', true, 'NONE', 'APPROVED,REJECTED,REQUEST_CHANGES', 'approval result'),
    ('20000000-0000-0000-0000-000000000033', 'approval_completed', 'duration_ms', 'integer', true, 'NONE', NULL, 'approval duration'),
    ('20000000-0000-0000-0000-000000000034', 'verification_status_changed', 'from_status', 'string', false, 'NONE', 'DRAFT,READY,RUNNING,DONE,FAILED', 'from status'),
    ('20000000-0000-0000-0000-000000000035', 'verification_status_changed', 'to_status', 'string', true, 'NONE', 'DRAFT,READY,RUNNING,DONE,FAILED', 'to status'),
    ('20000000-0000-0000-0000-000000000036', 'verification_status_changed', 'reason', 'string', false, 'NONE', NULL, 'status change reason'),
    ('20000000-0000-0000-0000-000000000037', 'verification_reopened', 'parent_verification_id', 'uuid', false, 'NONE', NULL, 'parent verification id'),
    ('20000000-0000-0000-0000-000000000038', 'verification_backfilled', 'reason', 'string', true, 'NONE', NULL, 'backfill reason')
ON CONFLICT (event_name, property_name) DO UPDATE SET
    property_type = EXCLUDED.property_type,
    required = EXCLUDED.required,
    pii_class = EXCLUDED.pii_class,
    allowed_values = EXCLUDED.allowed_values,
    description = EXCLUDED.description;

INSERT INTO analytics_event_contract_test (
    test_id,
    test_name,
    target_event_name,
    test_type,
    expected_result,
    owner,
    status
)
VALUES
    ('EVT-T-001', 'duplicate event_id', NULL, 'DUPLICATE_ID', 'duplicate event_id rejected or deduplicated', 'DE', 'NOT_TESTED'),
    ('EVT-T-002', 'missing required fields', NULL, 'REQUIRED_FIELD', 'required envelope and event properties are present', 'DE', 'NOT_TESTED'),
    ('EVT-T-003', 'timestamp order/clock skew', NULL, 'TIMESTAMP_ORDER', 'occurredAt <= receivedAt + allowed skew', 'DE', 'NOT_TESTED'),
    ('EVT-T-004', 'invalid enum/status transition', 'verification_status_changed', 'ENUM', 'invalid enum or impossible transition rejected', 'BE', 'NOT_TESTED'),
    ('EVT-T-005', 'orphan verification_id', NULL, 'ORPHAN', 'event verification_id maps to source verification', 'DE', 'NOT_TESTED'),
    ('EVT-T-006', 'schema compatibility', NULL, 'SCHEMA_COMPATIBILITY', 'optional field compatible, breaking changes require major version', 'DE', 'NOT_TESTED'),
    ('EVT-T-007', 'late arrival/freshness', NULL, 'FRESHNESS', 'late event and freshness policy applied', 'DE', 'NOT_TESTED'),
    ('EVT-T-008', 'raw code/secret detector', NULL, 'SECRET_DETECTION', 'payload contains no code_content, prompt body, credential, direct PII', 'SECURITY', 'NOT_TESTED'),
    ('EVT-T-009', 'source row vs event count reconciliation', NULL, 'RECONCILIATION', 'source row count and event count reconcile by window', 'DE', 'NOT_TESTED')
ON CONFLICT (test_id) DO UPDATE SET
    test_name = EXCLUDED.test_name,
    target_event_name = EXCLUDED.target_event_name,
    test_type = EXCLUDED.test_type,
    expected_result = EXCLUDED.expected_result,
    owner = EXCLUDED.owner,
    status = EXCLUDED.status,
    updated_at = now();

INSERT INTO analytics_bi_serving_contract (
    dashboard_id,
    dashboard_name,
    mart_name,
    dimensions,
    privacy_threshold,
    required_metadata,
    owner,
    measurement_status
)
VALUES
    ('DAILY_PRODUCT_METRICS', 'Daily product metrics', 'mart_daily_product_metrics', 'team,date,input,risk', 10, 'metric version,last refresh,data quality status,release annotation,owner', 'DA', 'NOT_MEASURED')
ON CONFLICT (dashboard_id) DO UPDATE SET
    dashboard_name = EXCLUDED.dashboard_name,
    mart_name = EXCLUDED.mart_name,
    dimensions = EXCLUDED.dimensions,
    privacy_threshold = EXCLUDED.privacy_threshold,
    required_metadata = EXCLUDED.required_metadata,
    owner = EXCLUDED.owner,
    measurement_status = EXCLUDED.measurement_status,
    updated_at = now();
