const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8080';

async function request(path, options = {}) {
  const { headers: optionHeaders, ...restOptions } = options;
  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...restOptions,
    headers: {
      'Content-Type': 'application/json',
      ...(optionHeaders ?? {}),
    },
  });

  if (!response.ok) {
    let message = 'Yeu cau that bai';
    const text = await response.text();
    try {
      const data = text ? JSON.parse(text) : {};
      message = data.message || Object.values(data.errors ?? {})[0] || message;
    } catch {
      if (text) message = text;
    }
    const error = new Error(message);
    error.status = response.status;
    throw error;
  }

  if (response.status === 204) return null;
  return response.json();
}

function authHeaders(auth) {
  return auth?.accessToken
    ? { Authorization: `Bearer ${auth.accessToken}` }
    : {};
}

export function login(phoneNumber, password) {
  return request('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ phoneNumber, password }),
  });
}

export function verifyLoginOtp(phoneNumber, otp) {
  return request('/api/auth/login/verify-otp', {
    method: 'POST',
    body: JSON.stringify({ phoneNumber, otp }),
  });
}

export function resendLoginOtp(phoneNumber, password) {
  return request('/api/auth/login/resend-otp', {
    method: 'POST',
    body: JSON.stringify({ phoneNumber, password }),
  });
}

export function sendResetOtp(phoneNumber) {
  return request('/api/auth/password/send-otp', {
    method: 'POST',
    body: JSON.stringify({ phoneNumber }),
  });
}

export function verifyResetOtp(phoneNumber, otp) {
  return request('/api/auth/password/verify-otp', {
    method: 'POST',
    body: JSON.stringify({ phoneNumber, otp }),
  });
}

export function resetPassword(phoneNumber, otp, newPassword) {
  return request('/api/auth/password/reset', {
    method: 'POST',
    body: JSON.stringify({ phoneNumber, otp, newPassword }),
  });
}

export function getClasses(auth) {
  return request('/api/school-classes', {
    headers: authHeaders(auth),
  });
}

export function getSubjects(auth) {
  return request('/api/subjects', {
    headers: authHeaders(auth),
  });
}

export function getStudentsByClass(auth, classId) {
  return request(`/api/teacher/class/${classId}/students`, {
    headers: authHeaders(auth),
  });
}

export function getClassScores(auth, classId, academicYear, semester) {
  const query = new URLSearchParams({ academicYear, semester: String(semester) });
  return request(`/api/teacher/class/${classId}/scores?${query}`, {
    headers: authHeaders(auth),
  });
}

async function upload(path, auth, fields) {
  const body = new FormData();
  Object.entries(fields).forEach(([key, value]) => body.append(key, value));
  const response = await fetch(`${API_BASE_URL}${path}`, {
    method: 'POST',
    headers: authHeaders(auth),
    body,
  });
  const text = await response.text();
  let data = {};
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    data = { message: text };
  }
  if (!response.ok) {
    const error = new Error(data.message || 'Không thể xử lý file Excel');
    error.status = response.status;
    throw error;
  }
  return data;
}

export function getStudentScores(auth, studentId, academicYear, semester) {
  const query = new URLSearchParams({ academicYear, semester: String(semester) });
  return request(`/api/teacher/student/${studentId}/scores?${query}`, {
    headers: authHeaders(auth),
  });
}

export function getStudentAcademicSummary(auth, studentId, academicYear) {
  const query = new URLSearchParams({ academicYear });
  return request(`/api/teacher/student/${studentId}/academic-summary?${query}`, {
    headers: authHeaders(auth),
  });
}

export function getClassStatistics(auth, classId, academicYear, semester) {
  const query = new URLSearchParams({ academicYear, semester: String(semester) });
  return request(`/api/teacher/class/${classId}/statistics?${query}`, {
    headers: authHeaders(auth),
  });
}

export function createScore(auth, payload) {
  return request('/api/teacher/scores', {
    method: 'POST',
    headers: authHeaders(auth),
    body: JSON.stringify(payload),
  });
}

export function getPendingApplications(auth) {
  return request('/api/applications/all-pending', {
    headers: authHeaders(auth),
  });
}

export function previewScoreImport(auth, payload) {
  return upload('/api/teacher/scores/import/preview', auth, payload);
}

export function importScoresExcel(auth, payload) {
  return upload('/api/teacher/scores/import', auth, payload);
}

export async function downloadScoreImportTemplate(auth) {
  const response = await fetch(`${API_BASE_URL}/api/teacher/scores/import/template`, {
    headers: authHeaders(auth),
  });
  if (!response.ok) {
    throw new Error('Không thể tải file Excel mẫu');
  }
  const blob = await response.blob();
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = 'score-import-template.xlsx';
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
}

export function getAllApplications(auth) {
  return request('/api/applications/all', {
    headers: authHeaders(auth),
  });
}

export function respondToApplication(auth, applicationId, payload) {
  return request(`/api/applications/${applicationId}/respond`, {
    method: 'PUT',
    headers: authHeaders(auth),
    body: JSON.stringify(payload),
  });
}
