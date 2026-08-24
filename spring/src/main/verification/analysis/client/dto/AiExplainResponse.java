package com.mido.verification.analysis.client.dto;

import com.mido.verification.analysis.risk.AiConfidence;
import com.mido.verification.analysis.risk.AiOutputStatus;
import com.mido.verification.analysis.risk.AiRecommendation;

import java.util.UUID;

public class AiExplainResponse {

    private UUID analysisRunId;
    private String modelVersion;
    private String promptVersion;
    private AiOutputStatus outputStatus;
    private AiConfidence confidence;
    private AiRecommendation recommendation;
    private String explanation;

    public UUID getAnalysisRunId() { return analysisRunId; }
    public void setAnalysisRunId(UUID analysisRunId) { this.analysisRunId = analysisRunId; }
    public String getModelVersion() { return modelVersion; }
    public void setModelVersion(String modelVersion) { this.modelVersion = modelVersion; }
    public String getPromptVersion() { return promptVersion; }
    public void setPromptVersion(String promptVersion) { this.promptVersion = promptVersion; }
    public AiOutputStatus getOutputStatus() { return outputStatus; }
    public void setOutputStatus(AiOutputStatus outputStatus) { this.outputStatus = outputStatus; }
    public AiConfidence getConfidence() { return confidence; }
    public void setConfidence(AiConfidence confidence) { this.confidence = confidence; }
    public AiRecommendation getRecommendation() { return recommendation; }
    public void setRecommendation(AiRecommendation recommendation) { this.recommendation = recommendation; }
    public String getExplanation() { return explanation; }
    public void setExplanation(String explanation) { this.explanation = explanation; }
}
