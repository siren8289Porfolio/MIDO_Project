package com.mido.verification.context.entity;

import com.mido.verification.common.entity.VerificationData;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "work_context")
public class WorkContext {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "verification_data_id", nullable = false)
    private VerificationData verificationData;

    @Column(name = "display_repo_url")
    private String displayRepoUrl;

    @Column(name = "display_commit_hash", length = 128)
    private String displayCommitHash;

    @Column(name = "display_pr_number")
    private Integer displayPrNumber;

    @Column(name = "source_system", nullable = false, length = 64)
    private String sourceSystem = "MIDO";

    @Column(name = "schema_version", nullable = false)
    private Integer schemaVersion = 1;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public VerificationData getVerificationData() { return verificationData; }
    public void setVerificationData(VerificationData verificationData) { this.verificationData = verificationData; }
    public String getDisplayRepoUrl() { return displayRepoUrl; }
    public void setDisplayRepoUrl(String displayRepoUrl) { this.displayRepoUrl = displayRepoUrl; }
    public String getDisplayCommitHash() { return displayCommitHash; }
    public void setDisplayCommitHash(String displayCommitHash) { this.displayCommitHash = displayCommitHash; }
    public Integer getDisplayPrNumber() { return displayPrNumber; }
    public void setDisplayPrNumber(Integer displayPrNumber) { this.displayPrNumber = displayPrNumber; }
    public String getSourceSystem() { return sourceSystem; }
    public void setSourceSystem(String sourceSystem) { this.sourceSystem = sourceSystem; }
    public Integer getSchemaVersion() { return schemaVersion; }
    public void setSchemaVersion(Integer schemaVersion) { this.schemaVersion = schemaVersion; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
