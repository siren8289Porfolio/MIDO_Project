package com.mido.verification.list.controller;

import com.mido.verification.common.entity.VerificationStatus;
import com.mido.verification.global.exception.GlobalExceptionHandler;
import com.mido.verification.list.dto.VerificationSummaryResponse;
import com.mido.verification.list.service.VerificationListService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(VerificationListController.class)
@Import(GlobalExceptionHandler.class)
class VerificationListControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private VerificationListService verificationListService;

    @Test
    void list_returnsPagedSummaries_withoutCodeField() throws Exception {
        UUID id = UUID.randomUUID();
        VerificationSummaryResponse summary = new VerificationSummaryResponse(
                id, "PASTE", VerificationStatus.DRAFT, Instant.parse("2026-01-01T00:00:00Z"));

        Page<VerificationSummaryResponse> page = new PageImpl<>(
                List.of(summary), PageRequest.of(0, 20), 1);

        when(verificationListService.list(isNull(), eq(0), eq(20))).thenReturn(page);

        mockMvc.perform(get("/api/verifications"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray())
                .andExpect(jsonPath("$.content[0].id").value(id.toString()))
                .andExpect(jsonPath("$.content[0].inputType").value("PASTE"))
                .andExpect(jsonPath("$.content[0].status").value("DRAFT"))
                .andExpect(jsonPath("$.content[0].code").doesNotExist())
                .andExpect(jsonPath("$.totalElements").value(1));
    }

    @Test
    void list_passesStatusFilterAndPagingParams() throws Exception {
        Page<VerificationSummaryResponse> emptyPage = new PageImpl<>(
                List.of(), PageRequest.of(2, 10), 0);

        when(verificationListService.list(eq("DONE"), anyInt(), anyInt())).thenReturn(emptyPage);

        mockMvc.perform(get("/api/verifications").param("status", "DONE").param("page", "2").param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray())
                .andExpect(jsonPath("$.content").isEmpty());
    }

    @Test
    void list_invalidStatus_returnsBadRequest() throws Exception {
        when(verificationListService.list(eq("NOT_A_STATUS"), any(Integer.class), any(Integer.class)))
                .thenThrow(new IllegalArgumentException("Invalid status: NOT_A_STATUS"));

        mockMvc.perform(get("/api/verifications").param("status", "NOT_A_STATUS"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("INVALID_REQUEST"));
    }
}
