package com.mido.verification.manual.service;

import com.mido.verification.common.entity.VerificationData;
import com.mido.verification.common.repository.VerificationDataRepository;
import com.mido.verification.context.entity.WorkContext;
import com.mido.verification.context.repository.WorkContextRepository;
import com.mido.verification.manual.dto.ManualInputRequest;
import com.mido.verification.manual.dto.VerificationCreateResponse;
import com.mido.verification.manual.entity.ManualInput;
import com.mido.verification.manual.repository.ManualInputRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Service
public class ManualInputService {

    private final VerificationDataRepository verificationDataRepository;
    private final ManualInputRepository manualInputRepository;
    private final WorkContextRepository workContextRepository;

    public ManualInputService(
            VerificationDataRepository verificationDataRepository,
            ManualInputRepository manualInputRepository,
            WorkContextRepository workContextRepository
    ) {
        this.verificationDataRepository = verificationDataRepository;
        this.manualInputRepository = manualInputRepository;
        this.workContextRepository = workContextRepository;
    }

    @Transactional
    public VerificationCreateResponse create(ManualInputRequest request) {
        Instant now = Instant.now();

        validate(request);

        VerificationData data = new VerificationData();
        data.setId(UUID.randomUUID());
        data.setInputType(request.getInputType());
        data.setRepoUrl(request.getRepoUrl());
        data.setCommitHash(request.getCommitHash());
        data.setPrNumber(request.getPrNumber());
        data.setCode(request.getCode());
        data.setCreatedAt(now);
        data.setUpdatedAt(now);
        verificationDataRepository.save(data);

        ManualInput manualInput = new ManualInput();
        manualInput.setId(UUID.randomUUID());
        manualInput.setVerificationData(data);
        manualInput.setInputMethod(request.getInputMethod());
        manualInput.setRawInput(request.getRawInput());
        manualInput.setCreatedAt(now);
        manualInputRepository.save(manualInput);

        WorkContext context = new WorkContext();
        context.setId(UUID.randomUUID());
        context.setVerificationData(data);
        context.setDisplayRepoUrl(data.getRepoUrl());
        context.setDisplayCommitHash(data.getCommitHash());
        context.setDisplayPrNumber(data.getPrNumber());
        context.setCreatedAt(now);
        workContextRepository.save(context);

        VerificationCreateResponse response = new VerificationCreateResponse();
        response.setId(data.getId());
        response.setStatus(VerificationCreateResponse.Status.DRAFT);
        response.setNextAction(determineNextAction(request.getInputType()));
        return response;
    }

    private void validate(ManualInputRequest request) {
        String type = request.getInputType();
        if (type == null || type.isBlank()) {
            throw new IllegalArgumentException("inputType is required");
        }

        switch (type) {
            case "PASTE" -> requireNotBlank(request.getRawInput(), "rawInput is required for PASTE");
            case "COMMIT" -> {
                requireNotBlank(request.getRepoUrl(), "repoUrl is required for COMMIT");
                requireNotBlank(request.getCommitHash(), "commitHash is required for COMMIT");
            }
            case "PR" -> {
                requireNotBlank(request.getRepoUrl(), "repoUrl is required for PR");
                if (request.getPrNumber() == null || request.getPrNumber() < 1) {
                    throw new IllegalArgumentException("prNumber is required and must be >= 1 for PR");
                }
            }
            case "FILE" -> {
                // FILE 모드에서는 이 단계에서 파일이 오지 않으므로 추가 필수값 없음
            }
            default -> throw new IllegalArgumentException("Unsupported inputType: " + type);
        }
    }

    private void requireNotBlank(String value, String message) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(message);
        }
    }

    private VerificationCreateResponse.NextAction determineNextAction(String inputType) {
        if ("FILE".equals(inputType)) {
            return VerificationCreateResponse.NextAction.UPLOAD_FILE;
        }
        return VerificationCreateResponse.NextAction.VIEW_CONTEXT;
    }
}
