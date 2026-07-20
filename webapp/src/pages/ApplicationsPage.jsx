import { useEffect, useMemo, useState } from 'react';
import { getAllApplications, respondToApplication } from '../api';

function typeText(type) {
  switch (type) {
    case 'LEAVE':
      return 'Xin nghỉ phép';
    case 'LATE':
      return 'Xin đi muộn';
    case 'CERTIFICATE':
      return 'Xin giấy xác nhận';
    default:
      return type;
  }
}

function statusInfo(status) {
  switch (status) {
    case 'APPROVED':
      return { text: 'Đã duyệt', className: 'approved' };
    case 'REJECTED':
      return { text: 'Đã từ chối', className: 'rejected' };
    default:
      return { text: 'Chờ duyệt', className: 'pending' };
  }
}

export default function ApplicationsPage({ auth, onPendingCountChange }) {
  const [applications, setApplications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selected, setSelected] = useState(null);
  const [note, setNote] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [typeFilter, setTypeFilter] = useState('');
  const [classFilter, setClassFilter] = useState('');

  async function loadApplications() {
    setLoading(true);
    setError('');
    try {
      const items = await getAllApplications(auth);
      setApplications(items);
      onPendingCountChange(items.filter((item) => item.status === 'PENDING').length);
    } catch (err) {
      setError(err.message || 'Không tải được danh sách đơn từ');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadApplications();
  }, [auth]);

  const summary = useMemo(
    () => ({
      total: applications.length,
      leave: applications.filter((item) => item.type === 'LEAVE').length,
      late: applications.filter((item) => item.type === 'LATE').length,
      certificate: applications.filter((item) => item.type === 'CERTIFICATE').length,
    }),
    [applications]
  );

  const classOptions = useMemo(
    () => [...new Set(
      applications
        .map((item) => item.student?.className?.trim())
        .filter(Boolean)
    )].sort((a, b) => a.localeCompare(b, 'vi')),
    [applications]
  );

  const filteredApplications = useMemo(
    () => applications.filter((item) => {
      const matchesType = !typeFilter || item.type === typeFilter;
      const matchesClass = !classFilter || item.student?.className === classFilter;
      return matchesType && matchesClass;
    }),
    [applications, typeFilter, classFilter]
  );

  async function handleRespond(status) {
    if (!selected) return;
    setSubmitting(true);
    setError('');
    try {
      await respondToApplication(auth, selected.id, {
        status,
        responseNote: note,
      });
      setSelected(null);
      setNote('');
      await loadApplications();
    } catch (err) {
      setError(err.message || 'Không phản hồi được đơn');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="content-page">
      <div className="page-header">
        <div>
          <h2>Tất cả đơn từ</h2>
          <p>Xem toàn bộ đơn chờ xử lý, đã duyệt và đã từ chối.</p>
        </div>
        <button className="secondary-btn" onClick={loadApplications}>
          Tải lại
        </button>
      </div>

      {error ? <div className="alert error compact">{error}</div> : null}

      <div className="stats-row">
        <div className="mini-card">
          <strong>{summary.total}</strong>
          <span>Tổng đơn</span>
        </div>
        <div className="mini-card">
          <strong>{summary.leave}</strong>
          <span>Xin nghỉ</span>
        </div>
        <div className="mini-card">
          <strong>{summary.late}</strong>
          <span>Đi muộn</span>
        </div>
        <div className="mini-card">
          <strong>{summary.certificate}</strong>
          <span>Giấy xác nhận</span>
        </div>
      </div>

      <div className="card">
        <div className="toolbar">
          <label>
            <span>Loại đơn</span>
            <select value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)}>
              <option value="">Tất cả loại đơn</option>
              <option value="LEAVE">Xin nghỉ phép</option>
              <option value="LATE">Xin đi muộn</option>
              <option value="CERTIFICATE">Xin giấy xác nhận</option>
              <option value="OTHER">Khác</option>
            </select>
          </label>
          <label>
            <span>Lớp</span>
            <select value={classFilter} onChange={(e) => setClassFilter(e.target.value)}>
              <option value="">Tất cả lớp</option>
              {classOptions.map((className) => (
                <option value={className} key={className}>{className}</option>
              ))}
            </select>
          </label>
          <span>{filteredApplications.length} kết quả</span>
        </div>
      </div>

      <div className="card">
        {loading ? (
          <div className="empty-state">Đang tải danh sách đơn...</div>
        ) : filteredApplications.length === 0 ? (
          <div className="empty-state">
            {applications.length === 0 ? 'Chưa có đơn từ nào.' : 'Không có đơn phù hợp với bộ lọc.'}
          </div>
        ) : (
          <div className="application-list">
            {filteredApplications.map((app) => (
              <button
                type="button"
                className="application-card"
                key={app.id}
                onClick={() => {
                  setSelected(app);
                  setNote(app.responseNote || '');
                }}
              >
                <div className="application-card-top">
                  <strong>{app.title}</strong>
                  <span className={`status ${statusInfo(app.status).className}`}>
                    {statusInfo(app.status).text}
                  </span>
                </div>
                <p>{app.student?.fullName || 'N/A'} - {app.student?.className || ''}</p>
                <div className="meta-row">
                  <span>{typeText(app.type)}</span>
                  <span>{app.createdAt || ''}</span>
                </div>
              </button>
            ))}
          </div>
        )}
      </div>

      {selected ? (
        <div className="modal-backdrop" onClick={() => setSelected(null)}>
          <div className="modal-card" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <div>
                <h3>{selected.title}</h3>
                <p>{selected.student?.fullName || 'N/A'} - {selected.student?.className || ''}</p>
              </div>
              <button type="button" className="icon-btn" onClick={() => setSelected(null)}>
                Đóng
              </button>
            </div>

            <div className="application-detail">
              <div className="detail-row">
                <strong>Loại đơn</strong>
                <span>{typeText(selected.type)}</span>
              </div>
              <div className="detail-row">
                <strong>Ngày gửi</strong>
                <span>{selected.createdAt || ''}</span>
              </div>
              <div className="content-box">{selected.content}</div>
              <label>
                <span>Ghi chú phản hồi</span>
                <textarea
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  disabled={selected.status !== 'PENDING'}
                  rows={4}
                  placeholder="Nhập ghi chú nếu cần"
                />
              </label>
              {selected.status === 'PENDING' ? <div className="action-row">
                <button
                  type="button"
                  className="danger-btn"
                  disabled={submitting}
                  onClick={() => handleRespond('REJECTED')}
                >
                  Từ chối
                </button>
                <button
                  type="button"
                  disabled={submitting}
                  onClick={() => handleRespond('APPROVED')}
                >
                  Duyệt đơn
                </button>
              </div> : null}
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
