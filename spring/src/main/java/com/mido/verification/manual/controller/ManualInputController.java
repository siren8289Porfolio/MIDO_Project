package com.mido.verification.manual.controller;

import com.mido.verification.manual.dto.ManualInputRequest;
import com.mido.verification.manual.dto.VerificationCreateResponse;
import com.mido.verification.manual.service.ManualInputService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/verifications")
public class ManualInputController {

    private final ManualInputService manualInputService;

    public ManualInputController(ManualInputService manualInputService) {
        this.manualInputService = manualInputService;
    }

    @PostMapping("/manual")
    public ResponseEntity<VerificationCreateResponse> create(@RequestBody ManualInputRequest request) {
        VerificationCreateResponse response = manualInputService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
