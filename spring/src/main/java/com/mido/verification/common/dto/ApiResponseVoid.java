package com.mido.verification.common.dto;

/**
 * OpenAPI의 ApiResponseVoid 스키마에 대응하는 공통 응답 래퍼.
 *
 * <p>데이터가 없는 성공/실패 응답을 표현할 때 사용한다.</p>
 */
public class ApiResponseVoid {

    private boolean success;
    private Object data;
    private String message;

    public ApiResponseVoid() {
    }

    public ApiResponseVoid(boolean success, Object data, String message) {
        this.success = success;
        this.data = data;
        this.message = message;
    }

    public static ApiResponseVoid ok() {
        return new ApiResponseVoid(true, null, "ok");
    }

    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public Object getData() {
        return data;
    }

    public void setData(Object data) {
        this.data = data;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
