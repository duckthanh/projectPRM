import { useEffect, useMemo, useState } from 'react';
import { Navigate, Route, Routes, useNavigate } from 'react-router-dom';
import {
  getPendingApplications,
  login,
  resendLoginOtp,
  verifyLoginOtp,
} from './api';
import { clearAuth, loadAuth, saveAuth } from './auth';
import Layout from './components/Layout';
import ApplicationsPage from './pages/ApplicationsPage';
import ForgotPasswordPage from './pages/ForgotPasswordPage';
import LoginPage from './pages/LoginPage';
import OtpPage from './pages/OtpPage';
import ScoresPage from './pages/ScoresPage';
import StatisticsPage from './pages/StatisticsPage';
import StudentsPage from './pages/StudentsPage';

function isTeacherLike(user) {
  const roles = user?.roles ?? [];
  return roles.includes('TEACHER') || roles.includes('ADMIN');
}

export default function App() {
  const navigate = useNavigate();
  const [auth, setAuth] = useState(() => loadAuth());
  const [pendingLogin, setPendingLogin] = useState(null);
  const [pendingCount, setPendingCount] = useState(0);

  useEffect(() => {
    if (!auth) {
      setPendingCount(0);
      return;
    }

    getPendingApplications(auth)
      .then((items) => setPendingCount(Array.isArray(items) ? items.length : 0))
      .catch(() => setPendingCount(0));
  }, [auth]);

  async function handleLogin({ phoneNumber, password }) {
    const response = await login(phoneNumber, password);

    if (response.twoFactorRequired) {
      setPendingLogin({ phoneNumber, password });
      navigate('/otp');
      return;
    }

    if (!isTeacherLike(response.user)) {
      throw new Error('Tài khoản này không phải giáo viên hoặc quản trị');
    }

    const nextAuth = {
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      user: response.user,
    };
    setAuth(nextAuth);
    saveAuth(nextAuth);
    setPendingLogin(null);
    navigate('/students');
  }

  async function handleVerifyOtp(otp) {
    const response = await verifyLoginOtp(pendingLogin.phoneNumber, otp);
    if (!isTeacherLike(response.user)) {
      throw new Error('Tài khoản này không phải giáo viên hoặc quản trị');
    }

    const nextAuth = {
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      user: response.user,
    };
    setAuth(nextAuth);
    saveAuth(nextAuth);
    setPendingLogin(null);
    navigate('/students');
  }

  async function handleResendOtp() {
    await resendLoginOtp(pendingLogin.phoneNumber, pendingLogin.password);
  }

  function handleLogout() {
    clearAuth();
    setAuth(null);
    setPendingLogin(null);
    setPendingCount(0);
    navigate('/login');
  }

  const protectedLayout = useMemo(() => {
    if (!auth) return null;
    return (
      <Layout auth={auth} pendingCount={pendingCount} onLogout={handleLogout}>
        <Routes>
          <Route path="/students" element={<StudentsPage auth={auth} />} />
          <Route path="/scores" element={<ScoresPage auth={auth} />} />
          <Route
            path="/applications"
            element={
              <ApplicationsPage
                auth={auth}
                onPendingCountChange={setPendingCount}
              />
            }
          />
          <Route path="/statistics" element={<StatisticsPage auth={auth} />} />
          <Route path="*" element={<Navigate to="/students" replace />} />
        </Routes>
      </Layout>
    );
  }, [auth, pendingCount]);

  return (
    <Routes>
      <Route
        path="/login"
        element={auth ? <Navigate to="/students" replace /> : <LoginPage onLogin={handleLogin} />}
      />
      <Route
        path="/forgot-password"
        element={auth ? <Navigate to="/students" replace /> : <ForgotPasswordPage />}
      />
      <Route
        path="/otp"
        element={
          auth ? (
            <Navigate to="/students" replace />
          ) : (
            <OtpPage
              pendingLogin={pendingLogin}
              onVerifyOtp={handleVerifyOtp}
              onResendOtp={handleResendOtp}
            />
          )
        }
      />
      <Route path="/*" element={auth ? protectedLayout : <Navigate to="/login" replace />} />
    </Routes>
  );
}
