// =====================================================================
//  solve-utils.js — 解题模式通用工具
//  知识卡片、Toast、评分、常用辅助
// =====================================================================

// =================================================================
//  知识卡片弹层
// =================================================================
function showKnowledge(title, body) {
  var eTitle = document.getElementById('knowledge-title');
  var eBody = document.getElementById('knowledge-body');
  var ePopup = document.getElementById('knowledge-popup');
  if (eTitle) eTitle.textContent = title;
  if (eBody) eBody.textContent = body;
  if (ePopup) ePopup.classList.add('show');
}
function closeKnowledge() {
  document.querySelectorAll('.knowledge-popup.show').forEach(function(el) {
    el.classList.remove('show');
  });
}

// =================================================================
//  Toast
// =================================================================
var _toastTimer = null;
function showToast(icon, msg, duration) {
  var bar = document.getElementById('toast-bar');
  var iconEl = document.getElementById('toast-icon');
  var msgEl = document.getElementById('toast-msg');
  if (!bar || !iconEl || !msgEl) return;
  iconEl.textContent = icon || '';
  msgEl.textContent = msg || '';
  bar.classList.add('show');
  if (!duration) duration = 3000;
  if (_toastTimer) clearTimeout(_toastTimer);
  _toastTimer = setTimeout(function() { bar.classList.remove('show'); }, duration);
}
function closeToast() {
  var bar = document.getElementById('toast-bar');
  if (bar) bar.classList.remove('show');
  if (_toastTimer) clearTimeout(_toastTimer);
}

// =================================================================
//  评分（10 星）
// =================================================================
var currentRating = { difficulty: 0, calculation: 0, elegance: 0 };

function setRating(dimension, value) {
  currentRating[dimension] = value;
  var container = document.querySelector('.star-rating[data-dim="' + dimension + '"]');
  if (!container) return;
  container.querySelectorAll('.star').forEach(function(s) {
    var v = parseInt(s.getAttribute('data-value'));
    s.classList.toggle('active', v <= value);
  });
  var userEl = document.getElementById('user-' + dimension);
  if (userEl) userEl.textContent = value;
}
function resetStars(dimension) {
  // hover reset handled by active class, no-op needed
}

// =================================================================
//  冷却倒计时工具
// =================================================================
function startCooldown(seconds, btnEl, cdEl, onDone) {
  btnEl.disabled = true;
  var remain = seconds;
  cdEl.style.display = 'block';
  cdEl.textContent = '⏳ 还剩 ' + remain + ' 秒';
  var timer = setInterval(function() {
    remain--;
    if (remain <= 0) {
      clearInterval(timer);
      btnEl.disabled = false;
      cdEl.textContent = '✓ 可以操作了';
      setTimeout(function() { cdEl.style.display = 'none'; }, 2000);
      if (onDone) onDone();
    } else {
      cdEl.textContent = '⏳ 还剩 ' + remain + ' 秒';
    }
  }, 1000);
  return timer;
}
