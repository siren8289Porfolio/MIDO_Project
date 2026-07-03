package com.mido.verification.upload.repository;

import com.mido.verification.common.entity.VerificationData;
import com.mido.verification.upload.entity.UploadedFile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UploadedFileRepository extends JpaRepository<UploadedFile, UUID> {

    Optional<UploadedFile> findTopByVerificationDataOrderByUploadedAtDesc(VerificationData verificationData);
}
