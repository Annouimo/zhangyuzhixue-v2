/* =============================================
   章鱼智学 · 教师端 — 通用 JS
   JWT 认证 / API 封装 / 路由守卫
   ============================================= */

// ── JWT 管理 ──
const TOKEN_KEY = 'teacher_access_token';
const REFRESH_KEY = 'teacher_refresh_token';
const USER_KEY = 'teacher_user_cache';

function getToken() { return localStorage.getItem(TOKEN_KEY); }
function saveToken(t) { localStorage.setItem(TOKEN_KEY, t); }

function clearAuth() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(REFRESH_KEY);
  localStorage.removeItem(USER_KEY);
  window.location.href = '/teacher/login.html';
}

function getCachedUser() {
  try {
    return JSON.parse(localStorage.getItem(USER_KEY));
  } catch { return null; }
}

// ── API 调用封装 ──
const API_BASE = '/api/v1';

async function apiCall(path, options = {}) {
  const token = getToken();
  const resp = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });
  const body = await resp.json();
  if (body.code === 40002) {  // token 过期
    const refreshed = await tryRefresh();
    if (refreshed) return apiCall(path, options); // 重试
    clearAuth();
  }
  if (body.code !== 0) throw new Error(body.message);
  return body.data;
}

// ── Token 刷新 ──
async function tryRefresh() {
  const refresh = localStorage.getItem(REFRESH_KEY);
  if (!refresh) return false;
  try {
    const resp = await fetch(`${API_BASE}/auth/refresh/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refresh }),
    });
    const body = await resp.json();
    if (body.code === 0) {
      saveToken(body.data.access);
      return true;
    }
  } catch {}
  return false;
}

// ── 路由守卫 ──
function requireAuth() {
  if (!getToken()) window.location.href = '/teacher/login.html';
}

// ── 错误显示 ──
function showError(msg) {
  const el = document.getElementById('error-msg');
  if (el) { el.textContent = msg; el.style.display = 'block'; }
}
function hideError() {
  const el = document.getElementById('error-msg');
  if (el) el.style.display = 'none';
}

// ── 登出 ──
function handleLogout() { clearAuth(); }
