package com.mido.verification.da.dashboard.controller;

import com.mido.verification.da.dashboard.dto.DailyProductMetricResponse;
import com.mido.verification.da.dashboard.service.DashboardMetricsService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/da/dashboard")
public class DashboardMetricsController {

    private final DashboardMetricsService dashboardMetricsService;

    public DashboardMetricsController(DashboardMetricsService dashboardMetricsService) {
        this.dashboardMetricsService = dashboardMetricsService;
    }

    @GetMapping("/daily-metrics")
    public ResponseEntity<List<DailyProductMetricResponse>> dailyMetrics(
            @RequestParam(value = "days", required = false) Integer days
    ) {
        return ResponseEntity.ok(dashboardMetricsService.dailyMetrics(days));
    }
}
