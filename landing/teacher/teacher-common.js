/* =============================================
   章鱼智学 · 教师端 — 通用 JS
   JWT 认证 / API 封装 / 路由守卫 / 教师 API
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
  if (body.code === 40002) {
    const refreshed = await tryRefresh();
    if (refreshed) return apiCall(path, options);
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
      if (body.data.refresh) localStorage.setItem(REFRESH_KEY, body.data.refresh);
      return true;
    }
  } catch {}
  return false;
}

// ── 路由守卫 ──
function requireAuth() {
  if (!getToken()) window.location.href = '/teacher/login.html';
}

// ── 页面通用初始化 ──
function initPage() {
  requireAuth();
  const user = getCachedUser();
  if (user) {
    const el = document.getElementById('header-username');
    if (el) el.textContent = user.real_name || user.username;
  }
}

// ── 错误/加载显示 ──
function showError(msg) {
  const el = document.getElementById('error-msg');
  if (el) { el.textContent = msg; el.style.display = 'block'; }
}
function hideError() {
  const el = document.getElementById('error-msg');
  if (el) el.style.display = 'none';
}

function showLoading(id) {
  const el = document.getElementById(id);
  if (el) el.style.display = 'block';
}
function hideLoading(id) {
  const el = document.getElementById(id);
  if (el) el.style.display = 'none';
}

// ── 登出 ──
function handleLogout() { clearAuth(); }

/** 加载作业列表 + 统计汇总 — 被 index.html 调用 */
async function loadAssignments() {
  const data = await apiCall('/teacher/assignments/');
  const items = data.items || [];
  setText('stat-total', data.totalAssignments ?? 0);
  setText('stat-active', data.activeAssignments ?? 0);
  setText('stat-rate', (data.avgCompletionRate ?? 0) + '%');
  setText('stat-acc', (data.avgAccuracy ?? 0) + '%');
  const container = document.getElementById('assign-list');
  if (!container) return;
  if (items.length === 0) {
    container.innerHTML = '<div class="text-center" style="padding:40px;color:var(--text-muted);font-size:14px;">暂无已发布的作业</div>';
    return;
  }
  container.innerHTML = items.map(a => {
    const isActive = a.statusTag === 'in_progress';
    const statusLabel = isActive ? '进行中' : '已截止';
    const statusClass = isActive ? 'in-progress' : 'done';
    return `
    <a href="detail.html?id=${a.id}" class="assign-item">
      <div class="left">
        <div class="title">${esc(a.title)}</div>
        <div class="meta">
          <span>📚 ${esc(a.className)}</span>
          <span>📖 ${esc(a.courseName)}</span>
          <span>⏰ 截止 ${esc(a.deadline)}</span>
          <span>📄 ${a.questionCount ?? 0} 题</span>
        </div>
        <div class="subtitle" style="font-size:12px;color:var(--text-muted);margin-top:2px;">
          发布于 ${esc(a.publishAt || '')}
        </div>
      </div>
      <div class="right">
        <div class="progress-bar">
          ${esc(a.completedCount)}/${esc(a.totalStudents)}
          <div class="progress-track"><div class="progress-fill" style="width:${a.totalStudents > 0 ? Math.round(a.completedCount / a.totalStudents * 100) : 0}%"></div></div>
          ${(a.completionRate ?? 0) + '%'}
        </div>
        <span class="status-tag ${statusClass}">${statusLabel}</span>
      </div>
    </a>`;
  }).join('');
}

// ── UI 工具 ──────────────────────────────────────────────────

function setText(id, val) {
  const el = document.getElementById(id);
  if (el) el.textContent = val;
}

function esc(s) {
  if (s == null) return '';
  const d = document.createElement('div');
  d.textContent = String(s);
  return d.innerHTML;
}

function fmtDate(iso) {
  if (!iso) return '';
  return iso.slice(0, 10);
}
