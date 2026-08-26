package com.mido.verification.common.repository;

import com.mido.verification.common.entity.VerificationData;
import com.mido.verification.common.entity.VerificationStatus;
import com.mido.verification.da.list.dto.VerificationSummaryResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.UUID;

public interface VerificationDataRepository extends JpaRepository<VerificationData, UUID> {

    /**
     * 목록 조회용 Projection 쿼리. {@code code} LOB을 절대 SELECT하지 않는다.
     * status 필터는 idx_verification_status_created(status, created_at DESC) 인덱스를 탄다.
     */
    @Query("""
            SELECT new com.mido.verification.da.list.dto.VerificationSummaryResponse(
                v.id, v.inputType, v.status, v.createdAt)
            FROM VerificationData v
            WHERE (:status IS NULL OR v.status = :status)
            """)
    Page<VerificationSummaryResponse> findSummaries(@Param("status") VerificationStatus status, Pageable pageable);
}
