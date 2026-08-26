package com.mido.verification.analysis.client.dto;

import com.mido.verification.de.risk.AiConfidence;
import com.mido.verification.de.risk.AiOutputStatus;
import com.mido.verification.de.risk.AiRecommendation;
import com.mido.verification.de.risk.EvidenceSource;
import com.mido.verification.de.risk.EvidenceStatus;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class AiRiskAnalyzeResponse {

    private UUID analysisRunId;
    private String modelVersion;
    private String promptVersion;
    private AiOutputStatus outputStatus;
    private AiConfidence confidence;
    private AiRecommendation recommendation;
    private List<RiskFindingDto> risks = new ArrayList<>();
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
    public List<RiskFindingDto> getRisks() { return risks; }
    public void setRisks(List<RiskFindingDto> risks) { this.risks = risks; }
    public String getExplanation() { return explanation; }
    public void setExplanation(String explanation) { this.explanation = explanation; }

    public static class RiskFindingDto {
        private String findingId;
        private String riskType;
        private String severity;
        private String description;
        private String cveId;
        private String cweId;
        private String ghsaId;
        private String packageName;
        private String packageVersion;
        private Double cvssScore;
        private boolean kevKnownExploited;
        private EvidenceSource source;
        private String sourceUrl;
        private EvidenceStatus evidenceStatus;

        public String getFindingId() { return findingId; }
        public void setFindingId(String findingId) { this.findingId = findingId; }
        public String getRiskType() { return riskType; }
        public void setRiskType(String riskType) { this.riskType = riskType; }
        public String getSeverity() { return severity; }
        public void setSeverity(String severity) { this.severity = severity; }
        public String getDescription() { return description; }
        public void setDescription(String description) { this.description = description; }
        public String getCveId() { return cveId; }
        public void setCveId(String cveId) { this.cveId = cveId; }
        public String getCweId() { return cweId; }
        public void setCweId(String cweId) { this.cweId = cweId; }
        public String getGhsaId() { return ghsaId; }
        public void setGhsaId(String ghsaId) { this.ghsaId = ghsaId; }
        public String getPackageName() { return packageName; }
        public void setPackageName(String packageName) { this.packageName = packageName; }
        public String getPackageVersion() { return packageVersion; }
        public void setPackageVersion(String packageVersion) { this.packageVersion = packageVersion; }
        public Double getCvssScore() { return cvssScore; }
        public void setCvssScore(Double cvssScore) { this.cvssScore = cvssScore; }
        public boolean isKevKnownExploited() { return kevKnownExploited; }
        public void setKevKnownExploited(boolean kevKnownExploited) { this.kevKnownExploited = kevKnownExploited; }
        public EvidenceSource getSource() { return source; }
        public void setSource(EvidenceSource source) { this.source = source; }
        public String getSourceUrl() { return sourceUrl; }
        public void setSourceUrl(String sourceUrl) { this.sourceUrl = sourceUrl; }
        public EvidenceStatus getEvidenceStatus() { return evidenceStatus; }
        public void setEvidenceStatus(EvidenceStatus evidenceStatus) { this.evidenceStatus = evidenceStatus; }
    }
}
