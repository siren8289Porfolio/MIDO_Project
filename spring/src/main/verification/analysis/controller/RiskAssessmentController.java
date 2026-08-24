package com.mido.verification.analysis.controller;

import com.mido.verification.analysis.dto.RiskAnalyzeApiResponse;
import com.mido.verification.analysis.service.RiskAssessmentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/verifications")
public class RiskAssessmentController {

    private final RiskAssessmentService riskAssessmentService;

    public RiskAssessmentController(RiskAssessmentService riskAssessmentService) {
        this.riskAssessmentService = riskAssessmentService;
    }

    @PostMapping("/{id}/analyze")
    public ResponseEntity<RiskAnalyzeApiResponse> analyze(@PathVariable("id") UUID id) {
        return ResponseEntity.ok(riskAssessmentService.analyze(id));
    }
}
