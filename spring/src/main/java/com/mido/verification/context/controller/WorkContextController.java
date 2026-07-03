package com.mido.verification.context.controller;

import com.mido.verification.context.dto.WorkContextResponse;
import com.mido.verification.context.service.WorkContextService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/verifications")
public class WorkContextController {

    private final WorkContextService workContextService;

    public WorkContextController(WorkContextService workContextService) {
        this.workContextService = workContextService;
    }

    @GetMapping("/{id}/context")
    public ResponseEntity<WorkContextResponse> get(@PathVariable("id") UUID id) {
        return ResponseEntity.ok(workContextService.get(id));
    }
}
