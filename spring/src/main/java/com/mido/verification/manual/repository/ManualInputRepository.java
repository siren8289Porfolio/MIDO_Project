package com.mido.verification.manual.repository;

import com.mido.verification.manual.entity.ManualInput;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface ManualInputRepository extends JpaRepository<ManualInput, UUID> {
}
