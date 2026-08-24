package com.mido.verification.analysis.client.dto;

import com.mido.verification.analysis.risk.AiConfidence;
import com.mido.verification.analysis.risk.AiOutputStatus;
import com.mido.verification.analysis.risk.AiRecommendation;
import com.mido.verification.analysis.risk.EvidenceSource;
import com.mido.verification.analysis.risk.EvidenceStatus;

import java.util.List;
import java.util.UUID;

public class AiRiskAnalyzeRequest {

    private UUID verificationId;
    private String code;
    private List<DependencyCoordinateDto> dependencies;
    private String inputType;
    private String repoUrl;

    public UUID getVerificationId() { return verificationId; }
    public void setVerificationId(UUID verificationId) { this.verificationId = verificationId; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public List<DependencyCoordinateDto> getDependencies() { return dependencies; }
    public void setDependencies(List<DependencyCoordinateDto> dependencies) { this.dependencies = dependencies; }
    public String getInputType() { return inputType; }
    public void setInputType(String inputType) { this.inputType = inputType; }
    public String getRepoUrl() { return repoUrl; }
    public void setRepoUrl(String repoUrl) { this.repoUrl = repoUrl; }

    public static class DependencyCoordinateDto {
        private String ecosystem;
        private String name;
        private String version;

        public DependencyCoordinateDto() {
        }

        public DependencyCoordinateDto(String ecosystem, String name, String version) {
            this.ecosystem = ecosystem;
            this.name = name;
            this.version = version;
        }

        public String getEcosystem() { return ecosystem; }
        public void setEcosystem(String ecosystem) { this.ecosystem = ecosystem; }
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        public String getVersion() { return version; }
        public void setVersion(String version) { this.version = version; }
    }
}
