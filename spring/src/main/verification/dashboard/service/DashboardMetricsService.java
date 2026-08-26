package com.mido.verification.dashboard.service;

import com.mido.verification.dashboard.dto.DailyProductMetricResponse;
import com.mido.verification.dashboard.repository.DashboardMetricsRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class DashboardMetricsService {

    private static final int DEFAULT_DAYS = 30;
    private static final int MAX_DAYS = 180;

    private final DashboardMetricsRepository dashboardMetricsRepository;

    public DashboardMetricsService(DashboardMetricsRepository dashboardMetricsRepository) {
        this.dashboardMetricsRepository = dashboardMetricsRepository;
    }

    @Transactional(readOnly = true)
    public List<DailyProductMetricResponse> dailyMetrics(Integer days) {
        int safeDays = days == null ? DEFAULT_DAYS : Math.min(Math.max(days, 1), MAX_DAYS);
        return dashboardMetricsRepository.findRecentDailyMetrics(safeDays);
    }
}
