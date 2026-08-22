CREATE TABLE IF NOT EXISTS analytics_analysis_framework (
    framework_id VARCHAR(64) PRIMARY KEY,
    framework_order INTEGER NOT NULL UNIQUE,
    framework_name VARCHAR(64) NOT NULL,
    description TEXT NOT NULL,
    causal_claim_allowed BOOLEAN NOT NULL DEFAULT false,
    required_evidence TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_analysis_framework_order CHECK (framework_order > 0),
    CONSTRAINT chk_analysis_framework_name
        CHECK (framework_name IN ('DESCRIPTIVE', 'DIAGNOSTIC', 'COMPARATIVE', 'EXPERIMENTAL'))
);

CREATE TABLE IF NOT EXISTS analytics_funnel_step (
    step_id VARCHAR(64) PRIMARY KEY,
    step_order INTEGER NOT NULL UNIQUE,
    event_name VARCHAR(128) NOT NULL,
    required BOOLEAN NOT NULL DEFAULT true,
    grain VARCHAR(128) NOT NULL,
    time_to_next_metric VARCHAR(128),
    retry_policy TEXT NOT NULL,
    owner VARCHAR(128) NOT NULL,
    measurement_status VARCHAR(32) NOT NULL DEFAULT 'NOT_MEASURED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_funnel_step_order CHECK (step_order > 0),
    CONSTRAINT chk_funnel_step_measurement_status
        CHECK (measurement_status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_funnel_step_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS analytics_cohort_definition (
    cohort_id VARCHAR(64) PRIMARY KEY,
    cohort_name VARCHAR(255) NOT NULL,
    grain VARCHAR(128) NOT NULL,
    assignment_rule TEXT NOT NULL,
    reuse_window TEXT NOT NULL,
    value_definition TEXT NOT NULL,
    adoption_definition TEXT NOT NULL,
    owner VARCHAR(128) NOT NULL,
    measurement_status VARCHAR(32) NOT NULL DEFAULT 'NOT_MEASURED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_cohort_measurement_status
        CHECK (measurement_status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_cohort_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS analytics_annotation (
    annotation_id UUID PRIMARY KEY,
    annotation_type VARCHAR(64) NOT NULL,
    effective_at TIMESTAMPTZ NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    related_version VARCHAR(128),
    owner VARCHAR(128) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_annotation_type
        CHECK (annotation_type IN ('FEATURE_RELEASE', 'GUIDELINE_CHANGE', 'MODEL_CHANGE', 'PROMPT_CHANGE', 'POLICY_CHANGE', 'INCIDENT'))
);

CREATE TABLE IF NOT EXISTS analytics_failure_taxonomy (
    failure_code VARCHAR(64) PRIMARY KEY,
    failure_name VARCHAR(255) NOT NULL,
    funnel_step_id VARCHAR(64) REFERENCES analytics_funnel_step(step_id),
    severity VARCHAR(20) NOT NULL,
    root_cause_owner VARCHAR(128) NOT NULL,
    ticket_required BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_failure_taxonomy_severity CHECK (severity IN ('P0', 'P1', 'P2', 'P3')),
    CONSTRAINT chk_failure_taxonomy_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS analytics_experiment_design (
    experiment_id VARCHAR(64) PRIMARY KEY,
    hypothesis TEXT NOT NULL,
    unit_of_randomization VARCHAR(64) NOT NULL,
    contamination_risk TEXT NOT NULL,
    primary_metric_id VARCHAR(32) NOT NULL,
    secondary_metric_ids TEXT NOT NULL,
    guardrail_ids TEXT NOT NULL,
    pre_period TEXT NOT NULL,
    sample_size_plan TEXT NOT NULL,
    stopping_rule TEXT NOT NULL,
    safety_constraints TEXT NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'PLANNED',
    owner VARCHAR(128) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_experiment_status
        CHECK (status IN ('PLANNED', 'RUNNING', 'COMPLETED', 'CANCELLED', 'NOT_TESTED')),
    CONSTRAINT chk_experiment_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS analytics_finding (
    finding_id UUID PRIMARY KEY,
    analysis_artifact_id UUID,
    observed_value TEXT NOT NULL,
    population TEXT NOT NULL,
    period_start TIMESTAMPTZ NOT NULL,
    period_end TIMESTAMPTZ NOT NULL,
    effect_size TEXT NOT NULL,
    uncertainty TEXT NOT NULL,
    finding_text TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_finding_period CHECK (period_start < period_end)
);

CREATE TABLE IF NOT EXISTS analytics_recommendation (
    recommendation_id UUID PRIMARY KEY,
    finding_id UUID NOT NULL REFERENCES analytics_finding(finding_id),
    owner VARCHAR(128) NOT NULL,
    action TEXT NOT NULL,
    expected_effect TEXT NOT NULL,
    risk TEXT NOT NULL,
    success_metric_id VARCHAR(32) NOT NULL,
    reevaluation_date DATE NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'PLANNED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_recommendation_status
        CHECK (status IN ('PLANNED', 'ACCEPTED', 'REJECTED', 'IN_PROGRESS', 'DONE')),
    CONSTRAINT chk_recommendation_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS analytics_artifact_registry (
    artifact_id UUID PRIMARY KEY,
    artifact_type VARCHAR(64) NOT NULL,
    artifact_name VARCHAR(255) NOT NULL,
    query_version VARCHAR(128) NOT NULL,
    snapshot_ref TEXT NOT NULL,
    source_objects TEXT NOT NULL,
    owner VARCHAR(128) NOT NULL,
    measurement_status VARCHAR(32) NOT NULL DEFAULT 'NOT_MEASURED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_artifact_type
        CHECK (artifact_type IN ('METRIC_VALIDATION', 'FUNNEL_COHORT_NOTEBOOK', 'FAILURE_TAXONOMY_REPORT', 'EXPERIMENT_READOUT', 'DASHBOARD_ANNOTATION', 'DECISION_LOG')),
    CONSTRAINT chk_artifact_measurement_status
        CHECK (measurement_status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_artifact_timestamp_order CHECK (created_at <= updated_at)
);

CREATE OR REPLACE VIEW mart_funnel_step_metrics AS
SELECT
    step.step_id,
    step.step_order,
    step.event_name,
    step.measurement_status,
    NULL::bigint AS reached_count,
    NULL::numeric AS conversion_rate,
    NULL::numeric AS drop_off_rate,
    NULL::bigint AS median_time_to_next_seconds,
    NULL::bigint AS p95_time_to_next_seconds
FROM analytics_funnel_step step;

CREATE OR REPLACE VIEW mart_decision_review_design AS
SELECT
    'action_distribution' AS analysis_name,
    'decision' AS grain,
    'Use/Fix/Ignore distribution' AS description,
    'NOT_MEASURED' AS measurement_status
UNION ALL
SELECT
    'risk_level_by_action',
    'decision',
    'risk level x action cross tab',
    'NOT_MEASURED'
UNION ALL
SELECT
    'guideline_by_rationale',
    'decision',
    'guideline hit x rationale completeness',
    'NOT_MEASURED'
UNION ALL
SELECT
    'ai_recommendation_by_human_action',
    'analysis_run_finding',
    'AI recommendation x human action agreement or override',
    'NOT_MEASURED'
UNION ALL
SELECT
    'approval_time_by_reviewer_load',
    'approval',
    'approval time and reviewer load',
    'NOT_MEASURED'
UNION ALL
SELECT
    'fix_to_reverification_chain_length',
    'verification/change_chain',
    'Fix to reverification chain length',
    'NOT_MEASURED';

INSERT INTO analytics_analysis_framework (
    framework_id,
    framework_order,
    framework_name,
    description,
    causal_claim_allowed,
    required_evidence
)
VALUES
    ('descriptive', 1, 'DESCRIPTIVE', '현황과 분포를 설명한다.', false, 'grain, 기간, 분모/분자, 제외 기준'),
    ('diagnostic', 2, 'DIAGNOSTIC', '이탈, 실패, 병목의 원인을 탐색한다.', false, 'segment, taxonomy, root cause ticket'),
    ('comparative', 3, 'COMPARATIVE', 'baseline/candidate 또는 segment 차이를 비교한다.', false, 'baseline/candidate 기간, 변경 요인, mix control'),
    ('experimental', 4, 'EXPERIMENTAL', '사전 가설과 통제된 실험으로 효과를 평가한다.', true, 'hypothesis, control, sample/power, stopping rule')
ON CONFLICT (framework_id) DO UPDATE SET
    framework_order = EXCLUDED.framework_order,
    framework_name = EXCLUDED.framework_name,
    description = EXCLUDED.description,
    causal_claim_allowed = EXCLUDED.causal_claim_allowed,
    required_evidence = EXCLUDED.required_evidence;

INSERT INTO analytics_funnel_step (
    step_id,
    step_order,
    event_name,
    required,
    grain,
    time_to_next_metric,
    retry_policy,
    owner,
    measurement_status
)
VALUES
    ('verification_created', 1, 'verification_created', true, 'verification', 'created_to_context_ready_seconds', '최초 성공 단계 기준과 run 기준을 별도 제공한다.', 'DA', 'NOT_MEASURED'),
    ('context_ready', 2, 'context_ready', true, 'verification', 'context_ready_to_analysis_started_seconds', '최초 성공 단계 기준과 run 기준을 별도 제공한다.', 'DA', 'NOT_MEASURED'),
    ('analysis_started', 3, 'analysis_started', true, 'analysis_run_finding', 'analysis_duration_seconds', 'analysis run 재시도는 run 지표에만 추가 집계한다.', 'AI', 'NOT_MEASURED'),
    ('analysis_completed', 4, 'analysis_completed', true, 'analysis_run_finding', 'analysis_completed_to_decision_seconds', '최초 성공 analysis_completed 기준을 funnel에 사용한다.', 'AI', 'NOT_MEASURED'),
    ('decision_submitted', 5, 'decision_submitted', true, 'decision', 'decision_to_approval_requested_seconds', '중복 decision은 정책에 따라 제외하거나 version 처리한다.', 'DA', 'NOT_MEASURED'),
    ('approval_requested', 6, 'approval_requested', false, 'approval', 'approval_duration_seconds', '승인 필요 대상에만 적용한다.', 'QA', 'NOT_MEASURED'),
    ('approval_completed', 7, 'approval_completed', false, 'approval', NULL, '승인 필요 대상에만 적용한다.', 'QA', 'NOT_MEASURED')
ON CONFLICT (step_id) DO UPDATE SET
    step_order = EXCLUDED.step_order,
    event_name = EXCLUDED.event_name,
    required = EXCLUDED.required,
    grain = EXCLUDED.grain,
    time_to_next_metric = EXCLUDED.time_to_next_metric,
    retry_policy = EXCLUDED.retry_policy,
    owner = EXCLUDED.owner,
    measurement_status = EXCLUDED.measurement_status,
    updated_at = now();

INSERT INTO analytics_cohort_definition (
    cohort_id,
    cohort_name,
    grain,
    assignment_rule,
    reuse_window,
    value_definition,
    adoption_definition,
    owner,
    measurement_status
)
VALUES
    ('first_valid_verification_week', '첫 유효 verification 주차 cohort', 'user/team', '첫 유효 verification이 생성된 calendar week로 배정한다.', 'W1/W4 재사용: 해당 주에 유효 verification 생성', '반복 가치: 2회 이상 responsible decision completion', 'team adoption: 활성 팀 내 활성 사용자 비율', 'DA', 'NOT_MEASURED')
ON CONFLICT (cohort_id) DO UPDATE SET
    cohort_name = EXCLUDED.cohort_name,
    grain = EXCLUDED.grain,
    assignment_rule = EXCLUDED.assignment_rule,
    reuse_window = EXCLUDED.reuse_window,
    value_definition = EXCLUDED.value_definition,
    adoption_definition = EXCLUDED.adoption_definition,
    owner = EXCLUDED.owner,
    measurement_status = EXCLUDED.measurement_status,
    updated_at = now();

INSERT INTO analytics_failure_taxonomy (
    failure_code,
    failure_name,
    funnel_step_id,
    severity,
    root_cause_owner,
    ticket_required
)
VALUES
    ('FAILED', 'verification FAILED', NULL, 'P1', 'BE/AI', true),
    ('LONG_DRAFT', '장기 DRAFT', 'verification_created', 'P2', 'PM', true),
    ('LONG_READY', '장기 READY', 'context_ready', 'P2', 'BE', true),
    ('LONG_RUNNING', '장기 RUNNING', 'analysis_started', 'P1', 'BE/AI', true),
    ('DUPLICATE_SUBMISSION', '중복 submission', 'verification_created', 'P2', 'BE', true),
    ('UPLOAD_VALIDATION', 'upload validation failure', 'context_ready', 'P2', 'BE', true),
    ('PROVIDER_TIMEOUT', 'provider timeout', 'analysis_started', 'P1', 'AI', true),
    ('OUTPUT_INVALID', 'analysis output invalid', 'analysis_completed', 'P1', 'AI', true),
    ('POLICY_MISSING', 'policy missing', 'decision_submitted', 'P1', 'QA', true)
ON CONFLICT (failure_code) DO UPDATE SET
    failure_name = EXCLUDED.failure_name,
    funnel_step_id = EXCLUDED.funnel_step_id,
    severity = EXCLUDED.severity,
    root_cause_owner = EXCLUDED.root_cause_owner,
    ticket_required = EXCLUDED.ticket_required,
    updated_at = now();

INSERT INTO analytics_experiment_design (
    experiment_id,
    hypothesis,
    unit_of_randomization,
    contamination_risk,
    primary_metric_id,
    secondary_metric_ids,
    guardrail_ids,
    pre_period,
    sample_size_plan,
    stopping_rule,
    safety_constraints,
    status,
    owner
)
VALUES
    ('EXP-001', '근거 요약 UI가 DecisionLog 작성률·승인 시간을 개선하는가', '사용자 또는 팀', '팀 내 공유와 reviewer 학습 효과로 contamination 가능', 'M-001', 'M-002,M-004', 'G-001,G-002,G-003,G-004,G-005', '사전 등록 필요', '표본/검정력 사전 산정 필요', 'guardrail P0 위반 또는 사전 중단 규칙 충족 시 중단', '안전 기능은 무작위로 제거하지 않는다.', 'PLANNED', 'PM')
ON CONFLICT (experiment_id) DO UPDATE SET
    hypothesis = EXCLUDED.hypothesis,
    unit_of_randomization = EXCLUDED.unit_of_randomization,
    contamination_risk = EXCLUDED.contamination_risk,
    primary_metric_id = EXCLUDED.primary_metric_id,
    secondary_metric_ids = EXCLUDED.secondary_metric_ids,
    guardrail_ids = EXCLUDED.guardrail_ids,
    pre_period = EXCLUDED.pre_period,
    sample_size_plan = EXCLUDED.sample_size_plan,
    stopping_rule = EXCLUDED.stopping_rule,
    safety_constraints = EXCLUDED.safety_constraints,
    status = EXCLUDED.status,
    owner = EXCLUDED.owner,
    updated_at = now();
