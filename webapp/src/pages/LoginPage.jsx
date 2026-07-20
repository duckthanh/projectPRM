import { useState } from 'react';
import { Link } from 'react-router-dom';

export default function LoginPage({ onLogin }) {
  const [phoneNumber, setPhoneNumber] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(event) {
    event.preventDefault();
    setLoading(true);
    setError('');
    try {
      await onLogin({
        phoneNumber: phoneNumber.trim(),
        password: password.trim(),
      });
    } catch (err) {
      setError(err.message || 'Không thể đăng nhập');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-page">
      <div className="auth-card">
        <div className="logo-circle">M</div>
        <h1>Đăng nhập giáo viên</h1>
        <p>Đăng nhập để sử dụng đầy đủ các chức năng giáo viên trên web.</p>

        {error ? <div className="alert error compact">{error}</div> : null}

        <form className="form" onSubmit={handleSubmit}>
          <label>
            <span>Số điện thoại</span>
            <input
              value={phoneNumber}
              onChange={(e) => setPhoneNumber(e.target.value)}
              placeholder="Nhập số điện thoại"
              required
            />
          </label>

          <label>
            <span>Mật khẩu</span>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Nhập mật khẩu"
              required
            />
          </label>

          <button type="submit" disabled={loading}>
            {loading ? 'Đang đăng nhập...' : 'Đăng nhập'}
          </button>
        </form>

        <div className="auth-footer">
          <Link to="/forgot-password">Quên mật khẩu?</Link>
        </div>
      </div>
    </div>
  );
}
