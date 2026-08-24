package com.mido.verification.analysis.service;

import com.mido.verification.analysis.client.AiAnalysisClient;
import com.mido.verification.analysis.client.dto.AiExplainRequest;
import com.mido.verification.analysis.client.dto.AiExplainResponse;
import com.mido.verification.analysis.client.dto.AiRiskAnalyzeRequest;
import com.mido.verification.analysis.client.dto.AiRiskAnalyzeResponse;
import com.mido.verification.analysis.dto.RiskAnalyzeApiResponse;
import com.mido.verification.analysis.dto.RiskItemResponse;
import com.mido.verification.common.entity.VerificationData;
import com.mido.verification.common.entity.VerificationStatus;
import com.mido.verification.common.repository.VerificationDataRepository;
import com.mido.verification.global.exception.VerificationAlreadyCompletedException;
import com.mido.verification.global.exception.VerificationNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
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

    @Transactional
    public RiskAnalyzeApiResponse analyze(UUID verificationId) {
        VerificationData verification = verificationDataRepository.findById(verificationId)
                .orElseThrow(() -> new VerificationNotFoundException(verificationId));

        if (verification.getStatus() == VerificationStatus.DONE) {
            throw new VerificationAlreadyCompletedException(verificationId);
        }

        verification.setStatus(VerificationStatus.RUNNING);
        verification.setUpdatedAt(Instant.now());
        verificationDataRepository.save(verification);

        try {
            AiRiskAnalyzeResponse aiResponse = aiAnalysisClient.analyzeRisk(buildAnalyzeRequest(verification));
            verification.setStatus(VerificationStatus.READY);
            verification.setUpdatedAt(Instant.now());
            verificationDataRepository.save(verification);
            return toApiResponse(aiResponse);
        } catch (RuntimeException ex) {
            verification.setStatus(VerificationStatus.FAILED);
            verification.setUpdatedAt(Instant.now());
            verificationDataRepository.save(verification);
            throw ex;
        }
    }

    @Transactional(readOnly = true)
    public AiExplainResponse explain(UUID verificationId, List<AiRiskAnalyzeResponse.RiskFindingDto> risks) {
        VerificationData verification = verificationDataRepository.findById(verificationId)
                .orElseThrow(() -> new VerificationNotFoundException(verificationId));

        AiExplainRequest request = new AiExplainRequest();
        request.setVerificationId(verificationId);
        request.setRisks(risks);
        request.setInputType(verification.getInputType());
        request.setCodeSummary(summarizeCode(verification.getCode()));

        return aiAnalysisClient.explainRisk(request);
    }

    private AiRiskAnalyzeRequest buildAnalyzeRequest(VerificationData verification) {
        AiRiskAnalyzeRequest request = new AiRiskAnalyzeRequest();
        request.setVerificationId(verification.getId());
        request.setCode(verification.getCode());
        request.setInputType(verification.getInputType());
        request.setRepoUrl(verification.getRepoUrl());
        return request;
    }

    private RiskAnalyzeApiResponse toApiResponse(AiRiskAnalyzeResponse aiResponse) {
        RiskAnalyzeApiResponse response = new RiskAnalyzeApiResponse();
        response.setAnalysisRunId(aiResponse.getAnalysisRunId());
        response.setOutputStatus(aiResponse.getOutputStatus());
        response.setConfidence(aiResponse.getConfidence());
        response.setRecommendation(aiResponse.getRecommendation());
        response.setExplanation(aiResponse.getExplanation());
        response.setRisks(aiResponse.getRisks().stream().map(this::toRiskItem).toList());
        return response;
    }

    private RiskItemResponse toRiskItem(AiRiskAnalyzeResponse.RiskFindingDto finding) {
        RiskItemResponse item = new RiskItemResponse();
        item.setId(finding.getFindingId());
        item.setSeverity(normalizeSeverity(finding.getSeverity()));
        item.setTitle(buildTitle(finding));
        item.setDescription(finding.getDescription());
        item.setCveId(finding.getCveId());
        item.setGhsaId(finding.getGhsaId());
        item.setPackageName(finding.getPackageName());
        item.setPackageVersion(finding.getPackageVersion());
        item.setSource(finding.getSource() == null ? null : finding.getSource().name());
        item.setSourceUrl(finding.getSourceUrl());
        item.setEvidenceStatus(finding.getEvidenceStatus() == null ? null : finding.getEvidenceStatus().name());
        return item;
    }

    private String buildTitle(AiRiskAnalyzeResponse.RiskFindingDto finding) {
        if (finding.getCveId() != null && !finding.getCveId().isBlank()) {
            return finding.getCveId();
        }
        if (finding.getGhsaId() != null && !finding.getGhsaId().isBlank()) {
            return finding.getGhsaId();
        }
        if (finding.getPackageName() != null && finding.getPackageVersion() != null) {
            return finding.getPackageName() + "@" + finding.getPackageVersion();
        }
        return finding.getRiskType();
    }

    private String normalizeSeverity(String severity) {
        if (severity == null || severity.isBlank()) {
            return "UNKNOWN";
        }
        return switch (severity.toUpperCase()) {
            case "CRITICAL", "HIGH", "MEDIUM", "LOW" -> severity.toUpperCase();
            default -> "MEDIUM";
        };
    }

    private String summarizeCode(String code) {
        if (code == null || code.isBlank()) {
            return null;
        }
        String normalized = code.replaceAll("\\s+", " ").trim();
        return normalized.length() <= 240 ? normalized : normalized.substring(0, 240);
    }
}
