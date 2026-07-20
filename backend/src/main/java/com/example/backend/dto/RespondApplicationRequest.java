package com.example.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RespondApplicationRequest {

    @NotBlank(message = "Trạng thái không được để trống")
    private String status;

    private String responseNote;
}
