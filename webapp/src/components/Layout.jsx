import { NavLink } from 'react-router-dom';

export default function Layout({ auth, pendingCount, onLogout, children }) {
  return (
    <div className="page-shell">
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-mark">M</div>
          <div>
            <h1>MyShool</h1>
            <p>Teacher Web</p>
          </div>
        </div>

        <div className="user-box">
          <strong>{auth?.user?.fullName || auth?.user?.phoneNumber}</strong>
          <span>{auth?.user?.phoneNumber}</span>
        </div>

        <nav className="nav-list">
          <NavLink to="/students" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
            Học sinh theo lớp
          </NavLink>
          <NavLink to="/scores" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
            Nhập điểm
          </NavLink>
          <NavLink to="/applications" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
            Đơn từ
            {pendingCount > 0 ? <span className="nav-badge">{pendingCount}</span> : null}
          </NavLink>
          <NavLink to="/statistics" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
            Thống kê
          </NavLink>
        </nav>

        <button className="logout-btn" onClick={onLogout}>
          Đăng xuất
        </button>
      </aside>

      <div className="main-panel">{children}</div>
    </div>
  );
}
