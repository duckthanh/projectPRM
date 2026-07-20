import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { resetPassword, sendResetOtp, verifyResetOtp } from '../api';

export default function ForgotPasswordPage() {
  const navigate = useNavigate();
  const [step, setStep] = useState(1);
  const [phoneNumber, setPhoneNumber] = useState('');
  const [otp, setOtp] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  async function handleSendOtp(event) {
    event.preventDefault();
    setLoading(true);
    setError('');
    setSuccess('');
    try {
      const response = await sendResetOtp(phoneNumber.trim());
      setSuccess(response.message || 'Đã gửi mã OTP');
      setStep(2);
    } catch (err) {
      setError(err.message || 'Không gửi được mã OTP');
    } finally {
      setLoading(false);
    }
  }

  async function handleVerifyOtp(event) {
    event.preventDefault();
    setLoading(true);
    setError('');
    setSuccess('');
    try {
      const response = await verifyResetOtp(phoneNumber.trim(), otp.trim());
      setSuccess(response.message || 'Mã OTP hợp lệ');
      setStep(3);
    } catch (err) {
      setError(err.message || 'OTP không hợp lệ');
    } finally {
      setLoading(false);
    }
  }

  async function handleResetPassword(event) {
    event.preventDefault();
    if (newPassword.length < 6) {
      setError('Mật khẩu mới phải có ít nhất 6 ký tự');
      return;
    }
    if (newPassword !== confirmPassword) {
      setError('Mật khẩu xác nhận không khớp');
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');
    try {
      const response = await resetPassword(
        phoneNumber.trim(),
        otp.trim(),
        newPassword
      );
      setSuccess(response.message || 'Đặt lại mật khẩu thành công');
      setTimeout(() => navigate('/login'), 1200);
    } catch (err) {
      setError(err.message || 'Không đặt lại được mật khẩu');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-page">
      <div className="auth-card">
        <div className="logo-circle">FP</div>
        <h1>Quên mật khẩu giáo viên</h1>
        <p>Thực hiện theo 3 bước để nhận OTP và đặt lại mật khẩu trên web.</p>

        <div className="stepper">
          {[1, 2, 3].map((item) => (
            <div
              key={item}
              className={item <= step ? 'step-item active' : 'step-item'}
            >
              <span>{item}</span>
              <small>
                {item === 1 ? 'SĐT' : item === 2 ? 'OTP' : 'Mật khẩu mới'}
              </small>
            </div>
          ))}
        </div>

        {error ? <div className="alert error compact">{error}</div> : null}
        {success ? <div className="alert success compact">{success}</div> : null}

        {step === 1 ? (
          <form className="form" onSubmit={handleSendOtp}>
            <label>
              <span>Số điện thoại</span>
              <input
                value={phoneNumber}
                onChange={(e) => setPhoneNumber(e.target.value)}
                placeholder="Nhập số điện thoại giáo viên"
                required
              />
            </label>
            <button type="submit" disabled={loading}>
              {loading ? 'Đang gửi OTP...' : 'Gửi mã OTP'}
            </button>
          </form>
        ) : null}

        {step === 2 ? (
          <form className="form" onSubmit={handleVerifyOtp}>
            <label>
              <span>Số điện thoại</span>
              <input value={phoneNumber} disabled />
            </label>
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
            <div className="auth-actions">
              <button type="button" className="ghost-action" onClick={() => setStep(1)}>
                Quay lại
              </button>
              <button type="submit" disabled={loading}>
                {loading ? 'Đang kiểm tra...' : 'Xác thực OTP'}
              </button>
            </div>
          </form>
        ) : null}

        {step === 3 ? (
          <form className="form" onSubmit={handleResetPassword}>
            <label>
              <span>Mật khẩu mới</span>
              <input
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder="Ít nhất 6 ký tự"
                required
              />
            </label>
            <label>
              <span>Xác nhận mật khẩu mới</span>
              <input
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                placeholder="Nhập lại mật khẩu mới"
                required
              />
            </label>
            <div className="auth-actions">
              <button type="button" className="ghost-action" onClick={() => setStep(2)}>
                Quay lại
              </button>
              <button type="submit" disabled={loading}>
                {loading ? 'Đang đặt lại...' : 'Đặt lại mật khẩu'}
              </button>
            </div>
          </form>
        ) : null}

        <div className="auth-footer">
          <Link to="/login">Quay về đăng nhập</Link>
        </div>
      </div>
    </div>
  );
}
