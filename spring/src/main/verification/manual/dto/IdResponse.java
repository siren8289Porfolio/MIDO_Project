package com.mido.verification.manual.dto;

import java.util.UUID;

public class IdResponse {

    private UUID id;

    public IdResponse() {}
    public IdResponse(UUID id) { this.id = id; }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
}
