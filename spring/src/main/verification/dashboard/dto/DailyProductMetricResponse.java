package com.mido.verification.dashboard.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * {@code mart_daily_product_metrics} (V5 마이그레이션의 dbt 스타일 mart 뷰)를 그대로 노출하는 응답 DTO.
 *
 * <p>DA-02/DA-03 "Key Insights &amp; Dashboard"에서 요구하는 M-001~M-004 지표를
 * 하루 단위로 반환한다. M-005(감사 수작업 시간 절감률)는 audit 이벤트가 아직
 * 수집되지 않아 뷰에서 항상 NULL이다.</p>
 */
public class DailyProductMetricResponse {

    private final LocalDate metricDate;
    private final long verificationStartedCount;
    private final long verificationDoneCount;
    private final long decisionLogCount;
    private final long fixDecisionCount;
    private final long reworkCount;
    private final BigDecimal m001DecisionLogRate;
    private final Double m002AvgApprovalSeconds;
    private final BigDecimal m003ReworkRate;
    private final BigDecimal m004CompletionRate;
    private final BigDecimal m005AuditManualTimeReductionRate;

    public DailyProductMetricResponse(
            LocalDate metricDate,
            long verificationStartedCount,
            long verificationDoneCount,
            long decisionLogCount,
            long fixDecisionCount,
            long reworkCount,
            BigDecimal m001DecisionLogRate,
            Double m002AvgApprovalSeconds,
            BigDecimal m003ReworkRate,
            BigDecimal m004CompletionRate,
            BigDecimal m005AuditManualTimeReductionRate
    ) {
        this.metricDate = metricDate;
        this.verificationStartedCount = verificationStartedCount;
        this.verificationDoneCount = verificationDoneCount;
        this.decisionLogCount = decisionLogCount;
        this.fixDecisionCount = fixDecisionCount;
        this.reworkCount = reworkCount;
        this.m001DecisionLogRate = m001DecisionLogRate;
        this.m002AvgApprovalSeconds = m002AvgApprovalSeconds;
        this.m003ReworkRate = m003ReworkRate;
        this.m004CompletionRate = m004CompletionRate;
        this.m005AuditManualTimeReductionRate = m005AuditManualTimeReductionRate;
    }

    public LocalDate getMetricDate() {
        return metricDate;
    }

    public long getVerificationStartedCount() {
        return verificationStartedCount;
    }

    public long getVerificationDoneCount() {
        return verificationDoneCount;
    }

    public long getDecisionLogCount() {
        return decisionLogCount;
    }

    public long getFixDecisionCount() {
        return fixDecisionCount;
    }

    public long getReworkCount() {
        return reworkCount;
    }

    public BigDecimal getM001DecisionLogRate() {
        return m001DecisionLogRate;
    }

    public Double getM002AvgApprovalSeconds() {
        return m002AvgApprovalSeconds;
    }

    public BigDecimal getM003ReworkRate() {
        return m003ReworkRate;
    }

    public BigDecimal getM004CompletionRate() {
        return m004CompletionRate;
    }

    public BigDecimal getM005AuditManualTimeReductionRate() {
        return m005AuditManualTimeReductionRate;
    }
}
