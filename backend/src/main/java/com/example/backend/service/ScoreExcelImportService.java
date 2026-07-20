package com.example.backend.service;

import com.example.backend.dto.ScoreImportResponse;
import com.example.backend.entity.SchoolClassEntity;
import com.example.backend.entity.ScoreEntity;
import com.example.backend.entity.SubjectEntity;
import com.example.backend.entity.UserEntity;
import com.example.backend.repository.SchoolClassRepository;
import com.example.backend.repository.ScoreRepository;
import com.example.backend.repository.SubjectRepository;
import com.example.backend.repository.UserRepository;
import com.example.backend.util.AcademicPeriodUtils;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.DataValidation;
import org.apache.poi.ss.usermodel.DataValidationConstraint;
import org.apache.poi.ss.usermodel.DataValidationHelper;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.FormulaEvaluator;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.ss.util.CellRangeAddressList;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.text.Normalizer;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class ScoreExcelImportService {

    private static final String VALID = "VALID";
    private static final String DUPLICATE = "DUPLICATE";
    private static final String ERROR = "ERROR";
    private static final DateTimeFormatter CREATED_AT_FORMAT =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final SchoolClassRepository schoolClassRepository;
    private final UserRepository userRepository;
    private final SubjectRepository subjectRepository;
    private final ScoreRepository scoreRepository;

    @Transactional(readOnly = true)
    public byte[] createTemplate() {
        List<SubjectEntity> subjects = subjectRepository.findAll().stream()
                .filter(subject -> Boolean.TRUE.equals(subject.getActive()))
                .sorted((left, right) -> left.getCode().compareToIgnoreCase(right.getCode()))
                .toList();

        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            Sheet inputSheet = workbook.createSheet("Nhap diem");
            Sheet guideSheet = workbook.createSheet("Huong dan");
            inputSheet.setDisplayGridlines(false);
            guideSheet.setDisplayGridlines(false);
            inputSheet.createFreezePane(0, 1);

            CellStyle headerStyle = createHeaderStyle(workbook);
            CellStyle textStyle = workbook.createCellStyle();
            textStyle.setDataFormat(workbook.createDataFormat().getFormat("@"));
            CellStyle decimalStyle = workbook.createCellStyle();
            decimalStyle.setDataFormat(workbook.createDataFormat().getFormat("0.0"));

            Row header = inputSheet.createRow(0);
            String[] headers = {"Số điện thoại", "Họ tên", "Mã môn", "Điểm", "Hệ số"};
            for (int column = 0; column < headers.length; column++) {
                Cell cell = header.createCell(column);
                cell.setCellValue(headers[column]);
                cell.setCellStyle(headerStyle);
            }
            header.setHeightInPoints(26);
            inputSheet.setAutoFilter(new CellRangeAddress(0, 500, 0, 4));
            inputSheet.setColumnWidth(0, 18 * 256);
            inputSheet.setColumnWidth(1, 28 * 256);
            inputSheet.setColumnWidth(2, 15 * 256);
            inputSheet.setColumnWidth(3, 12 * 256);
            inputSheet.setColumnWidth(4, 12 * 256);

            for (int index = 1; index <= 500; index++) {
                Row row = inputSheet.createRow(index);
                row.createCell(0).setCellStyle(textStyle);
                row.createCell(1).setCellStyle(textStyle);
                row.createCell(2).setCellStyle(textStyle);
                row.createCell(3).setCellStyle(decimalStyle);
                row.createCell(4).setCellStyle(decimalStyle);
            }

            DataValidationHelper validationHelper = inputSheet.getDataValidationHelper();
            addDecimalValidation(validationHelper, inputSheet, 3, 0, 10,
                    "Điểm không hợp lệ", "Điểm phải nằm trong khoảng từ 0 đến 10");
            addListValidation(validationHelper, inputSheet, 4, new String[]{"1", "2", "3"},
                    "Hệ số không hợp lệ", "Hệ số chỉ nhận 1, 2 hoặc 3");
            if (!subjects.isEmpty()) {
                addListValidation(validationHelper, inputSheet, 2,
                        subjects.stream().map(SubjectEntity::getCode).toArray(String[]::new),
                        "Mã môn không hợp lệ", "Hãy chọn mã môn trong danh sách");
            }

            createGuideSheet(guideSheet, workbook, headerStyle, subjects);
            workbook.write(output);
            return output.toByteArray();
        } catch (IOException ex) {
            throw new IllegalStateException("Không thể tạo file Excel mẫu", ex);
        }
    }

    @Transactional(readOnly = true)
    public ScoreImportResponse preview(
            Integer classId,
            String academicYear,
            Integer semester,
            MultipartFile file) {
        return process(classId, academicYear, semester, file, false);
    }

    @Transactional
    public ScoreImportResponse importScores(
            Integer classId,
            String academicYear,
            Integer semester,
            MultipartFile file) {
        return process(classId, academicYear, semester, file, true);
    }

    private ScoreImportResponse process(
            Integer classId,
            String academicYear,
            Integer semester,
            MultipartFile file,
            boolean persist) {
        String year = AcademicPeriodUtils.normalizeAcademicYear(academicYear);
        int term = AcademicPeriodUtils.normalizeSemester(semester);
        SchoolClassEntity schoolClass = schoolClassRepository.findById(classId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lớp học"));
        validateFile(file);

        List<ScoreImportResponse.RowResult> rows = new ArrayList<>();
        List<ScoreEntity> scoresToSave = new ArrayList<>();
        Set<String> fileKeys = new HashSet<>();

        try (Workbook workbook = WorkbookFactory.create(file.getInputStream())) {
            if (workbook.getNumberOfSheets() == 0) {
                throw new IllegalArgumentException("File Excel không có trang dữ liệu");
            }
            Sheet sheet = workbook.getSheetAt(0);
            FormulaEvaluator evaluator = workbook.getCreationHelper().createFormulaEvaluator();
            DataFormatter formatter = new DataFormatter(Locale.US);
            HeaderInfo header = findHeader(sheet, formatter, evaluator);

            for (int index = header.rowIndex() + 1; index <= sheet.getLastRowNum(); index++) {
                Row row = sheet.getRow(index);
                if (isBlankRow(row, header, formatter, evaluator)) {
                    continue;
                }
                ParsedRow parsed = parseRow(row, header, formatter, evaluator);
                ScoreImportResponse.RowResult result = validateRow(
                        parsed, index + 1, schoolClass, year, term, fileKeys, scoresToSave);
                rows.add(result);
            }
        } catch (IllegalArgumentException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new IllegalArgumentException("Không thể đọc file Excel. Hãy dùng file .xlsx mẫu hợp lệ", ex);
        }

        int errorCount = (int) rows.stream().filter(row -> ERROR.equals(row.getStatus())).count();
        int duplicateCount = (int) rows.stream().filter(row -> DUPLICATE.equals(row.getStatus())).count();
        int validCount = (int) rows.stream().filter(row -> VALID.equals(row.getStatus())).count();
        int importedCount = 0;

        if (persist && errorCount == 0 && !scoresToSave.isEmpty()) {
            scoreRepository.saveAll(scoresToSave);
            importedCount = scoresToSave.size();
        }

        boolean canImport = errorCount == 0 && validCount > 0;
        String message;
        if (rows.isEmpty()) {
            message = "File chưa có dòng điểm nào";
        } else if (errorCount > 0) {
            message = "Có " + errorCount + " dòng lỗi. Chưa có dữ liệu nào được lưu";
        } else if (persist) {
            message = "Đã nhập " + importedCount + " dòng điểm"
                    + (duplicateCount > 0 ? ", bỏ qua " + duplicateCount + " dòng trùng" : "");
        } else {
            message = "File hợp lệ và sẵn sàng nhập"
                    + (duplicateCount > 0 ? "; sẽ bỏ qua " + duplicateCount + " dòng trùng" : "");
        }

        return ScoreImportResponse.builder()
                .totalRows(rows.size())
                .validRows(validCount)
                .duplicateRows(duplicateCount)
                .errorRows(errorCount)
                .importedRows(importedCount)
                .canImport(canImport)
                .message(message)
                .rows(rows)
                .build();
    }

    private ScoreImportResponse.RowResult validateRow(
            ParsedRow parsed,
            int rowNumber,
            SchoolClassEntity schoolClass,
            String academicYear,
            int semester,
            Set<String> fileKeys,
            List<ScoreEntity> scoresToSave) {
        List<String> errors = new ArrayList<>();
        String phone = normalizePhone(parsed.phoneNumber());
        String subjectCode = parsed.subjectCode() == null
                ? ""
                : parsed.subjectCode().trim().toUpperCase(Locale.ROOT);

        if (phone.isBlank()) errors.add("Thiếu số điện thoại học sinh");
        if (subjectCode.isBlank()) errors.add("Thiếu mã môn");
        if (parsed.score() == null) errors.add("Điểm phải là số");
        else if (parsed.score() < 0 || parsed.score() > 10) errors.add("Điểm phải từ 0 đến 10");
        if (parsed.coefficient() == null) errors.add("Hệ số phải là số");
        else if (parsed.coefficient() != 1 && parsed.coefficient() != 2 && parsed.coefficient() != 3) {
            errors.add("Hệ số chỉ nhận 1, 2 hoặc 3");
        }

        UserEntity student = phone.isBlank() ? null : userRepository.findByPhoneNumber(phone).orElse(null);
        if (!phone.isBlank() && student == null) {
            errors.add("Không tìm thấy học sinh theo số điện thoại");
        } else if (student != null && schoolClass.getUsers().stream()
                .noneMatch(user -> user.getId().equals(student.getId()))) {
            errors.add("Học sinh không thuộc lớp đã chọn");
        }

        SubjectEntity subject = subjectCode.isBlank()
                ? null
                : subjectRepository.findByCode(subjectCode).orElse(null);
        if (!subjectCode.isBlank() && subject == null) {
            errors.add("Mã môn không tồn tại");
        } else if (subject != null && !Boolean.TRUE.equals(subject.getActive())) {
            errors.add("Môn học đang ngừng hoạt động");
        }

        String studentName = student != null ? student.getFullName() : parsed.studentName();
        if (!errors.isEmpty()) {
            return rowResult(rowNumber, phone, studentName, subjectCode, parsed, ERROR, String.join("; ", errors));
        }

        String key = student.getId() + "|" + subject.getId() + "|" + academicYear + "|"
                + semester + "|" + parsed.score() + "|" + parsed.coefficient();
        boolean duplicateInFile = !fileKeys.add(key);
        boolean duplicateInDatabase = scoreRepository
                .existsByUserIdAndSubjectIdAndAcademicYearAndSemesterAndScoreAndCoefficient(
                        student.getId(), subject.getId(), academicYear, semester,
                        parsed.score(), parsed.coefficient());
        if (duplicateInFile || duplicateInDatabase) {
            String reason = duplicateInFile ? "Trùng với dòng trước trong file" : "Điểm đã tồn tại trong hệ thống";
            return rowResult(rowNumber, phone, studentName, subjectCode, parsed, DUPLICATE, reason);
        }

        ScoreEntity score = new ScoreEntity();
        score.setUser(student);
        score.setSubject(subject);
        score.setScore(parsed.score());
        score.setCoefficient(parsed.coefficient());
        score.setAcademicYear(academicYear);
        score.setSemester(semester);
        score.setCreatedAt(LocalDateTime.now().format(CREATED_AT_FORMAT));
        scoresToSave.add(score);
        return rowResult(rowNumber, phone, studentName, subjectCode, parsed, VALID, "Hợp lệ");
    }

    private ScoreImportResponse.RowResult rowResult(
            int rowNumber,
            String phone,
            String studentName,
            String subjectCode,
            ParsedRow parsed,
            String status,
            String message) {
        return ScoreImportResponse.RowResult.builder()
                .rowNumber(rowNumber)
                .phoneNumber(phone)
                .studentName(studentName)
                .subjectCode(subjectCode)
                .score(parsed.score())
                .coefficient(parsed.coefficient())
                .status(status)
                .message(message)
                .build();
    }

    private HeaderInfo findHeader(Sheet sheet, DataFormatter formatter, FormulaEvaluator evaluator) {
        int lastCandidate = Math.min(sheet.getLastRowNum(), 9);
        for (int rowIndex = sheet.getFirstRowNum(); rowIndex <= lastCandidate; rowIndex++) {
            Row row = sheet.getRow(rowIndex);
            if (row == null) continue;
            Map<String, Integer> columns = new HashMap<>();
            for (Cell cell : row) {
                String header = normalizeHeader(cellText(cell, formatter, evaluator));
                if (isPhoneHeader(header)) columns.put("phone", cell.getColumnIndex());
                else if (header.equals("ho ten") || header.equals("ten hoc sinh")) columns.put("name", cell.getColumnIndex());
                else if (header.equals("ma mon") || header.equals("ma mon hoc")) columns.put("subject", cell.getColumnIndex());
                else if (header.equals("diem")) columns.put("score", cell.getColumnIndex());
                else if (header.equals("he so")) columns.put("coefficient", cell.getColumnIndex());
            }
            if (columns.keySet().containsAll(Set.of("phone", "subject", "score", "coefficient"))) {
                return new HeaderInfo(
                        rowIndex,
                        columns.get("phone"),
                        columns.getOrDefault("name", -1),
                        columns.get("subject"),
                        columns.get("score"),
                        columns.get("coefficient"));
            }
        }
        throw new IllegalArgumentException(
                "Không tìm thấy đủ cột: Số điện thoại, Mã môn, Điểm, Hệ số");
    }

    private boolean isPhoneHeader(String header) {
        return header.equals("so dien thoai")
                || header.equals("sdt")
                || header.equals("sdt hoc sinh")
                || header.equals("ma/sdt hoc sinh");
    }

    private ParsedRow parseRow(Row row, HeaderInfo header, DataFormatter formatter, FormulaEvaluator evaluator) {
        String phone = phoneText(row.getCell(header.phoneColumn()), formatter, evaluator);
        String name = header.nameColumn() >= 0
                ? cellText(row.getCell(header.nameColumn()), formatter, evaluator).trim()
                : "";
        String subject = cellText(row.getCell(header.subjectColumn()), formatter, evaluator).trim();
        Double score = parseNumber(row.getCell(header.scoreColumn()), formatter, evaluator);
        Double coefficient = parseNumber(row.getCell(header.coefficientColumn()), formatter, evaluator);
        return new ParsedRow(phone, name, subject, score, coefficient);
    }

    private boolean isBlankRow(Row row, HeaderInfo header, DataFormatter formatter, FormulaEvaluator evaluator) {
        if (row == null) return true;
        return cellText(row.getCell(header.phoneColumn()), formatter, evaluator).isBlank()
                && cellText(row.getCell(header.subjectColumn()), formatter, evaluator).isBlank()
                && cellText(row.getCell(header.scoreColumn()), formatter, evaluator).isBlank()
                && cellText(row.getCell(header.coefficientColumn()), formatter, evaluator).isBlank();
    }

    private Double parseNumber(Cell cell, DataFormatter formatter, FormulaEvaluator evaluator) {
        String value = cellText(cell, formatter, evaluator).trim().replace(',', '.');
        if (value.isBlank()) return null;
        try {
            return Double.valueOf(value);
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private String phoneText(Cell cell, DataFormatter formatter, FormulaEvaluator evaluator) {
        if (cell == null) return "";
        CellType type = cell.getCellType() == CellType.FORMULA
                ? evaluator.evaluateFormulaCell(cell)
                : cell.getCellType();
        if (type == CellType.NUMERIC) {
            return BigDecimal.valueOf(cell.getNumericCellValue()).stripTrailingZeros().toPlainString();
        }
        return cellText(cell, formatter, evaluator).trim();
    }

    private String cellText(Cell cell, DataFormatter formatter, FormulaEvaluator evaluator) {
        return cell == null ? "" : formatter.formatCellValue(cell, evaluator).trim();
    }

    private String normalizePhone(String phone) {
        String value = phone == null ? "" : phone.trim().replaceAll("[\\s.-]", "");
        if (value.matches("\\d{9}")) value = "0" + value;
        return value;
    }

    private String normalizeHeader(String value) {
        return Normalizer.normalize(value == null ? "" : value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .replace('đ', 'd')
                .replace('Đ', 'D')
                .toLowerCase(Locale.ROOT)
                .replaceAll("\\s+", " ")
                .trim();
    }

    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Vui lòng chọn file Excel");
        }
        String name = file.getOriginalFilename();
        if (name == null || !name.toLowerCase(Locale.ROOT).endsWith(".xlsx")) {
            throw new IllegalArgumentException("Chỉ hỗ trợ file Excel định dạng .xlsx");
        }
    }

    private CellStyle createHeaderStyle(Workbook workbook) {
        CellStyle style = workbook.createCellStyle();
        style.setFillForegroundColor(IndexedColors.DARK_BLUE.getIndex());
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        Font font = workbook.createFont();
        font.setBold(true);
        font.setColor(IndexedColors.WHITE.getIndex());
        style.setFont(font);
        return style;
    }

    private void addDecimalValidation(
            DataValidationHelper helper,
            Sheet sheet,
            int column,
            int minimum,
            int maximum,
            String title,
            String message) {
        DataValidationConstraint constraint = helper.createDecimalConstraint(
                DataValidationConstraint.OperatorType.BETWEEN,
                String.valueOf(minimum), String.valueOf(maximum));
        addValidation(helper, sheet, column, constraint, title, message);
    }

    private void addListValidation(
            DataValidationHelper helper,
            Sheet sheet,
            int column,
            String[] values,
            String title,
            String message) {
        DataValidationConstraint constraint = helper.createExplicitListConstraint(values);
        addValidation(helper, sheet, column, constraint, title, message);
    }

    private void addValidation(
            DataValidationHelper helper,
            Sheet sheet,
            int column,
            DataValidationConstraint constraint,
            String title,
            String message) {
        CellRangeAddressList addressList = new CellRangeAddressList(1, 500, column, column);
        DataValidation validation = helper.createValidation(constraint, addressList);
        validation.setShowErrorBox(true);
        validation.createErrorBox(title, message);
        sheet.addValidationData(validation);
    }

    private void createGuideSheet(
            Sheet sheet,
            Workbook workbook,
            CellStyle headerStyle,
            List<SubjectEntity> subjects) {
        sheet.setColumnWidth(0, 18 * 256);
        sheet.setColumnWidth(1, 42 * 256);
        Row title = sheet.createRow(0);
        title.createCell(0).setCellValue("HƯỚNG DẪN NHẬP ĐIỂM");
        title.getCell(0).setCellStyle(headerStyle);
        sheet.addMergedRegion(new CellRangeAddress(0, 0, 0, 1));

        String[][] instructions = {
                {"Bước 1", "Chọn đúng lớp, năm học và học kỳ trên website."},
                {"Bước 2", "Điền dữ liệu trong trang 'Nhap diem', từ dòng 2."},
                {"Số điện thoại", "Phải đúng số điện thoại tài khoản học sinh thuộc lớp đã chọn."},
                {"Họ tên", "Cột tham khảo, có thể để trống; hệ thống nhận diện bằng số điện thoại."},
                {"Mã môn", "Chọn một mã môn đang hoạt động trong danh sách bên dưới."},
                {"Điểm", "Nhập số từ 0 đến 10."},
                {"Hệ số", "Chỉ nhập 1, 2 hoặc 3."},
                {"Lưu ý", "Không đổi tên các cột. Dòng sai sẽ chặn toàn bộ lần nhập; dòng trùng được bỏ qua."}
        };
        for (int index = 0; index < instructions.length; index++) {
            Row row = sheet.createRow(index + 2);
            row.createCell(0).setCellValue(instructions[index][0]);
            row.createCell(1).setCellValue(instructions[index][1]);
        }

        int subjectHeaderRow = instructions.length + 4;
        Row subjectHeader = sheet.createRow(subjectHeaderRow);
        subjectHeader.createCell(0).setCellValue("Mã môn");
        subjectHeader.createCell(1).setCellValue("Tên môn");
        subjectHeader.getCell(0).setCellStyle(headerStyle);
        subjectHeader.getCell(1).setCellStyle(headerStyle);
        for (int index = 0; index < subjects.size(); index++) {
            SubjectEntity subject = subjects.get(index);
            Row row = sheet.createRow(subjectHeaderRow + index + 1);
            row.createCell(0).setCellValue(subject.getCode());
            row.createCell(1).setCellValue(subject.getName());
        }
        sheet.createFreezePane(0, 1);
    }

    private record HeaderInfo(
            int rowIndex,
            int phoneColumn,
            int nameColumn,
            int subjectColumn,
            int scoreColumn,
            int coefficientColumn) {
    }

    private record ParsedRow(
            String phoneNumber,
            String studentName,
            String subjectCode,
            Double score,
            Double coefficient) {
    }
}
