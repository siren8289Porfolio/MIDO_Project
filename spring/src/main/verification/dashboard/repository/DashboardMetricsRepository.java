package com.mido.verification.dashboard.repository;

import com.mido.verification.dashboard.dto.DailyProductMetricResponse;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

/**
 * {@code mart_daily_product_metrics} 뷰(V5 마이그레이션) 조회 전용 리포지토리.
 *
 * <p>이 뷰는 엔티티로 매핑하기보다 BI 마트 조회 관례대로 {@link JdbcTemplate}로 직접
 * 읽는다. JPA 엔티티/영속성 컨텍스트를 개입시키지 않는 순수 read model이다.</p>
 */
@Repository
public class DashboardMetricsRepository {

    private static final String SELECT_DAILY_METRICS = """
            SELECT metric_date,
                   verification_started_count,
                   verification_done_count,
                   decision_log_count,
                   fix_decision_count,
                   rework_count,
                   m001_decision_log_rate,
                   m002_avg_approval_seconds,
                   m003_rework_rate,
                   m004_completion_rate,
                   m005_audit_manual_time_reduction_rate
            FROM mart_daily_product_metrics
            WHERE metric_date >= CURRENT_DATE - ?
            ORDER BY metric_date DESC
            """;

    private final JdbcTemplate jdbcTemplate;

    public DashboardMetricsRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<DailyProductMetricResponse> findRecentDailyMetrics(int days) {
        return jdbcTemplate.query(SELECT_DAILY_METRICS, (rs, rowNum) -> new DailyProductMetricResponse(
                rs.getObject("metric_date", LocalDate.class),
                rs.getLong("verification_started_count"),
                rs.getLong("verification_done_count"),
                rs.getLong("decision_log_count"),
                rs.getLong("fix_decision_count"),
                rs.getLong("rework_count"),
                rs.getBigDecimal("m001_decision_log_rate"),
                (Double) rs.getObject("m002_avg_approval_seconds"),
                rs.getBigDecimal("m003_rework_rate"),
                rs.getBigDecimal("m004_completion_rate"),
                rs.getBigDecimal("m005_audit_manual_time_reduction_rate")
        ), days);
    }
}
