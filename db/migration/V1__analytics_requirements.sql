CREATE TABLE IF NOT EXISTS analytics_grain (
    grain_id VARCHAR(64) PRIMARY KEY,
    description TEXT NOT NULL,
    retry_policy TEXT,
    owner VARCHAR(128) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_analytics_grain_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS analytics_segment (
    segment_id VARCHAR(64) PRIMARY KEY,
    segment_name VARCHAR(128) NOT NULL,
    allowed_values TEXT,
    privacy_threshold INTEGER NOT NULL DEFAULT 10,
    source_status VARCHAR(32) NOT NULL,
    owner VARCHAR(128) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_analytics_segment_privacy_threshold CHECK (privacy_threshold >= 0),
    CONSTRAINT chk_analytics_segment_source_status
        CHECK (source_status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_analytics_segment_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS analytics_business_question (
    bq_id VARCHAR(16) PRIMARY KEY,
    question TEXT NOT NULL,
    decision_owner VARCHAR(128) NOT NULL,
    cadence VARCHAR(64) NOT NULL,
    primary_grain_id VARCHAR(64) NOT NULL REFERENCES analytics_grain(grain_id),
    threshold_policy TEXT NOT NULL,
    follow_up_action TEXT NOT NULL,
    measurement_status VARCHAR(32) NOT NULL DEFAULT 'NOT_MEASURED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_analytics_bq_measurement_status
        CHECK (measurement_status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_analytics_bq_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS analytics_metric_definition (
    metric_id VARCHAR(16) PRIMARY KEY,
    metric_name VARCHAR(255) NOT NULL,
    business_question_id VARCHAR(16) REFERENCES analytics_business_question(bq_id),
    grain_id VARCHAR(64) NOT NULL REFERENCES analytics_grain(grain_id),
    numerator_definition TEXT NOT NULL,
    denominator_definition TEXT NOT NULL,
    exclusion_policy TEXT NOT NULL,
    timezone_policy TEXT NOT NULL,
    late_event_policy TEXT NOT NULL,
    owner VARCHAR(128) NOT NULL,
    source_status VARCHAR(32) NOT NULL,
    measurement_status VARCHAR(32) NOT NULL DEFAULT 'NOT_MEASURED',
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_analytics_metric_source_status
        CHECK (source_status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_analytics_metric_measurement_status
        CHECK (measurement_status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_analytics_metric_effective_period
        CHECK (effective_to IS NULL OR effective_from < effective_to),
    CONSTRAINT chk_analytics_metric_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS analytics_requirement (
    requirement_id VARCHAR(16) PRIMARY KEY,
    requirement_text TEXT NOT NULL,
    owner VARCHAR(128) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'PLANNED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_analytics_requirement_status
        CHECK (status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_analytics_requirement_timestamp_order CHECK (created_at <= updated_at)
);

CREATE TABLE IF NOT EXISTS analytics_requirement_trace (
    id UUID PRIMARY KEY,
    requirement_id VARCHAR(16) NOT NULL REFERENCES analytics_requirement(requirement_id),
    business_question_id VARCHAR(16) REFERENCES analytics_business_question(bq_id),
    metric_id VARCHAR(16) REFERENCES analytics_metric_definition(metric_id),
    source_artifact VARCHAR(255) NOT NULL,
    target_artifact VARCHAR(255) NOT NULL,
    trace_status VARCHAR(32) NOT NULL DEFAULT 'PLANNED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_analytics_trace_status
        CHECK (trace_status IN ('IMPLEMENTED', 'PLANNED', 'NOT_TESTED', 'NOT_MEASURED')),
    CONSTRAINT chk_analytics_trace_target_present
        CHECK (business_question_id IS NOT NULL OR metric_id IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS analytics_metric_version (
    id UUID PRIMARY KEY,
    metric_id VARCHAR(16) NOT NULL REFERENCES analytics_metric_definition(metric_id),
    version VARCHAR(64) NOT NULL,
    effective_date DATE NOT NULL,
    change_reason TEXT NOT NULL,
    backfill_impact TEXT NOT NULL,
    approved_by VARCHAR(128),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_analytics_metric_version UNIQUE (metric_id, version)
);

CREATE INDEX IF NOT EXISTS idx_analytics_bq_owner
    ON analytics_business_question(decision_owner, cadence);

CREATE INDEX IF NOT EXISTS idx_analytics_metric_bq
    ON analytics_metric_definition(business_question_id, owner);

CREATE INDEX IF NOT EXISTS idx_analytics_requirement_trace_requirement
    ON analytics_requirement_trace(requirement_id, trace_status);

INSERT INTO analytics_grain (grain_id, description, retry_policy, owner)
VALUES
    ('verification', '제품 funnel 기본 grain. 한 verification 단위로 생성부터 완료까지 추적한다.', '동일 verification 재시도와 재분석은 별도 status event 또는 analysis run으로 분리한다.', 'DA'),
    ('status_event', '라이프사이클 지연 분석용 상태 이벤트 grain.', '동일 status event id는 중복 집계하지 않는다.', 'DA'),
    ('analysis_run_finding', 'AI 품질·운영 분석용 analysis run과 finding grain.', 'analysis_run_id와 finding_id 기준으로 중복 제거한다.', 'AI'),
    ('decision', 'Use/Fix/Ignore와 rationale 분석 grain.', 'verification당 활성 decision 정책을 따른다.', 'DA'),
    ('approval', 'reviewer 판단과 승인 시간 분석 grain.', 'approval_id 기준으로 중복 제거한다.', 'DA'),
    ('team_day_week', '운영 추세 분석용 team/day/week grain.', 'timezone과 cohort 기준을 metric 정의에 고정한다.', 'DA')
ON CONFLICT (grain_id) DO UPDATE SET
    description = EXCLUDED.description,
    retry_policy = EXCLUDED.retry_policy,
    owner = EXCLUDED.owner,
    updated_at = now();

INSERT INTO analytics_segment (segment_id, segment_name, allowed_values, privacy_threshold, source_status, owner)
VALUES
    ('team', 'team', NULL, 10, 'PLANNED', 'DA'),
    ('project', 'project', NULL, 10, 'PLANNED', 'DA'),
    ('input_type', 'input_type', 'PASTE,FILE,COMMIT,PR', 0, 'IMPLEMENTED', 'DA'),
    ('language_framework', 'language/framework', NULL, 10, 'PLANNED', 'DA'),
    ('work_type', 'work_type', NULL, 10, 'PLANNED', 'DA'),
    ('risk_level', 'risk_level', NULL, 10, 'PLANNED', 'AI'),
    ('decision_action', 'decision_action', 'USE,FIX,IGNORE', 0, 'PLANNED', 'DA'),
    ('reviewer_required', 'reviewer_required', 'true,false', 10, 'PLANNED', 'QA'),
    ('guideline_version', 'guideline_version', NULL, 10, 'PLANNED', 'DA'),
    ('model_prompt_version', 'model/prompt version', NULL, 10, 'PLANNED', 'AI'),
    ('user_cohort', 'new/repeat user', 'NEW,REPEAT', 10, 'PLANNED', 'DA'),
    ('calendar_period', 'date/week', NULL, 0, 'IMPLEMENTED', 'DA')
ON CONFLICT (segment_id) DO UPDATE SET
    segment_name = EXCLUDED.segment_name,
    allowed_values = EXCLUDED.allowed_values,
    privacy_threshold = EXCLUDED.privacy_threshold,
    source_status = EXCLUDED.source_status,
    owner = EXCLUDED.owner,
    updated_at = now();

INSERT INTO analytics_business_question (
    bq_id,
    question,
    decision_owner,
    cadence,
    primary_grain_id,
    threshold_policy,
    follow_up_action,
    measurement_status
)
VALUES
    ('BQ-001', '입력 후 판단 가능한 상태까지 얼마나 걸리는가?', 'PM', 'weekly', 'verification', 'baseline 확정 후 threshold 설정', 'UX/flow 개선 또는 BE 병목 개선', 'NOT_MEASURED'),
    ('BQ-002', 'AI 근거가 제공되면 DecisionLog 작성률이 증가하는가?', 'PM', 'weekly', 'decision', 'baseline/candidate 기간 비교', 'AI 근거 UI와 DecisionLog 작성 흐름 개선', 'NOT_MEASURED'),
    ('BQ-003', '팀/입력 유형/위험 수준별 승인 시간이 어떻게 다른가?', '리뷰어 리드', 'weekly', 'approval', 'privacy threshold 이상 segment만 publish', 'reviewer 배분과 guideline 보강', 'NOT_MEASURED'),
    ('BQ-004', 'Fix 판단은 실제 재작업과 재검증으로 이어지는가?', 'PM', 'weekly', 'verification', 'Fix 후 재검증 정의 고정', 'Fix workflow와 재검증 유도 개선', 'NOT_MEASURED'),
    ('BQ-005', '시니어 검토가 필요한 케이스를 적절히 집중시키는가?', '리뷰어 리드', 'weekly', 'approval', 'risk/reviewer_required segment 기준', 'review rule 조정', 'NOT_MEASURED'),
    ('BQ-006', 'guideline 적용 여부와 판단 일관성의 관계는 무엇인가?', '리뷰어 리드', 'monthly', 'decision', 'guideline version별 최소 표본 충족', 'guideline 보강과 교육', 'NOT_MEASURED'),
    ('BQ-007', '실패·포기·장기 RUNNING의 주요 원인은 무엇인가?', 'BE/AI', 'weekly', 'status_event', 'RUNNING aging threshold 별도 정의', 'timeout/retry/error handling 개선', 'NOT_MEASURED'),
    ('BQ-008', '감사 준비 시 필요한 근거가 자동으로 연결되는가?', 'QA/컴플라이언스', 'release', 'verification', '필수 evidence coverage 기준', 'release gate와 audit control 개선', 'NOT_MEASURED'),
    ('BQ-009', 'AI finding과 인간 override가 반복되는 영역은 무엇인가?', 'BE/AI', 'monthly', 'analysis_run_finding', 'finding taxonomy와 decision mismatch 기준', 'AI prompt/model/guideline 개선', 'NOT_MEASURED'),
    ('BQ-010', '제품 지표 M-001~M-005가 baseline 대비 개선되는가?', 'PM', 'release', 'team_day_week', 'baseline/candidate 기간과 변경 요인 기록', 'MVP 다음 기능 우선순위 결정', 'NOT_MEASURED')
ON CONFLICT (bq_id) DO UPDATE SET
    question = EXCLUDED.question,
    decision_owner = EXCLUDED.decision_owner,
    cadence = EXCLUDED.cadence,
    primary_grain_id = EXCLUDED.primary_grain_id,
    threshold_policy = EXCLUDED.threshold_policy,
    follow_up_action = EXCLUDED.follow_up_action,
    measurement_status = EXCLUDED.measurement_status,
    updated_at = now();

INSERT INTO analytics_metric_definition (
    metric_id,
    metric_name,
    business_question_id,
    grain_id,
    numerator_definition,
    denominator_definition,
    exclusion_policy,
    timezone_policy,
    late_event_policy,
    owner,
    source_status,
    measurement_status
)
VALUES
    ('M-001', 'DecisionLog 작성률', 'BQ-002', 'decision', '유효 decision log가 있는 완료 대상', 'decision 대상', '테스트/취소/무효 verification 제외', 'UTC 저장, 사용자 timezone 표시', 'late decision은 effective date 기준 재계산', 'DA', 'PLANNED', 'NOT_MEASURED'),
    ('M-002', '승인 시간', 'BQ-003', 'approval', 'approval completed - approval requested', '승인 완료 건', 'approval 미요청/취소 제외', 'UTC 저장, 사용자 timezone 표시', 'late approval은 승인일 파티션 backfill', 'DA', 'PLANNED', 'NOT_MEASURED'),
    ('M-003', '재작업률', 'BQ-004', 'verification', 'Fix 후 재검증 또는 정의된 rework', '완료 대상', '테스트/취소/무효 verification 제외', 'UTC 저장, 사용자 timezone 표시', 'late rework event는 원 verification cohort로 귀속', 'DA', 'PLANNED', 'NOT_MEASURED'),
    ('M-004', '검증 완료율', 'BQ-010', 'verification', 'DONE verification', '유효 시작 verification', '테스트/취소/무효 verification 제외', 'UTC 저장, 사용자 timezone 표시', 'late DONE event는 상태 전이일 기준 재계산', 'DA', 'IMPLEMENTED', 'NOT_MEASURED'),
    ('M-005', '감사 수작업 시간', 'BQ-008', 'verification', '표준 audit task 소요시간 baseline 대비 절감', 'baseline audit task 소요시간', '표준 audit task 외 작업 제외', 'UTC 저장, 사용자 timezone 표시', 'late audit event는 audit period backfill', 'QA', 'PLANNED', 'NOT_MEASURED')
ON CONFLICT (metric_id) DO UPDATE SET
    metric_name = EXCLUDED.metric_name,
    business_question_id = EXCLUDED.business_question_id,
    grain_id = EXCLUDED.grain_id,
    numerator_definition = EXCLUDED.numerator_definition,
    denominator_definition = EXCLUDED.denominator_definition,
    exclusion_policy = EXCLUDED.exclusion_policy,
    timezone_policy = EXCLUDED.timezone_policy,
    late_event_policy = EXCLUDED.late_event_policy,
    owner = EXCLUDED.owner,
    source_status = EXCLUDED.source_status,
    measurement_status = EXCLUDED.measurement_status,
    updated_at = now();

INSERT INTO analytics_requirement (requirement_id, requirement_text, owner, status)
VALUES
    ('AR-001', 'M-001~M-005 정의와 SQL owner 지정', 'DA', 'PLANNED'),
    ('AR-002', 'event coverage·중복·지연을 함께 보고', 'DE', 'PLANNED'),
    ('AR-003', 'funnel 이탈과 소요시간을 단계별 측정', 'DA', 'PLANNED'),
    ('AR-004', 'cohort는 첫 verification 주차 기준', 'DA', 'PLANNED'),
    ('AR-005', '세그먼트 최소 표본과 privacy threshold 적용', 'DA', 'PLANNED'),
    ('AR-006', 'baseline/candidate 기간과 변경 요인 기록', 'PM', 'PLANNED'),
    ('AR-007', 'finding은 권고와 인간 결정의 불일치 분석', 'AI', 'PLANNED'),
    ('AR-008', '실패·취소·테스트 계정을 분모 규칙에 따라 처리', 'DA', 'PLANNED'),
    ('AR-009', 'dashboard 수치에서 source/definition으로 drill-through', 'DA', 'PLANNED'),
    ('AR-010', 'metric 변경은 version·effective date·backfill 영향 기록', 'DA', 'PLANNED')
ON CONFLICT (requirement_id) DO UPDATE SET
    requirement_text = EXCLUDED.requirement_text,
    owner = EXCLUDED.owner,
    status = EXCLUDED.status,
    updated_at = now();

INSERT INTO analytics_metric_version (
    id,
    metric_id,
    version,
    effective_date,
    change_reason,
    backfill_impact,
    approved_by
)
VALUES
    ('00000000-0000-0000-0000-000000000001', 'M-001', 'v0', CURRENT_DATE, 'Initial DA-01 definition', 'No backfill before source events exist', NULL),
    ('00000000-0000-0000-0000-000000000002', 'M-002', 'v0', CURRENT_DATE, 'Initial DA-01 definition', 'No backfill before approval events exist', NULL),
    ('00000000-0000-0000-0000-000000000003', 'M-003', 'v0', CURRENT_DATE, 'Initial DA-01 definition', 'No backfill before rework events exist', NULL),
    ('00000000-0000-0000-0000-000000000004', 'M-004', 'v0', CURRENT_DATE, 'Initial DA-01 definition', 'Can be backfilled from verification status once available', NULL),
    ('00000000-0000-0000-0000-000000000005', 'M-005', 'v0', CURRENT_DATE, 'Initial DA-01 definition', 'No backfill before audit task events exist', NULL)
ON CONFLICT (metric_id, version) DO UPDATE SET
    effective_date = EXCLUDED.effective_date,
    change_reason = EXCLUDED.change_reason,
    backfill_impact = EXCLUDED.backfill_impact,
    approved_by = EXCLUDED.approved_by;
