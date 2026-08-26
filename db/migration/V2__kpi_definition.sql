CREATE TABLE IF NOT EXISTS analytics_metric_contract (
    metric_id VARCHAR(32) PRIMARY KEY,
    version VARCHAR(64) NOT NULL,
    business_owner VARCHAR(128) NOT NULL,
    data_owner VARCHAR(128) NOT NULL,
    description TEXT NOT NULL,
    grain VARCHAR(128) NOT NULL,
    formula TEXT NOT NULL,
    numerator_definition TEXT,
    denominator_definition TEXT,
    filters TEXT NOT NULL,
    dimensions TEXT NOT NULL,
    source_objects TEXT NOT NULL,
    freshness_sla TEXT NOT NULL,
    quality_tests TEXT NOT NULL,
    effective_date DATE NOT NULL,
    measurement_status VARCHAR(32) NOT NULL DEFAULT 'NOT_MEASURED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_metric_contract_measurement_status
        CHECK (measurement_status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_metric_contract_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS verification_data (
    id UUID PRIMARY KEY,
    input_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS work_context (
    id UUID PRIMARY KEY,
    verification_data_id UUID NOT NULL UNIQUE REFERENCES verification_data(id)
);

CREATE TABLE IF NOT EXISTS risk_assessment (
    id UUID PRIMARY KEY,
    verification_data_id UUID NOT NULL REFERENCES verification_data(id),
    severity VARCHAR(20),
    status VARCHAR(20) NOT NULL DEFAULT 'PLANNED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS decision_log (
    id UUID PRIMARY KEY,
    verification_data_id UUID NOT NULL UNIQUE REFERENCES verification_data(id),
    decision VARCHAR(20),
    rationale TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS approval (
    id UUID PRIMARY KEY,
    decision_log_id UUID NOT NULL UNIQUE REFERENCES decision_log(id),
    approved_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE verification_data ADD COLUMN IF NOT EXISTS input_type VARCHAR(20);
ALTER TABLE verification_data ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'DRAFT';
ALTER TABLE verification_data ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE verification_data ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE work_context ADD COLUMN IF NOT EXISTS verification_data_id UUID;

ALTER TABLE risk_assessment ADD COLUMN IF NOT EXISTS verification_data_id UUID;
ALTER TABLE risk_assessment ADD COLUMN IF NOT EXISTS severity VARCHAR(20);
ALTER TABLE risk_assessment ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'PLANNED';
ALTER TABLE risk_assessment ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE risk_assessment ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE decision_log ADD COLUMN IF NOT EXISTS verification_data_id UUID;
ALTER TABLE decision_log ADD COLUMN IF NOT EXISTS decision VARCHAR(20);
ALTER TABLE decision_log ADD COLUMN IF NOT EXISTS rationale TEXT;
ALTER TABLE decision_log ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE approval ADD COLUMN IF NOT EXISTS decision_log_id UUID;
ALTER TABLE approval ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ NOT NULL DEFAULT now();

CREATE TABLE IF NOT EXISTS analytics_guardrail_metric (
    guardrail_id VARCHAR(32) PRIMARY KEY,
    guardrail_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL,
    halt_release_on_violation BOOLEAN NOT NULL DEFAULT true,
    source_objects TEXT NOT NULL,
    owner VARCHAR(128) NOT NULL,
    measurement_status VARCHAR(32) NOT NULL DEFAULT 'NOT_MEASURED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_guardrail_severity CHECK (severity IN ('P0', 'P1', 'P2', 'P3')),
    CONSTRAINT chk_guardrail_measurement_status
        CHECK (measurement_status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_guardrail_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS analytics_operational_metric (
    metric_id VARCHAR(32) PRIMARY KEY,
    metric_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    grain VARCHAR(128) NOT NULL,
    source_objects TEXT NOT NULL,
    owner VARCHAR(128) NOT NULL,
    measurement_status VARCHAR(32) NOT NULL DEFAULT 'NOT_MEASURED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_operational_metric_measurement_status
        CHECK (measurement_status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_operational_metric_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS analytics_metric_validation_test (
    test_id VARCHAR(64) PRIMARY KEY,
    metric_id VARCHAR(32) NOT NULL,
    test_name VARCHAR(255) NOT NULL,
    test_sql TEXT,
    expected_result TEXT NOT NULL,
    owner VARCHAR(128) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'NOT_TESTED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_metric_validation_status
        CHECK (status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_metric_validation_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS analytics_metric_exclusion_policy (
    id UUID PRIMARY KEY,
    metric_id VARCHAR(32) NOT NULL,
    version VARCHAR(64) NOT NULL,
    exclusion_name VARCHAR(128) NOT NULL,
    exclusion_rule TEXT NOT NULL,
    applies BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_metric_exclusion_policy UNIQUE (metric_id, version, exclusion_name)
);

CREATE OR REPLACE VIEW mart_responsible_decision_completion AS
SELECT
    v.id AS verification_id,
    v.input_type,
    v.status,
    (w.id IS NOT NULL) AS has_required_context,
    (r.id IS NOT NULL) AS has_risk_evidence,
    (d.id IS NOT NULL AND d.rationale IS NOT NULL AND length(trim(d.rationale)) > 0) AS has_human_decision,
    (a.id IS NOT NULL OR r.severity IS NULL OR r.severity NOT IN ('S1', 'S2', 'HIGH', 'CRITICAL')) AS approval_requirement_met,
    (
        w.id IS NOT NULL
        AND r.id IS NOT NULL
        AND d.id IS NOT NULL
        AND d.rationale IS NOT NULL
        AND length(trim(d.rationale)) > 0
        AND (a.id IS NOT NULL OR r.severity IS NULL OR r.severity NOT IN ('S1', 'S2', 'HIGH', 'CRITICAL'))
    ) AS responsible_decision_completed
FROM verification_data v
LEFT JOIN work_context w ON w.verification_data_id = v.id
LEFT JOIN risk_assessment r ON r.verification_data_id = v.id
LEFT JOIN decision_log d ON d.verification_data_id = v.id
LEFT JOIN approval a ON a.decision_log_id = d.id;

INSERT INTO analytics_metric_contract (
    metric_id,
    version,
    business_owner,
    data_owner,
    description,
    grain,
    formula,
    numerator_definition,
    denominator_definition,
    filters,
    dimensions,
    source_objects,
    freshness_sla,
    quality_tests,
    effective_date,
    measurement_status
)
VALUES
    ('RDC', 'v0', 'PM', 'DA', 'Responsible Decision Completion: 필수 컨텍스트·근거·인간 decision이 모두 존재하는 verification 수. 승인 필요 대상은 approval까지 있어야 완료로 본다.', 'verification', 'count(responsible_decision_completed = true)', 'responsible_decision_completed verification', '유효 verification', '자동 승인 결과 제외, 테스트·시드·삭제·취소 제외', 'team, project, input_type, risk_level, reviewer_required, guideline_version, model_prompt_version, calendar_period', 'mart_responsible_decision_completion', 'daily', 'not_null, relationships, no_auto_approval, no_raw_code', CURRENT_DATE, 'NOT_MEASURED'),
    ('M-001', 'v0', 'PM', 'DA', 'DecisionLog 작성률', 'verification', 'valid_decision_log_count / decision_required_done_count', '유효 action과 rationale 정책을 충족한 DecisionLog 보유 대상', 'decision이 요구되는 DONE 대상', '시스템/테스트, 중복·철회된 decision 제외', 'team, project, input_type, risk_level, decision_action, guideline_version, model_prompt_version, calendar_period', 'decision_log, verification_data, mart_daily_product_metrics', 'daily', 'numerator_le_denominator, not_null, duplicate_grain, source_to_mart_count', CURRENT_DATE, 'NOT_MEASURED'),
    ('M-002', 'v0', '리뷰어 리드', 'DA', '승인 시간', 'approval_request', 'approved_or_rejected_at - requested_at', 'approval duration seconds', '승인 완료 건', '취소, 데이터 오류, reviewer 부재 정책 제외', 'team, risk_level, input_type, reviewer_required, calendar_period', 'approval, decision_log, fct_approval', 'daily', 'null_timestamp, timezone, late_event, duration_non_negative', CURRENT_DATE, 'NOT_MEASURED'),
    ('M-003', 'v0', 'PM', 'DA', '재작업률', 'verification/change_chain', 'rework_after_fix_count / completed_decision_target_count', 'Fix 이후 수정·재업로드·재검증이 연결된 완료 건', '완료된 decision 대상', '테스트, 취소, 중복 생성 제외', 'team, project, input_type, risk_level, decision_action, calendar_period', 'decision_log, verification_status_transition, int_rework_cycle', 'daily', 'numerator_le_denominator, duplicate_grain, deterministic_fixture', CURRENT_DATE, 'NOT_MEASURED'),
    ('M-004', 'v0', 'PM', 'DA', '검증 완료율', 'verification', 'done_verification_count / valid_started_verification_count', '정책상 완료 상태(DONE) 건', '유효 생성 건', '테스트, 명시 취소, 중복 생성 제외', 'team, project, input_type, calendar_period', 'verification_data, fct_verification, mart_daily_product_metrics', 'daily', 'numerator_le_denominator, accepted_values, status_order, source_to_mart_count', CURRENT_DATE, 'NOT_MEASURED'),
    ('M-005', 'v0', 'QA/컴플라이언스', 'QA', '감사 수작업 시간', 'standard_audit_task', 'audit_evidence_package_active_time compared with baseline', 'audit 시작→필수 evidence package 완성까지 active time', 'baseline audit task active time', '표준 audit task 외 작업 제외, 동일 범위 표본만 포함', 'team, project, risk_level, reviewer_required, calendar_period', 'audit events, int_audit_completeness', 'release', 'not_null, fixture_match, baseline_candidate_comparison', CURRENT_DATE, 'NOT_MEASURED')
ON CONFLICT (metric_id) DO UPDATE SET
    version = EXCLUDED.version,
    business_owner = EXCLUDED.business_owner,
    data_owner = EXCLUDED.data_owner,
    description = EXCLUDED.description,
    grain = EXCLUDED.grain,
    formula = EXCLUDED.formula,
    numerator_definition = EXCLUDED.numerator_definition,
    denominator_definition = EXCLUDED.denominator_definition,
    filters = EXCLUDED.filters,
    dimensions = EXCLUDED.dimensions,
    source_objects = EXCLUDED.source_objects,
    freshness_sla = EXCLUDED.freshness_sla,
    quality_tests = EXCLUDED.quality_tests,
    effective_date = EXCLUDED.effective_date,
    measurement_status = EXCLUDED.measurement_status,
    updated_at = now();

INSERT INTO analytics_guardrail_metric (
    guardrail_id,
    guardrail_name,
    description,
    severity,
    halt_release_on_violation,
    source_objects,
    owner,
    measurement_status
)
VALUES
    ('G-001', 'critical risk 누락률', 'critical risk가 누락되는 비율을 감시한다.', 'P0', true, 'risk_assessment, decision_log', 'QA', 'NOT_MEASURED'),
    ('G-002', '승인 없이 Use 처리된 고위험 건', '고위험 건이 approval 없이 USE 처리되면 release 확대를 중단한다.', 'P0', true, 'risk_assessment, decision_log, approval', 'QA', 'NOT_MEASURED'),
    ('G-003', 'secret/PII·교차 팀 데이터 노출', '민감정보 또는 교차 팀 데이터 노출 여부를 감시한다.', 'P0', true, 'data_event, data_quality_result', 'SECURITY', 'NOT_MEASURED'),
    ('G-004', 'AI 오류/timeout 및 장기 RUNNING', 'AI 오류, timeout, 장기 RUNNING 상태를 감시한다.', 'P1', true, 'risk_assessment, verification_data', 'BE/AI', 'NOT_MEASURED'),
    ('G-005', 'reviewer override와 rationale missing', 'reviewer override 또는 rationale 누락을 감시한다.', 'P1', true, 'decision_log, approval', 'QA', 'NOT_MEASURED')
ON CONFLICT (guardrail_id) DO UPDATE SET
    guardrail_name = EXCLUDED.guardrail_name,
    description = EXCLUDED.description,
    severity = EXCLUDED.severity,
    halt_release_on_violation = EXCLUDED.halt_release_on_violation,
    source_objects = EXCLUDED.source_objects,
    owner = EXCLUDED.owner,
    measurement_status = EXCLUDED.measurement_status,
    updated_at = now();

INSERT INTO analytics_operational_metric (
    metric_id,
    metric_name,
    description,
    grain,
    source_objects,
    owner,
    measurement_status
)
VALUES
    ('OP-001', 'created→READY', 'created에서 READY까지 걸린 시간', 'verification', 'verification_status_transition', 'BE', 'NOT_MEASURED'),
    ('OP-002', 'READY→RUNNING', 'READY에서 RUNNING까지 걸린 시간', 'verification', 'verification_status_transition', 'BE', 'NOT_MEASURED'),
    ('OP-003', 'RUNNING→DONE/FAILED', 'RUNNING에서 종료 상태까지 걸린 시간', 'verification', 'verification_status_transition', 'BE', 'NOT_MEASURED'),
    ('OP-004', 'analysis p95', 'AI 분석 p95 latency', 'analysis_run', 'risk_assessment', 'AI', 'NOT_MEASURED'),
    ('OP-005', 'retry', '재시도 횟수와 비율', 'run', 'pipeline_run, risk_assessment', 'DE', 'NOT_MEASURED'),
    ('OP-006', 'duplicate', '중복 이벤트 또는 중복 grain 비율', 'event', 'data_event, data_quality_result', 'DE', 'NOT_MEASURED'),
    ('OP-007', 'event freshness', 'event freshness lag', 'event', 'data_event', 'DE', 'NOT_MEASURED'),
    ('OP-008', 'guideline coverage', 'guideline 적용 coverage', 'verification', 'team_guideline, decision_log', 'DA', 'NOT_MEASURED'),
    ('OP-009', 'finding evidence coverage', 'finding evidence coverage', 'finding', 'risk_assessment', 'AI', 'NOT_MEASURED'),
    ('OP-010', 'cost per analysis', 'analysis당 비용', 'analysis_run', 'risk_assessment, cost event', 'AI', 'NOT_MEASURED')
ON CONFLICT (metric_id) DO UPDATE SET
    metric_name = EXCLUDED.metric_name,
    description = EXCLUDED.description,
    grain = EXCLUDED.grain,
    source_objects = EXCLUDED.source_objects,
    owner = EXCLUDED.owner,
    measurement_status = EXCLUDED.measurement_status,
    updated_at = now();

INSERT INTO analytics_metric_validation_test (
    test_id,
    metric_id,
    test_name,
    expected_result,
    owner,
    status
)
VALUES
    ('KPI-T-001', 'M-001', '분자≤분모', 'numerator <= denominator', 'DA', 'NOT_TESTED'),
    ('KPI-T-002', 'M-002', 'NULL timestamp', 'required timestamps are not null for included rows', 'DA', 'NOT_TESTED'),
    ('KPI-T-003', 'M-003', '중복 grain', 'one row per verification/change chain grain', 'DA', 'NOT_TESTED'),
    ('KPI-T-004', 'M-004', '기간 경계', 'metric windows include/exclude exact boundaries consistently', 'DA', 'NOT_TESTED'),
    ('KPI-T-005', 'M-004', 'timezone', 'UTC storage and business timezone display match fixture', 'DA', 'NOT_TESTED'),
    ('KPI-T-006', 'M-001', 'late event', 'late events are attributed by defined policy', 'DE', 'NOT_TESTED'),
    ('KPI-T-007', 'M-004', 'status 역행', 'invalid status transitions are rejected or excluded', 'BE', 'NOT_TESTED'),
    ('KPI-T-008', 'M-004', 'source↔mart count', 'source and mart reconciliation difference is 0', 'DE', 'NOT_TESTED'),
    ('KPI-T-009', 'RDC', 'hand-calculated fixture', 'small fixture output matches expected responsible completion', 'QA', 'NOT_TESTED')
ON CONFLICT (test_id) DO UPDATE SET
    metric_id = EXCLUDED.metric_id,
    test_name = EXCLUDED.test_name,
    expected_result = EXCLUDED.expected_result,
    owner = EXCLUDED.owner,
    status = EXCLUDED.status,
    updated_at = now();

INSERT INTO analytics_metric_exclusion_policy (
    id,
    metric_id,
    version,
    exclusion_name,
    exclusion_rule,
    applies
)
VALUES
    ('10000000-0000-0000-0000-000000000001', 'M-001', 'v0', 'system_test_seed_deleted', '테스트·시드·삭제된 계정 제외', true),
    ('10000000-0000-0000-0000-000000000002', 'M-001', 'v0', 'cancelled_or_retracted_decision', '명시적 취소, 중복·철회 decision 제외', true),
    ('10000000-0000-0000-0000-000000000003', 'M-002', 'v0', 'reviewer_absence_policy', 'reviewer 부재 정책에 해당하는 approval 제외', true),
    ('10000000-0000-0000-0000-000000000004', 'M-003', 'v0', 'fix_not_failure', 'Fix 자체를 실패로 간주하지 않고 불필요 반복만 rework로 구분', true),
    ('10000000-0000-0000-0000-000000000005', 'M-004', 'v0', 'cancelled_duplicate_creation', '명시 취소와 중복 생성 제외', true),
    ('10000000-0000-0000-0000-000000000006', 'M-005', 'v0', 'non_standard_audit_task', '표준 audit task 외 작업 제외', true)
ON CONFLICT (metric_id, version, exclusion_name) DO UPDATE SET
    exclusion_rule = EXCLUDED.exclusion_rule,
    applies = EXCLUDED.applies;
