package com.mido.verification.da.list.dto;

import com.mido.verification.common.entity.VerificationStatus;

import java.time.Instant;
import java.util.UUID;

/**
 * 목록 조회 전용 Projection. {@code code} LOB은 절대 포함하지 않는다.
 *
 * <p>DA-02 §5.3 "LOB 핵심 규칙"을 코드로 구현한 DTO다.</p>
 */
public class VerificationSummaryResponse {

    private final UUID id;
    private final String inputType;
    private final VerificationStatus status;
    private final Instant createdAt;

    public VerificationSummaryResponse(UUID id, String inputType, VerificationStatus status, Instant createdAt) {
        this.id = id;
        this.inputType = inputType;
        this.status = status;
        this.createdAt = createdAt;
    }

    public UUID getId() {
        return id;
    }

    public String getInputType() {
        return inputType;
    }

    public VerificationStatus getStatus() {
        return status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
