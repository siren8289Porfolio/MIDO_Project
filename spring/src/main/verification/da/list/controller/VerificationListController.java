package com.mido.verification.da.list.controller;

import com.mido.verification.da.list.dto.VerificationSummaryResponse;
import com.mido.verification.da.list.service.VerificationListService;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/verifications")
public class VerificationListController {

    private final VerificationListService verificationListService;

    public VerificationListController(VerificationListService verificationListService) {
        this.verificationListService = verificationListService;
    }

    @GetMapping
    public ResponseEntity<Page<VerificationSummaryResponse>> list(
            @RequestParam(value = "status", required = false) String status,
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "20") int size
    ) {
        return ResponseEntity.ok(verificationListService.list(status, page, size));
    }
}
