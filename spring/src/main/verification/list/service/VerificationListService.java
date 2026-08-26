package com.mido.verification.list.service;

import com.mido.verification.common.entity.VerificationStatus;
import com.mido.verification.common.repository.VerificationDataRepository;
import com.mido.verification.list.dto.VerificationSummaryResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class VerificationListService {

    private static final int MAX_PAGE_SIZE = 100;

    private final VerificationDataRepository verificationDataRepository;

    public VerificationListService(VerificationDataRepository verificationDataRepository) {
        this.verificationDataRepository = verificationDataRepository;
    }

    @Transactional(readOnly = true)
    public Page<VerificationSummaryResponse> list(String status, int page, int size) {
        VerificationStatus statusFilter = parseStatus(status);
        int safeSize = Math.min(Math.max(size, 1), MAX_PAGE_SIZE);
        int safePage = Math.max(page, 0);

        PageRequest pageable = PageRequest.of(safePage, safeSize, Sort.by(Sort.Direction.DESC, "createdAt"));
        return verificationDataRepository.findSummaries(statusFilter, pageable);
    }

    private VerificationStatus parseStatus(String status) {
        if (status == null || status.isBlank()) {
            return null;
        }
        try {
            return VerificationStatus.valueOf(status.trim().toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw new IllegalArgumentException("Invalid status: " + status);
        }
    }
}
