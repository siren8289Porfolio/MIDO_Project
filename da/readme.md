# MIDO — Responsible Decision Product Analytics

> **AI 코드 검증 과정의 `Verification → Risk Evidence → Human Decision → Approval` 흐름을 데이터로 구조화하고, DecisionLog 작성률·승인시간·재작업률·검증완료율을 추적하여 AI 코드 검토 프로세스의 품질과 운영 병목을 분석하는 Product Data Analytics 프로젝트**

---

# 1. Project Overview

MIDO는 AI가 생성하거나 수정한 코드를 사람이 그대로 사용하는 것이 아니라, 코드와 Dependency를 분석하고 위험 근거를 확인한 뒤 사람이 최종적으로 `USE / FIX / IGNORE`를 결정하도록 지원하는 검증 시스템입니다.

DA 영역에서는 단순한 Dashboard 제작보다 다음 질문에 답할 수 있는 분석 구조를 만드는 데 집중했습니다.

```text
Code / File / Commit / PR
          ↓
     Verification
          ↓
      Work Context
          ↓
     Risk Analysis
          ↓
    Risk Evidence
          ↓
 Human Decision
 USE / FIX / IGNORE
          ↓
       Approval
          ↓
    Decision Log
          ↓
 Product Analytics
```

핵심 분석 목표는 다음과 같습니다.

```text
검증은 얼마나 시작되는가?
        ↓
얼마나 완료되는가?
        ↓
사람의 판단 기록은 남는가?
        ↓
승인에는 얼마나 걸리는가?
        ↓
FIX 이후 재작업은 얼마나 발생하는가?
        ↓
어느 단계에서 병목과 실패가 발생하는가?
```

이를 위해 MIDO에서는 **Business Question → Metric Contract → Event Contract → Analytical Model → Serving API → Dashboard**를 하나의 흐름으로 연결했습니다.

---

# 2. DA 관련 파일 위치

MIDO의 DA 구현은 크게 다섯 영역에 나뉩니다.

```text
MIDO_Project/
│
├── da/                                      # DA 문서 / 포트폴리오
│
├── spring/src/main/resources/db/migration/ # Analytics SQL / KPI / Event / Mart
│
├── spring/src/main/verification/da/        # DA Backend API
│
├── spring/src/test/verification/da/        # DA API Test
│
└── web/src/                                # DA Dashboard
```

## 2.1 DA 문서

```text
da/
├── DA-01-data-performance-guide.md
├── DA-02-db-efficiency-summary.md
├── DA-03-efficiency-summary.md
├── DA-04-document-index.md
├── DA-05-portfolio-case-study.md
│
└── assets/
    └── da-05-dashboard-sample.png
```

### `DA-01-data-performance-guide.md`

역할:

* OLTP / OLAP 분리 기준
* 데이터 모델링
* API / Query 성능지표
* ETL / CDC 확장 방향
* 데이터 품질
* 모니터링
* 대용량 처리 전략

MIDO의 데이터·성능 영역을 전체적으로 설명하는 상세 가이드입니다.

---

### `DA-02-db-efficiency-summary.md`

역할:

* PostgreSQL DB 구조 분석
* LOB 분리
* Projection
* Pagination
* Index 설계
* `EXPLAIN ANALYZE`
* Summary / Analytics DB 설계

특히 실제 적용된:

```text
idx_verification_status_created
idx_verification_input_type_created
uq_work_context_verification
idx_uploaded_file_verification_uploaded
idx_manual_input_verification
```

등의 Index 설계 근거를 설명합니다.

---

### `DA-03-efficiency-summary.md`

역할:

```text
Backend Efficiency
+
Database Efficiency
+
Analytics Efficiency
```

를 한 번에 볼 수 있도록 정리한 통합 문서입니다.

---

### `DA-04-document-index.md`

DA 관련 코드가 실제 Repository 어디에 존재하는지 연결하는 문서입니다.

```text
DA Document
     ↓
DB Migration
     ↓
Spring DA Code
     ↓
Test
     ↓
Next.js Dashboard
```

현재 Repository를 탐색할 때 가장 먼저 보는 DA Index 문서입니다.

---

### `DA-05-portfolio-case-study.md`

DA 포트폴리오용 Case Study입니다.

구조:

```text
Project Summary
      ↓
Business Problem
      ↓
Data & Tech Stack
      ↓
Data Cleaning
      ↓
Analysis
      ↓
Dashboard
      ↓
Insight
      ↓
Recommendation
```

Dashboard 캡처도 다음 위치에 존재합니다.

```text
da/assets/da-05-dashboard-sample.png
```

---

# 3. Analytics SQL 위치

실제 분석 계약과 데이터 구조는 Flyway Migration으로 관리합니다.

```text
spring/src/main/resources/db/migration/
│
├── V1__analytics_requirements.sql
├── V2__kpi_definition.sql
├── V3__analysis_design.sql
├── V4__event_data_architecture.sql
└── V5__data_requirements.sql
```

각 SQL 파일의 역할이 명확하게 분리되어 있습니다.

---

# 4. V1 — Analytics Requirements

파일:

```text
spring/src/main/resources/db/migration/
└── V1__analytics_requirements.sql
```

분석을 시작하기 전에 **무엇을 분석할 것인가**를 데이터 계약으로 정의합니다.

주요 테이블:

```text
analytics_grain
analytics_segment
analytics_business_question
analytics_metric_definition
analytics_requirement
analytics_requirement_trace
analytics_metric_version
```

---

## 4.1 Analysis Grain

MIDO에서는 분석 단위를 명시적으로 정의합니다.

| Grain                  | 의미                  |
| ---------------------- | ------------------- |
| `verification`         | 하나의 Verification    |
| `status_event`         | 하나의 상태 변경           |
| `analysis_run_finding` | AI 분석 Run × Finding |
| `decision`             | 하나의 사람 판단           |
| `approval`             | 하나의 승인              |
| `team_day_week`        | 팀 × 날짜/주차 집계        |

즉 숫자를 계산하기 전에:

> **무엇을 1건이라고 볼 것인가?**

를 먼저 고정합니다.

---

# 5. Business Questions

MIDO에서는 분석 질문을 `BQ-001 ~ BQ-010`으로 관리합니다.

| ID     | Business Question                          |
| ------ | ------------------------------------------ |
| BQ-001 | 입력 후 판단 가능한 상태까지 얼마나 걸리는가?                 |
| BQ-002 | AI 근거가 제공되면 DecisionLog 작성률이 증가하는가?        |
| BQ-003 | 팀·입력유형·위험수준별 승인시간은 어떻게 다른가?                |
| BQ-004 | FIX 판단은 실제 재작업과 재검증으로 이어지는가?               |
| BQ-005 | 시니어 검토가 필요한 케이스에 리뷰가 집중되는가?                |
| BQ-006 | Guideline 적용 여부와 판단 일관성에는 어떤 관계가 있는가?      |
| BQ-007 | 실패·포기·장기 RUNNING의 주요 원인은 무엇인가?             |
| BQ-008 | 감사에 필요한 Evidence가 자동으로 연결되는가?              |
| BQ-009 | AI Finding과 Human Override가 반복되는 영역은 어디인가? |
| BQ-010 | 핵심 제품 KPI가 Baseline 대비 개선되는가?              |

단순히 데이터가 있기 때문에 분석하는 것이 아니라:

```text
Business Question
      ↓
Decision Owner
      ↓
Metric
      ↓
Analysis
      ↓
Action
```

으로 연결하는 구조입니다.

---

# 6. Core KPI

MIDO의 핵심 Product KPI는 `M-001 ~ M-005`입니다.

## M-001 — DecisionLog 작성률

```text
Valid DecisionLog
-----------------
Decision Required DONE Verification
```

의미:

> 검증을 완료하면서 실제 사람의 판단과 근거가 남았는가?

MIDO의 핵심 제품 지표 중 하나입니다.

---

## M-002 — 승인 시간

```text
Approval Completed
-
Approval Requested
```

승인이 필요한 Verification이 Reviewer에게 전달된 후 완료될 때까지 걸린 시간을 측정합니다.

활용:

```text
Risk Level
Team
Input Type
Reviewer Required
```

별로 승인시간 차이를 분석할 수 있습니다.

---

## M-003 — 재작업률

```text
FIX 이후 재작업 / 재검증 건
----------------------------
완료된 Decision 대상
```

`FIX` 판단이 실제 수정과 재검증으로 이어졌는지 확인하는 지표입니다.

---

## M-004 — 검증 완료율

```text
DONE Verification
-----------------
Valid Started Verification
```

Verification이 정상적으로 끝까지 완료되는 비율입니다.

---

## M-005 — 감사 수작업 시간

감사 Evidence를 준비하는 데 필요한 수작업 시간이 Baseline 대비 얼마나 감소했는지 측정하기 위한 KPI입니다.

현재 Dashboard DTO에서도 M-005 필드를 제공하지만, Audit Event가 아직 충분히 수집되지 않아 실제 Dashboard에서는 `NULL`을 허용하도록 구성되어 있습니다.

---

# 7. Metric Contract

파일:

```text
spring/src/main/resources/db/migration/
└── V2__kpi_definition.sql
```

단순히 KPI 이름과 수식만 저장하지 않습니다.

```text
metric_id
version

business_owner
data_owner

grain
formula

numerator_definition
denominator_definition

filters
dimensions

source_objects

freshness_sla
quality_tests

effective_date
measurement_status
```

를 함께 저장합니다.

예를 들어 같은 "완료율"이라도:

```text
테스트 데이터 포함 여부
취소 데이터 제외 여부
Timezone
Late Event 처리
분모 정의
```

에 따라 결과가 달라질 수 있습니다.

따라서 MIDO에서는 **지표의 계산 기준 자체를 코드로 버전 관리**합니다.

---

# 8. Responsible Decision Completion

MIDO에는 단순 KPI 외에 `Responsible Decision Completion` 개념도 정의되어 있습니다.

View:

```text
mart_responsible_decision_completion
```

판단 기준:

```text
Work Context 존재
        +
Risk Evidence 존재
        +
Human Decision 존재
        +
Rationale 존재
        +
고위험이면 Approval 존재
        ↓
Responsible Decision Completed
```

즉:

```text
분석 완료
≠
책임 있는 검증 완료
```

로 구분합니다.

AI가 결과를 만들었다고 해서 Verification이 끝난 것이 아니라, **사람의 판단과 필요한 승인까지 존재해야 책임 있는 Decision이 완성된 것**으로 정의했습니다.

---

# 9. Guardrail Metrics

제품 KPI가 좋아져도 안전성이 나빠진다면 좋은 결과라고 볼 수 없습니다.

따라서 별도의 Guardrail을 정의했습니다.

| ID    | Guardrail                             |
| ----- | ------------------------------------- |
| G-001 | Critical Risk 누락률                     |
| G-002 | 승인 없이 USE 처리된 고위험 건                   |
| G-003 | Secret / PII / Cross-team Data 노출     |
| G-004 | AI Error / Timeout / 장기 RUNNING       |
| G-005 | Reviewer Override 및 Rationale Missing |

P0 Guardrail은 Release 중단 조건으로 사용할 수 있도록 설계했습니다.

즉:

```text
Product KPI 개선
       +
Guardrail 정상
       ↓
확대 적용 검토
```

구조입니다.

---

# 10. Operational Metrics

제품 지표뿐 아니라 Pipeline과 시스템 병목을 확인하기 위한 운영지표도 정의했습니다.

```text
OP-001 created → READY
OP-002 READY → RUNNING
OP-003 RUNNING → DONE / FAILED
OP-004 Analysis p95
OP-005 Retry
OP-006 Duplicate
OP-007 Event Freshness
OP-008 Guideline Coverage
OP-009 Finding Evidence Coverage
OP-010 Cost per Analysis
```

이 지표를 이용하면:

```text
제품 문제인가?
Backend 문제인가?
AI Service 문제인가?
Data Pipeline 문제인가?
Reviewer 병목인가?
```

를 구분할 수 있습니다.

---

# 11. Analysis Framework

파일:

```text
spring/src/main/resources/db/migration/
└── V3__analysis_design.sql
```

분석 수준을 네 단계로 구분합니다.

```text
1. Descriptive
      ↓
2. Diagnostic
      ↓
3. Comparative
      ↓
4. Experimental
```

## Descriptive

현재 상태와 분포를 설명합니다.

예:

```text
오늘 Verification 100건
Completion Rate 78%
```

인과관계를 주장하지 않습니다.

---

## Diagnostic

어디에서 문제나 병목이 발생했는지 탐색합니다.

예:

```text
RUNNING 단계에서 실패율이 높음
        ↓
Provider Timeout 증가
```

---

## Comparative

Segment 또는 Baseline/Candidate를 비교합니다.

예:

```text
FILE Input
vs
PR Input

Approval Time 비교
```

역시 인과관계라고 단정하지 않습니다.

---

## Experimental

사전에 가설과 Control을 정의한 실험만 인과 효과를 평가할 수 있도록 설계했습니다.

즉 MIDO의 분석 계약에서는 **Descriptive / Diagnostic / Comparative 단계에서는 Causal Claim을 허용하지 않습니다.**

---

# 12. Verification Funnel

MIDO의 분석 Funnel은 다음 흐름으로 정의되어 있습니다.

```text
Verification Created
        ↓
Context Ready
        ↓
Analysis Started
        ↓
Analysis Completed
        ↓
Decision Submitted
        ↓
Approval Requested
        ↓
Approval Completed
```

각 단계에서:

```text
Reached Count
Conversion Rate
Drop-off Rate
Median Time To Next
p95 Time To Next
```

를 분석할 수 있도록 설계했습니다.

---

# 13. Funnel 파일 위치

```text
spring/src/main/resources/db/migration/
└── V3__analysis_design.sql
```

주요 분석 View:

```text
mart_funnel_step_metrics
mart_decision_review_design
```

현재 Funnel Metric 중 일부는 실제 운영 Event가 충분히 수집되기 전까지 `NOT_MEASURED` 상태로 관리됩니다.

---

# 14. Failure Taxonomy

단순히:

```text
실패 20건
```

이라고 집계하지 않고 실패 원인을 Taxonomy로 구분합니다.

```text
FAILED
LONG_DRAFT
LONG_READY
LONG_RUNNING
DUPLICATE_SUBMISSION
UPLOAD_VALIDATION
PROVIDER_TIMEOUT
OUTPUT_INVALID
POLICY_MISSING
```

각 Failure에는:

```text
Severity
Root Cause Owner
Ticket Required
Funnel Step
```

를 연결합니다.

따라서:

```text
Failure
   ↓
Cause
   ↓
Owner
   ↓
Action
```

까지 분석 결과가 이어지도록 설계했습니다.

---

# 15. Cohort Analysis

첫 번째 유효 Verification이 만들어진 주를 기준으로 Cohort를 정의했습니다.

```text
First Valid Verification Week
          ↓
W1 Reuse
W4 Reuse
```

장기적으로는:

```text
첫 Verification
      ↓
반복 Verification
      ↓
Responsible Decision 반복
      ↓
Team Adoption
```

을 측정할 수 있도록 설계했습니다.

현재 Cohort 측정은 `NOT_MEASURED` 단계이며, Definition과 Grain이 먼저 정의된 상태입니다.

---

# 16. Experiment Design

MIDO에는 향후 실험을 위한 Contract도 존재합니다.

대표 실험:

```text
EXP-001

근거 요약 UI가
DecisionLog 작성률과 승인시간을
개선하는가?
```

Primary Metric:

```text
M-001 DecisionLog 작성률
```

Secondary Metrics:

```text
M-002 승인시간
M-004 검증완료율
```

Guardrail:

```text
G-001 ~ G-005
```

실험 설계에서는:

```text
Randomization Unit
Contamination Risk
Pre-period
Sample Size
Stopping Rule
Safety Constraint
```

까지 관리합니다.

현재 상태는 `PLANNED`입니다.

---

# 17. Event Data Architecture

파일:

```text
spring/src/main/resources/db/migration/
└── V4__event_data_architecture.sql
```

Event Schema 자체도 데이터 계약으로 관리합니다.

주요 테이블:

```text
analytics_event_schema
analytics_event_property
analytics_event_metric_trace
analytics_event_contract_test
analytics_event_schema_change
analytics_bi_serving_contract
```

---

# 18. Event Catalog

정의된 대표 Event는 다음과 같습니다.

```text
verification_created
manual_input_saved
file_uploaded
work_context_ready

analysis_started
analysis_completed
analysis_failed

risk_finding_produced
guideline_retrieved

decision_submitted

approval_requested
approval_completed

verification_status_changed
verification_reopened
verification_backfilled
```

전체 Event가 모두 운영 수집 완료 상태인 것은 아닙니다.

현재 Contract에서는 일부 Backend Event는 `IMPLEMENTED`, AI·Decision·Approval 관련 Event 상당수는 `PLANNED` 상태로 명확히 구분합니다.

---

# 19. Event Privacy

분석 Event에는 Source Code 원문이나 Secret을 넣지 않는 것을 원칙으로 합니다.

Event Property 계약에서는 다음 Property를 금지합니다.

```text
code_content
raw_code
prompt
credential
access_token
personal_identifier
```

또한 Event 단위로:

```text
NONE
PSEUDONYMIZED
SENSITIVE
RESTRICTED
```

PII Class를 구분합니다.

분석을 위해 모든 원본 데이터를 복제하는 대신 **분석에 필요한 Metadata만 Event로 전달**하도록 설계한 것입니다.

---

# 20. Event Idempotency

Event 재전송으로 KPI가 중복 계산되지 않도록:

```text
event_id
+
producer
+
idempotency_key
```

를 관리합니다.

실제 `data_event`에는:

```text
UNIQUE(producer, idempotency_key)
```

제약을 사용합니다.

따라서 같은 Event가 다시 전달되어도 중복 집계 위험을 줄일 수 있습니다.

---

# 21. Data Architecture

파일:

```text
spring/src/main/resources/db/migration/
└── V5__data_requirements.sql
```

V5에서는 실제 운영 데이터와 Analytics Model을 연결합니다.

전체 분석 데이터 흐름은 다음과 같습니다.

```text
Operational Tables
       ↓
Staging
       ↓
Intermediate
       ↓
Fact
       ↓
Mart
       ↓
Spring DA API
       ↓
Next.js Dashboard
```

---

# 22. Operational Source

분석 Source의 중심은 다음 데이터입니다.

```text
verification_data
manual_input
uploaded_file
work_context

risk_assessment
decision_log
approval

verification_status_transition
data_event
team_guideline
git_metadata
```

MIDO DA의 핵심 중심 Entity는:

```text
verification_data
```

입니다.

---

# 23. Layered Analytics Modeling

분석 모델을 한 번의 거대한 SQL로 만들지 않고 계층화했습니다.

```text
STAGING
│
├── stg_verification_data
├── stg_decision_log
└── stg_approval

        ↓

INTERMEDIATE
│
├── int_verification_lifecycle
├── int_decision_cycle
└── int_rework_cycle

        ↓

FACT
│
├── fct_verification
├── fct_decision
└── fct_approval

        ↓

MART
│
├── mart_daily_product_metrics
├── mart_team_quality
└── mart_ai_operations
```

각 단계의 책임을 나눠 같은 Metric을 여러 Dashboard에서 다시 구현하지 않도록 했습니다.

---

# 24. Why Layering?

예를 들어 Dashboard마다 완료율을 직접 계산하면:

```text
Dashboard A
DONE / 전체

Dashboard B
DONE / 테스트 제외 전체

Report C
DONE / 취소 제외 전체
```

처럼 동일한 지표가 서로 다른 숫자가 될 수 있습니다.

MIDO에서는:

```text
Metric Contract
      ↓
Fact
      ↓
Mart
      ↓
Dashboard
```

구조로 계산 기준을 고정합니다.

---

# 25. Daily Product Mart

Dashboard가 직접 조회하는 핵심 Mart는:

```text
mart_daily_product_metrics
```

입니다.

제공하는 주요 값:

```text
metric_date

verification_started_count
verification_done_count

decision_log_count
fix_decision_count
rework_count

m001_decision_log_rate
m002_avg_approval_seconds
m003_rework_rate
m004_completion_rate
m005_audit_manual_time_reduction_rate
```

이 Mart가 MIDO Product Analytics Dashboard의 Serving Layer 역할을 합니다.

---

# 26. DA Backend 위치

Backend DA 코드는:

```text
spring/src/main/verification/da/
```

아래에 존재합니다.

```text
spring/src/main/verification/da/
│
├── dashboard/
│   ├── controller/
│   │   └── DashboardMetricsController.java
│   │
│   ├── service/
│   │   └── DashboardMetricsService.java
│   │
│   ├── repository/
│   │   └── DashboardMetricsRepository.java
│   │
│   └── dto/
│       └── DailyProductMetricResponse.java
│
└── list/
    ├── controller/
    │   └── VerificationListController.java
    │
    ├── service/
    │   └── VerificationListService.java
    │
    └── dto/
        └── VerificationSummaryResponse.java
```

---

# 27. Dashboard API

Controller:

```text
spring/src/main/verification/da/dashboard/controller/
└── DashboardMetricsController.java
```

API:

```http
GET /api/da/dashboard/daily-metrics
```

기간 지정:

```http
GET /api/da/dashboard/daily-metrics?days=30
```

---

# 28. Dashboard Service

파일:

```text
spring/src/main/verification/da/dashboard/service/
└── DashboardMetricsService.java
```

기간 입력값을 그대로 DB에 전달하지 않습니다.

```text
default = 30 days
minimum = 1 day
maximum = 180 days
```

로 제한합니다.

또한 조회 전용이므로:

```java
@Transactional(readOnly = true)
```

를 사용합니다.

---

# 29. Dashboard Repository

파일:

```text
spring/src/main/verification/da/dashboard/repository/
└── DashboardMetricsRepository.java
```

Dashboard용 Mart는 JPA Entity로 다시 매핑하지 않고 `JdbcTemplate`을 통해 Read Model로 직접 조회합니다.

```text
mart_daily_product_metrics
        ↓
JdbcTemplate
        ↓
DailyProductMetricResponse
        ↓
REST API
```

Analytics Mart를 운영 Entity처럼 다루지 않고 **조회 전용 Serving Model로 분리**한 구조입니다.

---

# 30. Dashboard DTO

파일:

```text
spring/src/main/verification/da/dashboard/dto/
└── DailyProductMetricResponse.java
```

DTO 필드:

```text
metricDate

verificationStartedCount
verificationDoneCount

decisionLogCount
fixDecisionCount
reworkCount

m001DecisionLogRate
m002AvgApprovalSeconds
m003ReworkRate
m004CompletionRate
m005AuditManualTimeReductionRate
```

---

# 31. Verification List Analytics Optimization

DA 작업에는 Dashboard뿐 아니라 분석 및 운영 목록 조회 최적화도 포함되어 있습니다.

위치:

```text
spring/src/main/verification/da/list/
```

API:

```http
GET /api/verifications
```

지원:

```text
status
page
size
```

---

# 32. DTO Projection

목록 API에서는 `VerificationData` Entity 전체를 가져오지 않습니다.

공용 Repository 위치:

```text
spring/src/main/verification/common/repository/
└── VerificationDataRepository.java
```

조회하는 컬럼:

```text
id
inputType
status
createdAt
```

제외:

```text
code
```

즉:

```text
Before

VerificationData 전체
      ↓
대용량 code까지 읽을 가능성


After

Summary Projection
      ↓
id / type / status / date
```

로 바꿨습니다.

---

# 33. LOB Optimization

MIDO에서 `verification_data.code`는 대용량 LOB 데이터입니다.

따라서 핵심 규칙을:

> **목록과 통계 Query에서 Code LOB을 조회하지 않는다.**

로 정의했습니다.

이를 DTO Projection 구조로 코드 레벨에서도 강제합니다.

---

# 34. Pagination

파일:

```text
spring/src/main/verification/da/list/service/
└── VerificationListService.java
```

Pagination을 지원합니다.

```text
page >= 0
1 <= size <= 100
```

최대 Page Size:

```text
100
```

무제한 `findAll()` 형태의 조회를 방지합니다.

정렬:

```text
createdAt DESC
```

---

# 35. Index

목록 조회를 지원하기 위해 V5에서 Index를 정의했습니다.

대표 Index:

```sql
CREATE INDEX idx_verification_status_created
ON verification_data(status, created_at DESC);
```

따라서:

```text
WHERE status = ?
ORDER BY created_at DESC
```

형태의 조회를 지원합니다.

추가 Index:

```text
idx_verification_input_type_created

uq_work_context_verification

idx_uploaded_file_verification_uploaded

idx_manual_input_verification
```

등이 있습니다.

---

# 36. 현재 성능 Evidence의 경계

Index와 Projection은 구현되어 있지만:

```text
EXPLAIN ANALYZE
```

를 이용한 실제 Index Scan 성능 검증은 DA 문서에서 아직 `미실행` 상태로 남아 있습니다.

따라서 README에서는:

```text
"응답시간 80% 개선"
"DB 조회 10배 향상"
```

같은 실제 측정되지 않은 수치를 사용하지 않습니다.

현재 증명 가능한 것은:

```text
Projection 구현
LOB 제외 구현
Pagination 구현
Index 구현
API/Test 구현
```

입니다.

---

# 37. Frontend Dashboard 위치

Dashboard 화면:

```text
web/src/app/da/dashboard/
└── page.tsx
```

URL:

```text
/mido/da/dashboard
```

구조:

```text
Dashboard Page
      ↓
GET /api/da/dashboard/daily-metrics
      ↓
Spring DA API
      ↓
mart_daily_product_metrics
```

---

# 38. Dashboard Component

차트:

```text
web/src/components/da/
└── DailyMetricsBarChart.tsx
```

외부 BI 도구를 사용하지 않고 React + CSS 기반으로 구현되어 있습니다.

표시 항목:

```text
날짜

Verification 시작
Verification 완료

M-001 DecisionLog율

M-002 평균 승인시간

M-003 재작업률

M-004 완료율
```

---

# 39. Sample Data 위치

파일:

```text
web/src/lib/da/
└── sampleMetrics.ts
```

현재 실사용 Verification 데이터가 충분하지 않을 때 Dashboard Layout을 확인하기 위한 Sample Dataset입니다.

중요한 점은 Dashboard가 이를 숨기지 않는다는 것입니다.

```text
실데이터 있음
→ 실제 API 결과 표시

실데이터 없음
        또는
Backend 연결 실패
→ Sample Data 표시
→ "샘플 데이터" Badge 표시
```

따라서 Sample KPI를 실제 제품 성과처럼 보여주지 않습니다.

---

# 40. Sample Data Interpretation

현재 Sample Dataset은 2026-08-13 ~ 2026-08-26 기간의 Dashboard 동작 확인을 위해 구성되어 있습니다.

예를 들어 Sample에서는:

```text
Verification 시작 건수
9 ~ 30건

DecisionLog Rate
약 73% ~ 92%

평균 승인시간
약 470 ~ 715초

재작업률
0% ~ 약 30%

완료율
약 67% ~ 81%
```

범위가 나타납니다.

하지만 이것은:

> **실사용자가 만든 KPI가 아니라 Dashboard와 분석 구조를 재현하기 위한 Sample Data**

입니다.

---

# 41. Example Insight — Sample Only

Sample Data에서는 Verification 요청량이 높은 일부 날짜에서 재작업률과 승인시간도 상대적으로 높게 설정되어 있습니다.

예:

```text
2026-08-20

Started
28

Rework Rate
28.57%

Approval Time
690 sec
```

또:

```text
2026-08-23

Started
30

Rework Rate
30.43%

Approval Time
715 sec
```

입니다.

이 데이터를 실제 운영 데이터라고 가정할 수는 없지만, 실제 Event가 쌓였을 경우 다음 가설을 검토하는 Dashboard 구조를 보여줍니다.

```text
Verification 요청 증가
        ↓
Reviewer Load 증가?
        ↓
Approval Delay 증가?
        ↓
Rework 증가?
```

실제 인과관계는 운영 데이터 또는 별도의 실험 없이는 주장하지 않습니다.

---

# 42. Dashboard Test

Backend Dashboard 테스트:

```text
spring/src/test/verification/da/dashboard/controller/
└── DashboardMetricsControllerTest.java
```

검증 대상:

```text
GET /api/da/dashboard/daily-metrics

HTTP 200

Metric Date

Verification Started Count

M-004 Completion Rate

M-005 NULL 처리

days Query Parameter
```

---

# 43. Verification List Test

위치:

```text
spring/src/test/verification/da/list/controller/
└── VerificationListControllerTest.java
```

특히 다음을 Test로 고정합니다.

```text
GET /api/verifications
        ↓
Summary Response
        ↓
code field 없음
```

즉 LOB 제거가 단순 개발 규칙이 아니라 **회귀 테스트 대상**이 됩니다.

추가로:

```text
status filter

page

size

invalid status → HTTP 400
```

도 테스트합니다.

---

# 44. End-to-End DA Architecture

전체 DA 구조를 하나로 보면 다음과 같습니다.

```text
┌──────────────────────────────┐
│       MIDO Application       │
│                              │
│ Verification / Context       │
│ Risk / Decision / Approval   │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│          PostgreSQL          │
│                              │
│ OLTP Tables                  │
│ Event / Status Transition    │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│      Analytics Modeling      │
│                              │
│ STG → INT → FACT → MART      │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ mart_daily_product_metrics   │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│     Spring Dashboard API     │
│                              │
│ /api/da/dashboard/           │
│ daily-metrics                │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│    Next.js DA Dashboard      │
│                              │
│ /mido/da/dashboard           │
└──────────────────────────────┘
```

---

# 45. DA Data Quality

MIDO는 지표를 계산하는 것뿐 아니라 데이터 품질을 함께 고려합니다.

V5에는:

```text
data_quality_rule
data_quality_quarantine
```

구조가 존재합니다.

Event에는:

```text
event_id
occurred_at
received_at
schema_version

verification_id

idempotency_key

actor_id_hash

team_id
project_id
```

등을 저장할 수 있도록 설계했습니다.

---

# 46. Privacy

분석 Segment에는 최소 표본 기준도 존재합니다.

예:

```text
team
project
language_framework
work_type
risk_level
reviewer_required
user_cohort
```

등은 기본적으로 작은 표본의 결과를 무조건 공개하지 않고 Privacy Threshold를 둘 수 있도록 설계되어 있습니다.

또 사용자 및 Reviewer 식별정보는:

```text
actor_id_hash
reviewer_id_hash
approved_by_hash
```

등 Hash 기반 식별자로 분석할 수 있도록 구조를 잡았습니다.

---

# 47. Source → Metric Lineage

MIDO의 DA 설계에서 중요한 부분은 Metric이 어디에서 만들어졌는지 추적하는 것입니다.

```text
Business Requirement
       ↓
Business Question
       ↓
Metric Definition
       ↓
Event
       ↓
Analytical Model
       ↓
Mart
       ↓
Dashboard
```

이를 위한 테이블로:

```text
analytics_requirement_trace
analytics_event_metric_trace
analytics_artifact_registry
analytics_model_catalog
```

등을 사용합니다.

따라서 최종 Dashboard 숫자에서 다시 Source까지 추적할 수 있는 구조를 지향합니다.

---

# 48. Business Recommendations

실제 운영 데이터가 충분히 쌓인 이후 다음 분석을 우선 수행할 수 있습니다.

### Recommendation 1 — Rework Spike Monitoring

```text
M-003 Rework Rate
      ↓
일별 Baseline 비교
      ↓
급증 탐지
      ↓
Team / Risk / Input Type Drill-down
```

재작업률이 갑자기 증가한 날짜를 빠르게 찾고 원인을 분석합니다.

---

### Recommendation 2 — Approval SLA

```text
M-002 Approval Time
      ↓
Risk Level
Reviewer
Input Type
      ↓
SLA 초과 분석
```

승인 병목이 특정 Reviewer나 Risk Level에 집중되는지 확인할 수 있습니다.

---

### Recommendation 3 — Missing DecisionLog

```text
DONE Verification
      ↓
DecisionLog LEFT JOIN
      ↓
Missing Rationale
      ↓
Audit Risk
```

완료되었지만 판단 기록이 없는 Verification을 추적합니다.

---

### Recommendation 4 — AI Evidence Effect

다음 Segment를 비교할 수 있습니다.

```text
AI Evidence 있음
        VS
AI Evidence 없음
```

비교 KPI:

```text
M-001 DecisionLog 작성률

M-002 승인시간

M-003 재작업률
```

단, 단순 관찰 분석에서는 인과관계를 주장하지 않습니다.

---

# 49. Current Implementation Status

| 영역                                   | 상태                           |
| ------------------------------------ | ---------------------------- |
| Analytics Requirement Schema         | ✅ Implemented                |
| Business Question BQ-001~010         | ✅ Defined                    |
| Core KPI M-001~005                   | ✅ Defined                    |
| Metric Contract                      | ✅ Implemented                |
| Metric Versioning                    | ✅ Implemented                |
| Guardrail Metric                     | ✅ Defined                    |
| Operational Metric                   | ✅ Defined                    |
| Analysis Framework                   | ✅ Implemented                |
| Funnel Definition                    | ✅ Defined                    |
| Cohort Definition                    | ✅ Defined                    |
| Failure Taxonomy                     | ✅ Defined                    |
| Experiment Contract                  | ✅ Defined / Planned          |
| Event Schema Contract                | ✅ Implemented                |
| Event Property Contract              | ✅ Implemented                |
| Event → Metric Trace                 | ✅ Designed                   |
| Operational Data Model               | ✅ Implemented                |
| Data Event Schema                    | ✅ Implemented                |
| Status Transition Model              | ✅ Implemented                |
| STG / INT / FACT / MART Layer        | ✅ Implemented in Migration   |
| `mart_daily_product_metrics`         | ✅ Implemented                |
| Dashboard REST API                   | ✅ Implemented                |
| Verification Summary API             | ✅ Implemented                |
| DTO Projection                       | ✅ Implemented                |
| Pagination                           | ✅ Implemented                |
| DB Index                             | ✅ Implemented                |
| Dashboard UI                         | ✅ Implemented                |
| Dashboard Sample Fallback            | ✅ Implemented                |
| Dashboard Controller Test            | ✅ Implemented                |
| List Controller Test                 | ✅ Implemented                |
| Real User KPI                        | ⚠️ Not Measured              |
| M-005 Audit Metric                   | ⚠️ Data Not Collected / NULL |
| EXPLAIN ANALYZE Performance Evidence | ⚠️ Not Executed              |
| Production Performance Improvement % | ❌ Not Claimed                |

---

# 50. Current Repository Gaps

현재 Repository를 기준으로 몇 가지 정리할 부분도 있습니다.

## Funnel Event Naming

`V3__analysis_design.sql`의 Funnel에는:

```text
context_ready
```

가 사용되지만 Event Contract인 `V4__event_data_architecture.sql`에서는:

```text
work_context_ready
```

가 정의되어 있습니다.

따라서 실제 Event 기반 Funnel을 연결하기 전에 Event Name을 하나로 통일할 필요가 있습니다.

---

## Documentation Package Path Drift

일부 기존 DA 문서의 오래된 코드 예시에는:

```text
com.mido.verification.list...
```

형태가 남아 있지만 현재 실제 구현 위치는:

```text
com.mido.verification.da.list...
```

입니다.

이 README에서는 현재 Repository의 실제 경로를 기준으로 작성합니다.

---

## Sample vs Production Data

현재 Dashboard는 실제 데이터가 없으면 Sample Dataset으로 자동 전환됩니다.

따라서 README나 포트폴리오에서 Sample Dashboard 숫자를 실제 서비스 개선 성과로 표현해서는 안 됩니다.

---

# 51. Tech Stack

| 영역                 | 기술                                        |
| ------------------ | ----------------------------------------- |
| Analytics Database | PostgreSQL                                |
| Data Modeling      | STG / INT / FACT / MART                   |
| Metric Contract    | SQL / Flyway                              |
| Backend            | Java 21                                   |
| Framework          | Spring Boot 3.5                           |
| ORM / Query        | Spring Data JPA / JPQL / JdbcTemplate     |
| Migration          | Flyway                                    |
| API                | Spring MVC REST                           |
| Frontend           | Next.js 15                                |
| UI                 | React 19                                  |
| Language           | TypeScript                                |
| Dashboard          | Custom React/CSS                          |
| AI Service         | FastAPI / Python                          |
| Test               | JUnit 5 / MockMvc                         |
| DB Performance     | Index / Projection / Pagination / EXPLAIN |
| Privacy            | Hashed Identifier / Privacy Threshold     |

---

# 52. Repository Map — DA Only

```text
MIDO_Project/
│
├── da/
│   ├── DA-01-data-performance-guide.md
│   ├── DA-02-db-efficiency-summary.md
│   ├── DA-03-efficiency-summary.md
│   ├── DA-04-document-index.md
│   ├── DA-05-portfolio-case-study.md
│   │
│   └── assets/
│       └── da-05-dashboard-sample.png
│
├── spring/
│   └── src/
│       ├── main/
│       │   ├── resources/
│       │   │   └── db/
│       │   │       └── migration/
│       │   │           ├── V1__analytics_requirements.sql
│       │   │           ├── V2__kpi_definition.sql
│       │   │           ├── V3__analysis_design.sql
│       │   │           ├── V4__event_data_architecture.sql
│       │   │           └── V5__data_requirements.sql
│       │   │
│       │   └── verification/
│       │       ├── common/
│       │       │   └── repository/
│       │       │       └── VerificationDataRepository.java
│       │       │
│       │       └── da/
│       │           ├── list/
│       │           │   ├── controller/
│       │           │   │   └── VerificationListController.java
│       │           │   ├── service/
│       │           │   │   └── VerificationListService.java
│       │           │   └── dto/
│       │           │       └── VerificationSummaryResponse.java
│       │           │
│       │           └── dashboard/
│       │               ├── controller/
│       │               │   └── DashboardMetricsController.java
│       │               ├── service/
│       │               │   └── DashboardMetricsService.java
│       │               ├── repository/
│       │               │   └── DashboardMetricsRepository.java
│       │               └── dto/
│       │                   └── DailyProductMetricResponse.java
│       │
│       └── test/
│           └── verification/
│               └── da/
│                   ├── list/
│                   │   └── controller/
│                   │       └── VerificationListControllerTest.java
│                   │
│                   └── dashboard/
│                       └── controller/
│                           └── DashboardMetricsControllerTest.java
│
└── web/
    └── src/
        ├── app/
        │   └── da/
        │       └── dashboard/
        │           └── page.tsx
        │
        ├── components/
        │   └── da/
        │       └── DailyMetricsBarChart.tsx
        │
        ├── lib/
        │   ├── api.ts
        │   └── da/
        │       └── sampleMetrics.ts
        │
        └── types/
            └── index.ts
```

---

# 53. What I Focused On

MIDO의 DA 영역에서는 단순히 Dashboard를 만든 것이 아니라:

```text
Business Problem
       ↓
Business Question
       ↓
Metric Contract
       ↓
Event Contract
       ↓
Data Quality
       ↓
Analytical Model
       ↓
Serving Mart
       ↓
REST API
       ↓
Dashboard
       ↓
Insight
       ↓
Product Action
```

까지 연결하는 데 집중했습니다.

특히 MIDO는 AI가 포함된 시스템이므로 일반적인 Product Analytics보다:

```text
Human Decision

Auditability

Risk Evidence

Reviewer Approval

Guardrail

Privacy
```

를 분석 모델에 함께 포함했습니다.

---

# 54. Portfolio Point

이 프로젝트의 DA 포인트는:

> **“Dashboard를 만들었다”가 아니라 “AI 코드 검증 과정에서 사람의 책임 있는 판단이 실제로 발생하는지를 측정 가능한 데이터 구조로 만들었다”**

는 것입니다.

이를 위해:

```text
BQ-001 ~ BQ-010
        ↓
M-001 ~ M-005
        ↓
Event Contract
        ↓
Funnel
        ↓
STG / INT / FACT / MART
        ↓
Spring Dashboard API
        ↓
Next.js Dashboard
```

를 실제 Repository 구조로 연결했습니다.

또한 Sample Data와 실제 KPI를 구분하고, 측정하지 않은 성능 개선율을 임의로 성과화하지 않았습니다.

---

# Summary

**MIDO DA는 AI 코드 검증 시스템의 `Verification → Context → AI Analysis → Decision → Approval` Lifecycle을 분석 가능한 Event와 Metric으로 구조화한 Responsible AI Product Analytics 프로젝트입니다.**

10개의 Business Question과 M-001~M-005 Product KPI, Guardrail 및 Operational Metric을 데이터 계약으로 정의하고, Funnel·Failure Taxonomy·Cohort·Experiment 구조를 분석 Schema에 포함했습니다.

운영 데이터는 `STG → INT → FACT → MART` 레이어로 변환하고 `mart_daily_product_metrics`를 Spring REST API로 제공한 뒤 Next.js Dashboard에서 일별 Verification 시작·완료·DecisionLog 작성률·승인시간·재작업률·완료율을 조회할 수 있도록 구성했습니다.

또한 분석 조회에서는 대용량 `code` LOB을 DTO Projection으로 제거하고 Pagination과 Index를 적용했으며, 이를 Controller Test로 검증했습니다.

현재 실사용 데이터가 충분하지 않은 Dashboard는 명확하게 **Sample Data**로 표시하며, 실제 측정되지 않은 KPI나 성능 개선율은 프로젝트 성과로 주장하지 않습니다.
