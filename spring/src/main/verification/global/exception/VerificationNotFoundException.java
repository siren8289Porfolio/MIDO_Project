package com.mido.verification.global.exception;

import java.util.UUID;

public class VerificationNotFoundException extends RuntimeException {

    public VerificationNotFoundException(UUID verificationId) {
        super("Verification not found: " + verificationId);
    }
}
