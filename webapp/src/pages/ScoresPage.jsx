import { useEffect, useRef, useState } from 'react';
import {
  createScore,
  downloadScoreImportTemplate,
  getClasses,
  getStudentsByClass,
  getSubjects,
  importScoresExcel,
  previewScoreImport,
} from '../api';
import { academicYearOptions, currentAcademicPeriod } from '../academic';

const currentPeriod = currentAcademicPeriod();

const initialForm = {
  classId: '',
  studentId: '',
  subjectId: '',
  score: '',
  coefficient: 1,
  academicYear: currentPeriod.academicYear,
  semester: currentPeriod.semester,
};

const initialImportForm = {
  classId: '',
  academicYear: currentPeriod.academicYear,
  semester: currentPeriod.semester,
  file: null,
};

const statusLabel = {
  VALID: 'Hợp lệ',
  DUPLICATE: 'Trùng',
  ERROR: 'Lỗi',
};

export default function ScoresPage({ auth }) {
  const [classes, setClasses] = useState([]);
  const [subjects, setSubjects] = useState([]);
  const [students, setStudents] = useState([]);
  const [form, setForm] = useState(initialForm);
  const [importForm, setImportForm] = useState(initialImportForm);
  const [preview, setPreview] = useState(null);
  const [loading, setLoading] = useState(false);
  const [importLoading, setImportLoading] = useState(false);
  const [studentsLoading, setStudentsLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const fileInputRef = useRef(null);

  useEffect(() => {
    let active = true;
    async function loadInitial() {
      try {
        const [classList, subjectList] = await Promise.all([
          getClasses(auth),
          getSubjects(auth),
        ]);
        if (!active) return;
        setClasses(classList);
        setSubjects(subjectList);
      } catch (err) {
        if (active) setError(err.message || 'Không tải được dữ liệu ban đầu');
      }
    }
    loadInitial();
    return () => { active = false; };
  }, [auth]);

  useEffect(() => {
    if (!form.classId) {
      setStudents([]);
      return;
    }
    let active = true;
    async function loadStudents() {
      setStudentsLoading(true);
      try {
        const data = await getStudentsByClass(auth, form.classId);
        if (active) setStudents(data);
      } catch (err) {
        if (active) setError(err.message || 'Không tải được học sinh');
      } finally {
        if (active) setStudentsLoading(false);
      }
    }
    loadStudents();
    return () => { active = false; };
  }, [auth, form.classId]);

  async function handleSubmit(event) {
    event.preventDefault();
    setLoading(true);
    setError('');
    setMessage('');
    try {
      await createScore(auth, {
        studentId: Number(form.studentId),
        subjectId: Number(form.subjectId),
        score: Number(form.score),
        coefficient: Number(form.coefficient),
        academicYear: form.academicYear,
        semester: Number(form.semester),
      });
      setForm((previous) => ({
        ...previous,
        studentId: '',
        subjectId: '',
        score: '',
        coefficient: 1,
      }));
      setMessage('Đã nhập điểm thành công');
    } catch (err) {
      setError(err.message || 'Không thể lưu điểm');
    } finally {
      setLoading(false);
    }
  }

  function updateImportField(field, value) {
    setImportForm((previous) => ({ ...previous, [field]: value }));
    setPreview(null);
    setMessage('');
  }

  function importPayload() {
    return {
      classId: importForm.classId,
      academicYear: importForm.academicYear,
      semester: String(importForm.semester),
      file: importForm.file,
    };
  }

  async function handlePreview(event) {
    event.preventDefault();
    setImportLoading(true);
    setError('');
    setMessage('');
    try {
      const result = await previewScoreImport(auth, importPayload());
      setPreview(result);
    } catch (err) {
      setPreview(null);
      setError(err.message || 'Không thể đọc file Excel');
    } finally {
      setImportLoading(false);
    }
  }

  async function handleImport() {
    setImportLoading(true);
    setError('');
    setMessage('');
    try {
      const result = await importScoresExcel(auth, importPayload());
      setPreview(result);
      if (result.errorRows > 0) setError(result.message);
      else setMessage(result.message);
      if (result.importedRows > 0) {
        setImportForm((previous) => ({ ...previous, file: null }));
        if (fileInputRef.current) fileInputRef.current.value = '';
      }
    } catch (err) {
      setError(err.message || 'Không thể nhập điểm từ Excel');
    } finally {
      setImportLoading(false);
    }
  }

  async function handleDownloadTemplate() {
    setError('');
    try {
      await downloadScoreImportTemplate(auth);
    } catch (err) {
      setError(err.message || 'Không thể tải file Excel mẫu');
    }
  }

  return (
    <div className="content-page">
      <div className="page-header">
        <div>
          <h2>Nhập điểm học sinh</h2>
          <p>Nhập từng điểm hoặc tải file Excel để xử lý hàng loạt theo học kỳ.</p>
        </div>
      </div>

      {error ? <div className="alert error compact">{error}</div> : null}
      {message ? <div className="alert success compact">{message}</div> : null}

      <div className="card">
        <div className="card-heading">
          <div>
            <h3>Nhập điểm bằng Excel</h3>
            <p>Tải file mẫu, điền dữ liệu, xem trước lỗi rồi mới xác nhận lưu.</p>
          </div>
          <button className="template-link" type="button" onClick={handleDownloadTemplate}>
            Tải file Excel mẫu
          </button>
        </div>

        <form className="form import-form" onSubmit={handlePreview}>
          <label>
            <span>Lớp</span>
            <select value={importForm.classId} onChange={(event) => updateImportField('classId', event.target.value)} required>
              <option value="">-- Chọn lớp --</option>
              {classes.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}
            </select>
          </label>
          <label>
            <span>Năm học</span>
            <select value={importForm.academicYear} onChange={(event) => updateImportField('academicYear', event.target.value)} required>
              {academicYearOptions().map((year) => <option key={year} value={year}>{year}</option>)}
            </select>
          </label>
          <label>
            <span>Học kỳ</span>
            <select value={importForm.semester} onChange={(event) => updateImportField('semester', Number(event.target.value))} required>
              <option value={1}>Học kỳ 1</option>
              <option value={2}>Học kỳ 2</option>
            </select>
          </label>
          <label>
            <span>File .xlsx</span>
            <input
              ref={fileInputRef}
              type="file"
              accept=".xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
              onChange={(event) => updateImportField('file', event.target.files?.[0] ?? null)}
              required
            />
          </label>
          <div className="submit-row import-actions">
            <button type="submit" disabled={importLoading}>
              {importLoading ? 'Đang kiểm tra...' : 'Xem trước và kiểm tra lỗi'}
            </button>
          </div>
        </form>

        {preview ? (
          <div className="import-preview">
            <div className="import-summary">
              <span>Tổng: <strong>{preview.totalRows}</strong></span>
              <span className="valid-text">Hợp lệ: <strong>{preview.validRows}</strong></span>
              <span className="duplicate-text">Trùng: <strong>{preview.duplicateRows}</strong></span>
              <span className="error-text">Lỗi: <strong>{preview.errorRows}</strong></span>
            </div>
            <p className={preview.errorRows ? 'preview-message error-text' : 'preview-message valid-text'}>{preview.message}</p>
            <div className="import-table-wrap">
              <table className="import-table">
                <thead>
                  <tr><th>Dòng</th><th>Học sinh</th><th>Số điện thoại</th><th>Mã môn</th><th>Điểm</th><th>Hệ số</th><th>Trạng thái</th><th>Chi tiết</th></tr>
                </thead>
                <tbody>
                  {preview.rows.map((row) => (
                    <tr key={`${row.rowNumber}-${row.subjectCode}`}>
                      <td>{row.rowNumber}</td>
                      <td>{row.studentName || '—'}</td>
                      <td>{row.phoneNumber || '—'}</td>
                      <td>{row.subjectCode || '—'}</td>
                      <td>{row.score ?? '—'}</td>
                      <td>{row.coefficient ?? '—'}</td>
                      <td><span className={`import-status ${row.status.toLowerCase()}`}>{statusLabel[row.status]}</span></td>
                      <td>{row.message}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div className="import-confirm-row">
              <button type="button" onClick={handleImport} disabled={importLoading || !preview.canImport || preview.importedRows > 0}>
                {importLoading ? 'Đang nhập...' : 'Xác nhận nhập điểm'}
              </button>
              {preview.errorRows > 0 ? <small>Sửa toàn bộ dòng lỗi trong file rồi xem trước lại.</small> : null}
            </div>
          </div>
        ) : null}
      </div>

      <div className="card manual-score-card">
        <div className="card-heading"><div><h3>Nhập một điểm</h3><p>Dùng khi cần thêm nhanh một đầu điểm cho học sinh.</p></div></div>
        <form className="form two-col" onSubmit={handleSubmit}>
          <label>
            <span>Chọn lớp</span>
            <select value={form.classId} onChange={(event) => setForm((previous) => ({ ...previous, classId: event.target.value, studentId: '' }))} required>
              <option value="">-- Chọn lớp --</option>
              {classes.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}
            </select>
          </label>
          <label>
            <span>Chọn học sinh</span>
            <select value={form.studentId} onChange={(event) => setForm((previous) => ({ ...previous, studentId: event.target.value }))} disabled={!form.classId || studentsLoading} required>
              <option value="">{studentsLoading ? 'Đang tải...' : '-- Chọn học sinh --'}</option>
              {students.map((item) => <option key={item.id} value={item.id}>{item.fullName || 'N/A'} ({item.phoneNumber || ''})</option>)}
            </select>
          </label>
          <label>
            <span>Năm học</span>
            <select value={form.academicYear} onChange={(event) => setForm((previous) => ({ ...previous, academicYear: event.target.value }))} required>
              {academicYearOptions().map((year) => <option key={year} value={year}>{year}</option>)}
            </select>
          </label>
          <label>
            <span>Học kỳ</span>
            <select value={form.semester} onChange={(event) => setForm((previous) => ({ ...previous, semester: Number(event.target.value) }))} required>
              <option value={1}>Học kỳ 1</option><option value={2}>Học kỳ 2</option>
            </select>
          </label>
          <label>
            <span>Chọn môn học</span>
            <select value={form.subjectId} onChange={(event) => setForm((previous) => ({ ...previous, subjectId: event.target.value }))} required>
              <option value="">-- Chọn môn học --</option>
              {subjects.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}
            </select>
          </label>
          <label>
            <span>Điểm</span>
            <input type="number" step="0.1" min="0" max="10" value={form.score} onChange={(event) => setForm((previous) => ({ ...previous, score: event.target.value }))} placeholder="0 - 10" required />
          </label>
          <label className="coefficient-row">
            <span>Hệ số</span>
            <div className="chip-row">
              {[1, 2, 3].map((value) => (
                <button type="button" key={value} className={Number(form.coefficient) === value ? 'chip active' : 'chip'} onClick={() => setForm((previous) => ({ ...previous, coefficient: value }))}>{value}</button>
              ))}
            </div>
          </label>
          <div className="submit-row"><button type="submit" disabled={loading}>{loading ? 'Đang lưu...' : 'Lưu điểm'}</button></div>
        </form>
      </div>
    </div>
  );
}
