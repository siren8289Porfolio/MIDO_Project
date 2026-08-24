package com.mido.verification.analysis.service;

import com.mido.verification.analysis.client.AiAnalysisClient;
import com.mido.verification.analysis.client.dto.AiExplainRequest;
import com.mido.verification.analysis.client.dto.AiExplainResponse;
import com.mido.verification.analysis.client.dto.AiRiskAnalyzeRequest;
import com.mido.verification.analysis.client.dto.AiRiskAnalyzeResponse;
import com.mido.verification.common.entity.VerificationData;
import com.mido.verification.common.repository.VerificationDataRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class RiskAssessmentService {

    private final VerificationDataRepository verificationDataRepository;
    private final AiAnalysisClient aiAnalysisClient;

    public RiskAssessmentService(
            VerificationDataRepository verificationDataRepository,
            AiAnalysisClient aiAnalysisClient
    ) {
        this.verificationDataRepository = verificationDataRepository;
        this.aiAnalysisClient = aiAnalysisClient;
    }

    @Transactional(readOnly = true)
    public AiRiskAnalyzeResponse analyze(UUID verificationId) {
        VerificationData verification = verificationDataRepository.findById(verificationId)
                .orElseThrow(() -> new IllegalArgumentException("Verification not found: " + verificationId));

        AiRiskAnalyzeRequest request = new AiRiskAnalyzeRequest();
        request.setVerificationId(verificationId);
        request.setCode(verification.getCode());
        request.setInputType(verification.getInputType());
        request.setRepoUrl(verification.getRepoUrl());

        return aiAnalysisClient.analyzeRisk(request);
    }

    @Transactional(readOnly = true)
    public AiExplainResponse explain(UUID verificationId, List<AiRiskAnalyzeResponse.RiskFindingDto> risks) {
        VerificationData verification = verificationDataRepository.findById(verificationId)
                .orElseThrow(() -> new IllegalArgumentException("Verification not found: " + verificationId));

        AiExplainRequest request = new AiExplainRequest();
        request.setVerificationId(verificationId);
        request.setRisks(risks);
        request.setInputType(verification.getInputType());
        request.setCodeSummary(summarizeCode(verification.getCode()));

        return aiAnalysisClient.explainRisk(request);
    }

    private String summarizeCode(String code) {
        if (code == null || code.isBlank()) {
            return null;
        }
        String normalized = code.replaceAll("\\s+", " ").trim();
        return normalized.length() <= 240 ? normalized : normalized.substring(0, 240);
    }
}
