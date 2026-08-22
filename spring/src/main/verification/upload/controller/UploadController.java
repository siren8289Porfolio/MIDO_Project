package com.mido.verification.upload.controller;

import com.mido.verification.common.dto.ApiResponseVoid;
import com.mido.verification.upload.service.UploadService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.UUID;

@RestController
@RequestMapping("/api/verifications")
public class UploadController {

    private final UploadService uploadService;

    public UploadController(UploadService uploadService) {
        this.uploadService = uploadService;
    }

    @PostMapping("/{id}/upload")
    public ResponseEntity<ApiResponseVoid> upload(
            @PathVariable("id") UUID id,
            @RequestParam("file") MultipartFile file
    ) throws IOException {
        uploadService.upload(id, file);
        return ResponseEntity.ok(ApiResponseVoid.ok());
    }
}
