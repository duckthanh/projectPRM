package com.example.backend.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class SmsService {

    @Value("${sms.api-key:}")
    private String apiKey;

    @Value("${sms.secret-key:}")
    private String secretKey;

    @Value("${sms.brand-name:Baotrixemay}")
    private String brandName;

    @Value("${sms.enabled:false}")
    private boolean smsEnabled;

    private final RestTemplate restTemplate = new RestTemplate();

    public boolean sendOtp(String phoneNumber, String otp) {
        String message = "Ma xac thuc cua ban la: " + otp + ". Ma co hieu luc trong 5 phut.";
        return sendSms(phoneNumber, message);
    }

    public boolean sendSms(String phoneNumber, String message) {
        if (!smsEnabled) {
            log.info("SMS disabled. Would send to {}: {}", phoneNumber, message);
            System.out.println(" To: " + phoneNumber);
            System.out.println(" OTP: " + extractOtp(message));
            return true;
        }

        try {

            String baseUrl = "http://rest.esms.vn/MainService.svc/json/SendMultipleMessage_V4_get";


            String encodedMessage = URLEncoder.encode(message, StandardCharsets.UTF_8.toString());
            String formattedPhone = formatPhoneNumber(phoneNumber);


            String fullUrl = String.format(
                "%s?Phone=%s&Content=%s&ApiKey=%s&SecretKey=%s&SmsType=4",
                baseUrl,
                formattedPhone,
                encodedMessage,
                apiKey,
                secretKey
            );

            log.info("Sending SMS to {} via eSMS", formattedPhone);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<String> request = new HttpEntity<>(headers);

            @SuppressWarnings("rawtypes")
            ResponseEntity<Map> response = restTemplate.exchange(
                fullUrl,
                HttpMethod.GET,
                request,
                Map.class
            );

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> resBody = response.getBody();
                Object codeResult = resBody.get("CodeResult");
                String code = codeResult != null ? codeResult.toString() : "";

                if ("100".equals(code)) {
                    log.info("eSMS sent successfully to {}", phoneNumber);
                    return true;
                }

                String errorMsg = getEsmsErrorMessage(code);
                log.error("eSMS error code {}: {}", code, errorMsg);
            }

            log.error("Failed to send SMS via eSMS: {}", response.getBody());
            return false;

        } catch (Exception e) {
            log.error("Error sending SMS to {}: {}", phoneNumber, e.getMessage());
            return false;
        }
    }

    private String formatPhoneNumber(String phoneNumber) {
        if (phoneNumber == null) return "";
        String cleaned = phoneNumber.replaceAll("[^0-9]", "");


        if (cleaned.startsWith("+84")) {
            return "0" + cleaned.substring(3);
        }
        if (cleaned.startsWith("84") && cleaned.length() > 9) {
            return "0" + cleaned.substring(2);
        }
        return cleaned;
    }

    private String extractOtp(String message) {
        java.util.regex.Matcher matcher = java.util.regex.Pattern.compile("\\d{6}").matcher(message);
        return matcher.find() ? matcher.group() : "N/A";
    }

    private String getEsmsErrorMessage(String code) {
        return switch (code) {
            case "100" -> "Thành công";
            case "101" -> "Chưa đăng nhập";
            case "102" -> "Tài khoản bị khóa";
            case "103" -> "Số dư không đủ";
            case "104" -> "Brandname không tồn tại";
            case "105" -> "Tin nhắn chứa từ ngữ bị chặn";
            case "106" -> "Số điện thoại không hợp lệ";
            case "107" -> "Nội dung tin nhắn rỗng";
            case "108" -> "SmsType không hợp lệ";
            case "109" -> "Sai API Key hoặc Secret Key";
            default -> "Lỗi không xác định: " + code;
        };
    }
}
