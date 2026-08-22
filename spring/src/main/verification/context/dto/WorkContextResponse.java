package com.mido.verification.context.dto;

import com.mido.verification.context.entity.WorkContext;

/**
 * OpenAPI의 WorkContextResponse(oneOf) 스키마에 대응하는 DTO.
 *
 * <p>contextType에 따라 COMMIT / PR / PASTE / FILE 형태로 분기되어 사용된다.</p>
 */
public class WorkContextResponse {

    private String contextType;
    private String repoUrl;
    private String commitHash;
    private Integer prNumber;
    private String fileName;
    private String language;
    private Integer lineCount;
    private String snippet;

    public static WorkContextResponse from(WorkContext ctx) {
        WorkContextResponse r = new WorkContextResponse();
        r.setRepoUrl(ctx.getDisplayRepoUrl());
        r.setCommitHash(ctx.getDisplayCommitHash());
        r.setPrNumber(ctx.getDisplayPrNumber());
        return r;
    }

    public String getContextType() {
        return contextType;
    }

    public void setContextType(String contextType) {
        this.contextType = contextType;
    }

    public String getRepoUrl() {
        return repoUrl;
    }

    public void setRepoUrl(String repoUrl) {
        this.repoUrl = repoUrl;
    }

    public String getCommitHash() {
        return commitHash;
    }

    public void setCommitHash(String commitHash) {
        this.commitHash = commitHash;
    }

    public Integer getPrNumber() {
        return prNumber;
    }

    public void setPrNumber(Integer prNumber) {
        this.prNumber = prNumber;
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public Integer getLineCount() {
        return lineCount;
    }

    public void setLineCount(Integer lineCount) {
        this.lineCount = lineCount;
    }

    public String getSnippet() {
        return snippet;
    }

    public void setSnippet(String snippet) {
        this.snippet = snippet;
    }
}
