package com.mido.verification.common.entity;

import com.mido.verification.context.entity.WorkContext;
import com.mido.verification.manual.entity.ManualInput;
import com.mido.verification.upload.entity.UploadedFile;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "verification_data")
public class VerificationData {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "input_type", nullable = false)
    private String inputType;

    @Column(name = "repo_url")
    private String repoUrl;

    @Column(name = "commit_hash")
    private String commitHash;

    @Column(name = "pr_number")
    private Integer prNumber;

    @Lob
    @Column(name = "code")
    private String code;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;

    @OneToMany(mappedBy = "verificationData")
    private List<ManualInput> manualInputs = new ArrayList<>();

    @OneToMany(mappedBy = "verificationData")
    private List<UploadedFile> uploadedFiles = new ArrayList<>();

    @OneToOne(mappedBy = "verificationData")
    private WorkContext workContext;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getInputType() { return inputType; }
    public void setInputType(String inputType) { this.inputType = inputType; }
    public String getRepoUrl() { return repoUrl; }
    public void setRepoUrl(String repoUrl) { this.repoUrl = repoUrl; }
    public String getCommitHash() { return commitHash; }
    public void setCommitHash(String commitHash) { this.commitHash = commitHash; }
    public Integer getPrNumber() { return prNumber; }
    public void setPrNumber(Integer prNumber) { this.prNumber = prNumber; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
