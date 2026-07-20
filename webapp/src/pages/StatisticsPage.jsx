import { useEffect, useMemo, useState } from 'react';
import { getClassStatistics, getClasses } from '../api';
import { academicYearOptions, currentAcademicPeriod } from '../academic';

const currentPeriod = currentAcademicPeriod();

export default function StatisticsPage({ auth }) {
  const [classes, setClasses] = useState([]);
  const [selectedClassId, setSelectedClassId] = useState('');
  const [statistics, setStatistics] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [academicYear, setAcademicYear] = useState(currentPeriod.academicYear);
  const [semester, setSemester] = useState(currentPeriod.semester);

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
    async function loadStatistics() {
      setLoading(true);
      setError('');
      try {
        const data = await getClassStatistics(auth, selectedClassId, academicYear, semester);
        if (!active) return;
        setStatistics(data);
      } catch (err) {
        if (!active) return;
        setError(err.message || 'Không tải được thống kê');
      } finally {
        if (active) setLoading(false);
      }
    }
    loadStatistics();
    return () => {
      active = false;
    };
  }, [auth, selectedClassId, academicYear, semester]);

  const distribution = useMemo(() => {
    if (!statistics) return [];
    return [
      { label: 'Giỏi', value: statistics.excellentCount, className: 'excellent' },
      { label: 'Khá', value: statistics.goodCount, className: 'good' },
      { label: 'Trung bình', value: statistics.averageCount, className: 'average' },
      { label: 'Yếu', value: statistics.belowAverageCount, className: 'weak' },
    ];
  }, [statistics]);

  return (
    <div className="content-page">
      <div className="page-header">
        <div>
          <h2>Thống kê lớp học</h2>
          <p>Xem sĩ số, điểm trung bình và phân loại học lực theo từng lớp.</p>
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

      {loading ? (
        <div className="card empty-state">Đang tải thống kê...</div>
      ) : !statistics ? (
        <div className="card empty-state">Không có dữ liệu thống kê.</div>
      ) : (
        <div className="statistics-grid">
          <section className="card">
            <h3>{statistics.className} · Học kỳ {semester}</h3>
            <div className="stats-row">
              <div className="mini-card">
                <strong>{statistics.totalStudents}</strong>
                <span>Sĩ số</span>
              </div>
              <div className="mini-card">
                <strong>{statistics.classAverageScore.toFixed(2)}</strong>
                <span>Điểm TB</span>
              </div>
            </div>
          </section>

          <section className="card">
            <h3>Phân loại học lực</h3>
            <div className="distribution-list">
              {distribution.map((item) => {
                const percent = statistics.totalStudents
                  ? (item.value / statistics.totalStudents) * 100
                  : 0;
                return (
                  <div className="distribution-item" key={item.label}>
                    <div className="distribution-head">
                      <strong>{item.label}</strong>
                      <span>{item.value} ({percent.toFixed(0)}%)</span>
                    </div>
                    <div className="distribution-track">
                      <div
                        className={`distribution-fill ${item.className}`}
                        style={{ width: `${percent}%` }}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          </section>

          <section className="card full-width">
            <h3>Thống kê theo môn</h3>
            {statistics.subjectStatistics.length === 0 ? (
              <div className="empty-state small">Chưa có thống kê theo môn.</div>
            ) : (
              <div className="subject-table">
                <div className="subject-table-head">
                  <span>Môn học</span>
                  <span>TB</span>
                  <span>Cao nhất</span>
                  <span>Thấp nhất</span>
                </div>
                {statistics.subjectStatistics.map((subject) => (
                  <div className="subject-row" key={subject.subjectId}>
                    <span>{subject.subjectName}</span>
                    <strong>{subject.averageScore.toFixed(2)}</strong>
                    <span>{subject.highestScore.toFixed(1)}</span>
                    <span>{subject.lowestScore.toFixed(1)}</span>
                  </div>
                ))}
              </div>
            )}
          </section>
        </div>
      )}
    </div>
  );
}
