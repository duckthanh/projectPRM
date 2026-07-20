import { useState } from 'react';
import { Navigate } from 'react-router-dom';

export default function OtpPage({ pendingLogin, onVerifyOtp, onResendOtp }) {
  const [otp, setOtp] = useState('');
  const [loading, setLoading] = useState(false);
  const [resending, setResending] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  if (!pendingLogin) {
    return <Navigate to="/login" replace />;
  }

  async function handleSubmit(event) {
    event.preventDefault();
    setLoading(true);
    setError('');
    try {
      await onVerifyOtp(otp.trim());
    } catch (err) {
      setError(err.message || 'Không xác thực được OTP');
    } finally {
      setLoading(false);
    }
  }

  async function handleResend() {
    setResending(true);
    setError('');
    setSuccess('');
    try {
      await onResendOtp();
      setSuccess('Đã gửi lại mã OTP');
    } catch (err) {
      setError(err.message || 'Không gửi lại được OTP');
    } finally {
      setResending(false);
    }
  }

  return (
    <div className="auth-page">
      <div className="auth-card">
        <div className="logo-circle">OTP</div>
        <h1>Xác thực 2 bước</h1>
        <p>Mã OTP đã được gửi đến {pendingLogin.phoneNumber}.</p>

        {error ? <div className="alert error compact">{error}</div> : null}
        {success ? <div className="alert success compact">{success}</div> : null}

        <form className="form" onSubmit={handleSubmit}>
          <label>
            <span>Mã OTP</span>
            <input
              value={otp}
              onChange={(e) => setOtp(e.target.value)}
              placeholder="Nhập mã OTP"
              maxLength={6}
              required
            />
          </label>

          <button type="submit" disabled={loading}>
            {loading ? 'Đang xác thực...' : 'Xác nhận OTP'}
          </button>
        </form>

        <button className="ghost-action" onClick={handleResend} disabled={resending}>
          {resending ? 'Đang gửi lại...' : 'Gửi lại OTP'}
        </button>
      </div>
    </div>
  );
}
