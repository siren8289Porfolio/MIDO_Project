package com.mido.verification.analysis.dto;

import com.mido.verification.analysis.risk.AiConfidence;
import com.mido.verification.analysis.risk.AiOutputStatus;
import com.mido.verification.analysis.risk.AiRecommendation;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class RiskAnalyzeApiResponse {

    private UUID analysisRunId;
    private AiOutputStatus outputStatus;
    private AiConfidence confidence;
    private AiRecommendation recommendation;
    private String explanation;
    private List<RiskItemResponse> risks = new ArrayList<>();

    public UUID getAnalysisRunId() { return analysisRunId; }
    public void setAnalysisRunId(UUID analysisRunId) { this.analysisRunId = analysisRunId; }
    public AiOutputStatus getOutputStatus() { return outputStatus; }
    public void setOutputStatus(AiOutputStatus outputStatus) { this.outputStatus = outputStatus; }
    public AiConfidence getConfidence() { return confidence; }
    public void setConfidence(AiConfidence confidence) { this.confidence = confidence; }
    public AiRecommendation getRecommendation() { return recommendation; }
    public void setRecommendation(AiRecommendation recommendation) { this.recommendation = recommendation; }
    public String getExplanation() { return explanation; }
    public void setExplanation(String explanation) { this.explanation = explanation; }
    public List<RiskItemResponse> getRisks() { return risks; }
    public void setRisks(List<RiskItemResponse> risks) { this.risks = risks; }
}
