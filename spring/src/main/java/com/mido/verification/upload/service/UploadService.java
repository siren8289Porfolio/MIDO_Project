package com.mido.verification.upload.service;

import com.mido.verification.common.entity.VerificationData;
import com.mido.verification.common.repository.VerificationDataRepository;
import com.mido.verification.upload.entity.UploadedFile;
import com.mido.verification.upload.repository.UploadedFileRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.UUID;

@Service
public class UploadService {

    private final VerificationDataRepository verificationDataRepository;
    private final UploadedFileRepository uploadedFileRepository;

    public UploadService(
            VerificationDataRepository verificationDataRepository,
            UploadedFileRepository uploadedFileRepository
    ) {
        this.verificationDataRepository = verificationDataRepository;
        this.uploadedFileRepository = uploadedFileRepository;
    }

    @Transactional
    public void upload(UUID verificationId, MultipartFile file) throws IOException {
        VerificationData data = verificationDataRepository.findById(verificationId)
                .orElseThrow(() -> new IllegalArgumentException("VerificationData not found: " + verificationId));

        Instant now = Instant.now();

        UploadedFile uploadedFile = new UploadedFile();
        uploadedFile.setId(UUID.randomUUID());
        uploadedFile.setVerificationData(data);
        uploadedFile.setFileName(file.getOriginalFilename());
        uploadedFile.setFileType(file.getContentType());
        uploadedFile.setFileContent(new String(file.getBytes(), StandardCharsets.UTF_8));
        uploadedFile.setUploadedAt(now);
        uploadedFileRepository.save(uploadedFile);

        data.setCode(uploadedFile.getFileContent());
        data.setUpdatedAt(now);
    }
}
