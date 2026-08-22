package com.mido.verification.common.repository;

import com.mido.verification.common.entity.VerificationData;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface VerificationDataRepository extends JpaRepository<VerificationData, UUID> {
}
