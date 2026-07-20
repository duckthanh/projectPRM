import { useEffect, useMemo, useState } from 'react';
import { getClassScores, getClasses, getStudentAcademicSummary } from '../api';
import { academicYearOptions, currentAcademicPeriod } from '../academic';

const currentPeriod = currentAcademicPeriod();
const displayScore = (value) => value == null ? '—' : Number(value).toFixed(2);

function averageBadge(avg) {
  if (avg >= 8.5) return { label: 'Giỏi', className: 'level excellent' };
  if (avg >= 7) return { label: 'Khá', className: 'level good' };
  if (avg >= 5) return { label: 'TB', className: 'level average' };
  return { label: 'Yếu', className: 'level weak' };
}

export default function StudentsPage({ auth }) {
  const [classes, setClasses] = useState([]);
  const [selectedClassId, setSelectedClassId] = useState('');
  const [students, setStudents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedStudent, setSelectedStudent] = useState(null);
  const [academicYear, setAcademicYear] = useState(currentPeriod.academicYear);
  const [semester, setSemester] = useState(currentPeriod.semester);
  const [academicSummary, setAcademicSummary] = useState(null);
  const [summaryLoading, setSummaryLoading] = useState(false);

  useEffect(() => {
    let active = true;
    async function loadClasses() {
      try {
        const classList = await getClasses(auth);
        if (!active) return;
        setClasses(classList);
        if (classList.length > 0) {
          setSelectedClassId(String(classList[0].id));
        } else {
          setLoading(false);
        }
      } catch (err) {
        if (!active) return;
        setError(err.message || 'Không tải được danh sách lớp');
        setLoading(false);
      }
    }
    loadClasses();
    return () => {
      active = false;
    };
  }, [auth]);

  useEffect(() => {
    if (!selectedClassId) return;
    let active = true;
    async function loadStudents() {
      setLoading(true);
      setError('');
      try {
        const data = await getClassScores(auth, selectedClassId, academicYear, semester);
        if (!active) return;
        setStudents(data);
      } catch (err) {
        if (!active) return;
        setError(err.message || 'Không tải được danh sách học sinh');
      } finally {
        if (active) setLoading(false);
      }
    }
    loadStudents();
    return () => {
      active = false;
    };
  }, [auth, selectedClassId, academicYear, semester]);

  async function openStudent(student) {
    setSelectedStudent(student);
    setAcademicSummary(null);
    setSummaryLoading(true);
    try {
      setAcademicSummary(await getStudentAcademicSummary(auth, student.studentId, academicYear));
    } catch (err) {
      setError(err.message || 'Không tải được tổng kết năm học');
    } finally {
      setSummaryLoading(false);
    }
  }

  const selectedClass = useMemo(
    () => classes.find((item) => String(item.id) === String(selectedClassId)),
    [classes, selectedClassId]
  );

  return (
    <div className="content-page">
      <div className="page-header">
        <div>
          <h2>Học sinh theo lớp</h2>
          <p>Xem danh sách học sinh và điểm trung bình của từng em.</p>
        </div>
        <div className="toolbar">
          <select value={academicYear} onChange={(e) => setAcademicYear(e.target.value)}>
            {academicYearOptions().map((year) => (
              <option value={year} key={year}>{year}</option>
            ))}
          </select>
          <select value={semester} onChange={(e) => setSemester(Number(e.target.value))}>
            <option value={1}>Học kỳ 1</option>
            <option value={2}>Học kỳ 2</option>
          </select>
          <select value={selectedClassId} onChange={(e) => setSelectedClassId(e.target.value)}>
            {classes.map((item) => (
              <option value={item.id} key={item.id}>
                {item.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {error ? <div className="alert error compact">{error}</div> : null}

      <div className="card">
        <div className="section-title">
          <strong>{selectedClass?.name || 'Danh sách học sinh'}</strong>
          <span>{students.length} học sinh</span>
        </div>

        {loading ? (
          <div className="empty-state">Đang tải dữ liệu...</div>
        ) : students.length === 0 ? (
          <div className="empty-state">Không có học sinh trong lớp này.</div>
        ) : (
          <div className="student-grid">
            {students.map((student) => {
              const badge = averageBadge(student.averageScore);
              return (
                <button
                  type="button"
                  className="student-card"
                  key={student.studentId}
                  onClick={() => openStudent(student)}
                >
                  <div className="student-card-top">
                    <div className="avatar">{student.studentName?.[0] || '?'}</div>
                    <span className={badge.className}>{badge.label}</span>
                  </div>
                  <strong>{student.studentName}</strong>
                  <p>{student.className || selectedClass?.name || 'Chưa có lớp'}</p>
                  <div className="score-line">
                    TB học kỳ {semester}: <span>{student.averageScore.toFixed(2)}</span>
                  </div>
                </button>
              );
            })}
          </div>
        )}
      </div>

      {selectedStudent ? (
        <div className="modal-backdrop" onClick={() => setSelectedStudent(null)}>
          <div className="modal-card" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <div>
                <h3>{selectedStudent.studentName}</h3>
                <p>{academicYear} · Học kỳ {semester} · TB {selectedStudent.averageScore.toFixed(2)}</p>
              </div>
              <button type="button" className="icon-btn" onClick={() => setSelectedStudent(null)}>
                Đóng
              </button>
            </div>

            <div className="detail-list">
              {selectedStudent.scores.length === 0 ? (
                <div className="empty-state small">Học sinh này chưa có điểm.</div>
              ) : (
                selectedStudent.scores.map((score) => (
                  <div className="detail-row" key={score.scoreId}>
                    <div>
                      <strong>{score.subjectName}</strong>
                      <p>Hệ số {score.coefficient}</p>
                    </div>
                    <span className={score.score >= 5 ? 'value good' : 'value bad'}>
                      {score.score.toFixed(1)}
                    </span>
                  </div>
                ))
              )}
            </div>

            <div className="section-title">
              <strong>Tổng kết năm học {academicYear}</strong>
            </div>
            {summaryLoading ? (
              <div className="empty-state small">Đang tính tổng kết...</div>
            ) : academicSummary ? (
              <>
                <div className="stats-row">
                  <div className="mini-card"><strong>{displayScore(academicSummary.semester1Average)}</strong><span>TB học kỳ 1</span></div>
                  <div className="mini-card"><strong>{displayScore(academicSummary.semester2Average)}</strong><span>TB học kỳ 2</span></div>
                  <div className="mini-card"><strong>{displayScore(academicSummary.yearlyAverage)}</strong><span>TB cả năm</span></div>
                </div>
                <div className="subject-table">
                  <div className="subject-table-head">
                    <span>Môn học</span><span>HK1</span><span>HK2</span><span>Cả năm</span>
                  </div>
                  {academicSummary.subjects.map((subject) => (
                    <div className="subject-row" key={subject.subjectId}>
                      <span>{subject.subjectName}</span>
                      <span>{displayScore(subject.semester1Average)}</span>
                      <span>{displayScore(subject.semester2Average)}</span>
                      <strong>{displayScore(subject.yearlyAverage)}</strong>
                    </div>
                  ))}
                </div>
              </>
            ) : null}
          </div>
        </div>
      ) : null}
    </div>
  );
}
