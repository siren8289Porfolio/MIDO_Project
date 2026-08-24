package com.mido.verification.global.exception;

import java.util.UUID;

public class VerificationAlreadyCompletedException extends RuntimeException {

    public VerificationAlreadyCompletedException(UUID verificationId) {
        super("Decision already submitted for verification: " + verificationId);
    }
}
