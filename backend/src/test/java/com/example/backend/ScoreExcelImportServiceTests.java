package com.example.backend;

import com.example.backend.dto.ScoreImportResponse;
import com.example.backend.entity.SchoolClassEntity;
import com.example.backend.entity.SubjectEntity;
import com.example.backend.entity.UserEntity;
import com.example.backend.repository.SchoolClassRepository;
import com.example.backend.repository.ScoreRepository;
import com.example.backend.repository.SubjectRepository;
import com.example.backend.repository.UserRepository;
import com.example.backend.service.ScoreExcelImportService;
import org.apache.poi.ss.usermodel.DataValidation;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ScoreExcelImportServiceTests {

    @Mock private SchoolClassRepository schoolClassRepository;
    @Mock private UserRepository userRepository;
    @Mock private SubjectRepository subjectRepository;
    @Mock private ScoreRepository scoreRepository;

    private ScoreExcelImportService service;
    private SubjectEntity math;

    @BeforeEach
    void setUp() {
        service = new ScoreExcelImportService(
                schoolClassRepository, userRepository, subjectRepository, scoreRepository);
        math = new SubjectEntity();
        math.setId(1);
        math.setCode("TOAN");
        math.setName("Toán học");
        math.setActive(true);
    }

    @Test
    void templateContainsExpectedSheetsHeadersAndValidations() throws Exception {
        when(subjectRepository.findAll()).thenReturn(List.of(math));

        byte[] bytes = service.createTemplate();

        try (Workbook workbook = WorkbookFactory.create(new ByteArrayInputStream(bytes))) {
            assertThat(workbook.getNumberOfSheets()).isEqualTo(2);
            assertThat(workbook.getSheetAt(0).getSheetName()).isEqualTo("Nhap diem");
            assertThat(workbook.getSheetAt(1).getSheetName()).isEqualTo("Huong dan");
            Row header = workbook.getSheetAt(0).getRow(0);
            assertThat(header.getCell(0).getStringCellValue()).isEqualTo("Số điện thoại");
            assertThat(header.getCell(2).getStringCellValue()).isEqualTo("Mã môn");
            assertThat(header.getCell(3).getStringCellValue()).isEqualTo("Điểm");
            List<? extends DataValidation> validations = workbook.getSheetAt(0).getDataValidations();
            assertThat(validations).hasSize(3);
        }
    }

    @Test
    void previewReportsValidDuplicateAndInvalidRowsWithoutSaving() throws Exception {
        UserEntity student = new UserEntity();
        student.setId(10);
        student.setPhoneNumber("0912345678");
        student.setFullName("Nguyễn Văn An");
        SchoolClassEntity schoolClass = new SchoolClassEntity();
        schoolClass.setId(2);
        schoolClass.setUsers(new HashSet<>(List.of(student)));

        when(schoolClassRepository.findById(2)).thenReturn(Optional.of(schoolClass));
        when(userRepository.findByPhoneNumber("0912345678")).thenReturn(Optional.of(student));
        when(subjectRepository.findByCode("TOAN")).thenReturn(Optional.of(math));
        when(scoreRepository.existsByUserIdAndSubjectIdAndAcademicYearAndSemesterAndScoreAndCoefficient(
                any(), any(), any(), any(), any(), any())).thenReturn(false);

        byte[] excel;
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            var sheet = workbook.createSheet("Nhap diem");
            sheet.createRow(0).createCell(0).setCellValue("Số điện thoại");
            sheet.getRow(0).createCell(1).setCellValue("Họ tên");
            sheet.getRow(0).createCell(2).setCellValue("Mã môn");
            sheet.getRow(0).createCell(3).setCellValue("Điểm");
            sheet.getRow(0).createCell(4).setCellValue("Hệ số");
            addRow(sheet.createRow(1), "0912345678", "Nguyễn Văn An", "TOAN", 8.5, 2);
            addRow(sheet.createRow(2), "0912345678", "Nguyễn Văn An", "TOAN", 8.5, 2);
            addRow(sheet.createRow(3), "0912345678", "Nguyễn Văn An", "TOAN", 12, 1);
            workbook.write(output);
            excel = output.toByteArray();
        }

        MockMultipartFile file = new MockMultipartFile(
                "file", "scores.xlsx",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", excel);
        ScoreImportResponse response = service.preview(2, "2025-2026", 1, file);

        assertThat(response.getTotalRows()).isEqualTo(3);
        assertThat(response.getValidRows()).isEqualTo(1);
        assertThat(response.getDuplicateRows()).isEqualTo(1);
        assertThat(response.getErrorRows()).isEqualTo(1);
        assertThat(response.isCanImport()).isFalse();
        assertThat(response.getRows()).extracting(ScoreImportResponse.RowResult::getStatus)
                .containsExactly("VALID", "DUPLICATE", "ERROR");
    }

    private void addRow(Row row, String phone, String name, String subject, double score, double coefficient) {
        row.createCell(0).setCellValue(phone);
        row.createCell(1).setCellValue(name);
        row.createCell(2).setCellValue(subject);
        row.createCell(3).setCellValue(score);
        row.createCell(4).setCellValue(coefficient);
    }
}
