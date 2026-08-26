package com.mido.verification.dashboard.controller;

import com.mido.verification.dashboard.dto.DailyProductMetricResponse;
import com.mido.verification.dashboard.service.DashboardMetricsService;
import com.mido.verification.global.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import static org.hamcrest.Matchers.nullValue;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(DashboardMetricsController.class)
@Import(GlobalExceptionHandler.class)
class DashboardMetricsControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private DashboardMetricsService dashboardMetricsService;

    @Test
    void dailyMetrics_returnsMartRows_withDefaultWindow() throws Exception {
        DailyProductMetricResponse row = new DailyProductMetricResponse(
                LocalDate.parse("2026-08-25"),
                10L, 6L, 4L, 1L, 1L,
                new BigDecimal("0.6667"),
                125.5,
                new BigDecimal("0.1667"),
                new BigDecimal("0.6"),
                null);

        when(dashboardMetricsService.dailyMetrics(isNull())).thenReturn(List.of(row));

        mockMvc.perform(get("/api/dashboard/daily-metrics"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].metricDate").value("2026-08-25"))
                .andExpect(jsonPath("$[0].verificationStartedCount").value(10))
                .andExpect(jsonPath("$[0].m004CompletionRate").value(0.6))
                .andExpect(jsonPath("$[0].m005AuditManualTimeReductionRate").value(nullValue()));
    }

    @Test
    void dailyMetrics_passesDaysParam() throws Exception {
        when(dashboardMetricsService.dailyMetrics(eq(7))).thenReturn(List.of());

        mockMvc.perform(get("/api/dashboard/daily-metrics").param("days", "7"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$").isEmpty());
    }
}
