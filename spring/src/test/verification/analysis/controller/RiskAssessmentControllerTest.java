package com.mido.verification.analysis.controller;

import com.mido.verification.analysis.dto.RiskAnalyzeApiResponse;
import com.mido.verification.analysis.dto.RiskItemResponse;
import com.mido.verification.de.risk.AiConfidence;
import com.mido.verification.de.risk.AiOutputStatus;
import com.mido.verification.de.risk.AiRecommendation;
import com.mido.verification.analysis.service.RiskAssessmentService;
import com.mido.verification.global.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(RiskAssessmentController.class)
@Import(GlobalExceptionHandler.class)
class RiskAssessmentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private RiskAssessmentService riskAssessmentService;

    @Test
    void analyze_returnsRiskArray() throws Exception {
        UUID verificationId = UUID.randomUUID();

        RiskItemResponse risk = new RiskItemResponse();
        risk.setId("CVE-2024-0001");
        risk.setSeverity("HIGH");
        risk.setTitle("CVE-2024-0001");
        risk.setDescription("Example vulnerability");

        RiskAnalyzeApiResponse response = new RiskAnalyzeApiResponse();
        response.setAnalysisRunId(UUID.randomUUID());
        response.setOutputStatus(AiOutputStatus.SUPPORTED);
        response.setConfidence(AiConfidence.HIGH);
        response.setRecommendation(AiRecommendation.FIX);
        response.setExplanation("Review required");
        response.setRisks(List.of(risk));

        when(riskAssessmentService.analyze(eq(verificationId))).thenReturn(response);

        mockMvc.perform(post("/api/verifications/{id}/analyze", verificationId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.risks").isArray())
                .andExpect(jsonPath("$.risks[0].id").value("CVE-2024-0001"))
                .andExpect(jsonPath("$.risks[0].severity").value("HIGH"))
                .andExpect(jsonPath("$.recommendation").value("FIX"));
    }
}
