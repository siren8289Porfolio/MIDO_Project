package com.mido.verification.manual.dto;

import java.util.UUID;

/**
 * OpenAPI의 VerificationCreateResponse 스키마에 대응하는 생성 응답 DTO.
 */
public class VerificationCreateResponse {

    public enum Status {
        DRAFT,
        READY,
        PROCESSING,
        DONE,
        FAILED
    }

    public enum NextAction {
        UPLOAD_FILE,
        VIEW_CONTEXT,
        WAIT
    }

    private UUID id;
    private Status status;
    private NextAction nextAction;

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public Status getStatus() {
        return status;
    }

    public void setStatus(Status status) {
        this.status = status;
    }

    public NextAction getNextAction() {
        return nextAction;
    }

    public void setNextAction(NextAction nextAction) {
        this.nextAction = nextAction;
    }
}
