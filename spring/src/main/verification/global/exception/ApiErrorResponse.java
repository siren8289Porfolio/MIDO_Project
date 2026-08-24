package com.mido.verification.global.exception;

public class ApiErrorResponse {

    private final boolean success = false;
    private final String errorCode;
    private final String message;

    public ApiErrorResponse(String errorCode, String message) {
        this.errorCode = errorCode;
        this.message = message;
    }

    public boolean isSuccess() { return success; }
    public String getErrorCode() { return errorCode; }
    public String getMessage() { return message; }
}
