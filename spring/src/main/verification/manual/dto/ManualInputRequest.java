package com.mido.verification.manual.dto;

public class ManualInputRequest {

    private String inputType;
    private String inputMethod;
    private String repoUrl;
    private String commitHash;
    private Integer prNumber;
    private String rawInput;
    private String code;

    public String getInputType() { return inputType; }
    public void setInputType(String inputType) { this.inputType = inputType; }
    public String getInputMethod() { return inputMethod; }
    public void setInputMethod(String inputMethod) { this.inputMethod = inputMethod; }
    public String getRepoUrl() { return repoUrl; }
    public void setRepoUrl(String repoUrl) { this.repoUrl = repoUrl; }
    public String getCommitHash() { return commitHash; }
    public void setCommitHash(String commitHash) { this.commitHash = commitHash; }
    public Integer getPrNumber() { return prNumber; }
    public void setPrNumber(Integer prNumber) { this.prNumber = prNumber; }
    public String getRawInput() { return rawInput; }
    public void setRawInput(String rawInput) { this.rawInput = rawInput; }
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
}
