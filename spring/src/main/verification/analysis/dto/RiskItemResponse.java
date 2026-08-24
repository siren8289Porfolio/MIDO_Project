package com.mido.verification.analysis.dto;

public class RiskItemResponse {

    private String id;
    private String severity;
    private String title;
    private String description;
    private String cveId;
    private String ghsaId;
    private String packageName;
    private String packageVersion;
    private String source;
    private String sourceUrl;
    private String evidenceStatus;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getSeverity() { return severity; }
    public void setSeverity(String severity) { this.severity = severity; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getCveId() { return cveId; }
    public void setCveId(String cveId) { this.cveId = cveId; }
    public String getGhsaId() { return ghsaId; }
    public void setGhsaId(String ghsaId) { this.ghsaId = ghsaId; }
    public String getPackageName() { return packageName; }
    public void setPackageName(String packageName) { this.packageName = packageName; }
    public String getPackageVersion() { return packageVersion; }
    public void setPackageVersion(String packageVersion) { this.packageVersion = packageVersion; }
    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }
    public String getSourceUrl() { return sourceUrl; }
    public void setSourceUrl(String sourceUrl) { this.sourceUrl = sourceUrl; }
    public String getEvidenceStatus() { return evidenceStatus; }
    public void setEvidenceStatus(String evidenceStatus) { this.evidenceStatus = evidenceStatus; }
}
