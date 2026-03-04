package com.dasi.types.dto.request.admin.manage;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ApiManageRequest {

    private Long id;

    @NotBlank
    private String apiId;

    @NotBlank
    private String apiBaseUrl;

    @NotBlank
    private String apiKey;

    private String apiCompletionsPath;

    private String apiEmbeddingsPath;

    private LocalDateTime updateTime;

}
