package com.mido.verification.analysis.client.dto;

import com.mido.verification.de.risk.AiConfidence;
import com.mido.verification.de.risk.AiOutputStatus;
import com.mido.verification.de.risk.AiRecommendation;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class AiExplainRequest {

    private UUID verificationId;
    private List<AiRiskAnalyzeResponse.RiskFindingDto> risks = new ArrayList<>();
    private String codeSummary;
    private String inputType;

    public UUID getVerificationId() { return verificationId; }
    public void setVerificationId(UUID verificationId) { this.verificationId = verificationId; }
    public List<AiRiskAnalyzeResponse.RiskFindingDto> getRisks() { return risks; }
    public void setRisks(List<AiRiskAnalyzeResponse.RiskFindingDto> risks) { this.risks = risks; }
    public String getCodeSummary() { return codeSummary; }
    public void setCodeSummary(String codeSummary) { this.codeSummary = codeSummary; }
    public String getInputType() { return inputType; }
    public void setInputType(String inputType) { this.inputType = inputType; }
}
