package com.mido.verification.global.exception;

import com.mido.verification.analysis.client.AiServiceException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiErrorResponse> handleIllegalArgument(IllegalArgumentException ex) {
        String message = ex.getMessage() == null ? "Invalid request" : ex.getMessage();
        if (message.contains("not found")) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new ApiErrorResponse("VERIFICATION_NOT_FOUND", message));
        }
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ApiErrorResponse("INVALID_REQUEST", message));
    }

    @ExceptionHandler(VerificationNotFoundException.class)
    public ResponseEntity<ApiErrorResponse> handleVerificationNotFound(VerificationNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ApiErrorResponse("VERIFICATION_NOT_FOUND", ex.getMessage()));
    }

    @ExceptionHandler(VerificationAlreadyCompletedException.class)
    public ResponseEntity<ApiErrorResponse> handleAlreadyCompleted(VerificationAlreadyCompletedException ex) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(new ApiErrorResponse("DECISION_ALREADY_SUBMITTED", ex.getMessage()));
    }

    @ExceptionHandler(AiServiceException.class)
    public ResponseEntity<ApiErrorResponse> handleAiServiceFailure(AiServiceException ex) {
        log.warn("External AI service call failed", ex);
        return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                .body(new ApiErrorResponse("EXTERNAL_API_FAILED", "FastAPI AI service call failed"));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiErrorResponse> handleUnhandled(Exception ex) {
        log.error("Unhandled exception", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ApiErrorResponse("INTERNAL_SERVER_ERROR", "Internal server error"));
    }
}
