package com.mido.verification.analysis.client;

import com.mido.verification.analysis.client.dto.AiExplainRequest;
import com.mido.verification.analysis.client.dto.AiExplainResponse;
import com.mido.verification.analysis.client.dto.AiRiskAnalyzeRequest;
import com.mido.verification.analysis.client.dto.AiRiskAnalyzeResponse;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
public class AiAnalysisClient {

    private final RestClient aiRestClient;

    public AiAnalysisClient(@Qualifier("aiRestClient") RestClient aiRestClient) {
        this.aiRestClient = aiRestClient;
    }

    public AiRiskAnalyzeResponse analyzeRisk(AiRiskAnalyzeRequest request) {
        try {
            return aiRestClient.post()
                    .uri("/api/v1/risk/analyze")
                    .body(request)
                    .retrieve()
                    .body(AiRiskAnalyzeResponse.class);
        } catch (RestClientException ex) {
            throw new AiServiceException("FastAPI risk analysis call failed", ex);
        }
    }

    public AiExplainResponse explainRisk(AiExplainRequest request) {
        try {
            return aiRestClient.post()
                    .uri("/api/v1/risk/explain")
                    .body(request)
                    .retrieve()
                    .body(AiExplainResponse.class);
        } catch (RestClientException ex) {
            throw new AiServiceException("FastAPI explanation call failed", ex);
        }
    }
}
