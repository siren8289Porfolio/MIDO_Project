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
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
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
        byte[] content = file.getBytes();
        String fileContent = new String(content, StandardCharsets.UTF_8);

        UploadedFile uploadedFile = new UploadedFile();
        uploadedFile.setId(UUID.randomUUID());
        uploadedFile.setVerificationData(data);
        uploadedFile.setFileName(file.getOriginalFilename());
        uploadedFile.setFileType(file.getContentType());
        uploadedFile.setFileSizeBytes(file.getSize());
        uploadedFile.setMimeType(file.getContentType());
        uploadedFile.setChecksumSha256(sha256(content));
        uploadedFile.setFileContent(fileContent);
        uploadedFile.setCreatedAt(now);
        uploadedFile.setUpdatedAt(now);
        uploadedFile.setUploadedAt(now);
        uploadedFileRepository.save(uploadedFile);

        data.setCode(fileContent);
        data.setUpdatedAt(now);
    }

    private String sha256(byte[] content) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(content));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 digest is not available", e);
        }
    }
}
