// =====================================================================
//  solve-utils.js — 通用工具：知识卡片、评分、Toast、滚动
//  独立无依赖，可在任意页面复用
// =====================================================================

// =================================================================
//  滚动
// =================================================================
function scrollToSteps() {
  var container = document.getElementById('step-container');
  if (container) container.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

// =================================================================
//  知识卡片
// =================================================================
function showKnowledge(title, body) {
  document.getElementById('knowledge-title').textContent = title;
  document.getElementById('knowledge-body').textContent = body;
  document.getElementById('knowledge-popup').classList.add('show');
}

function closeKnowledge() {
  document.getElementById('knowledge-popup').classList.remove('show');
  document.querySelectorAll('.knowledge-popup.show').forEach(function(el) {
    el.classList.remove('show');
  });
}

// =================================================================
//  评分（10 星）
// =================================================================
var currentRating = { difficulty: 0, calculation: 0, elegance: 0 };

function setRating(el, dimension) {
  var container = el.parentElement;
  var value = parseInt(el.getAttribute('data-value'));
  var stars = container.querySelectorAll('.star');
  currentRating[dimension] = value;
  stars.forEach(function(s) {
    var v = parseInt(s.getAttribute('data-value'));
    if (v <= value) s.classList.add('active');
    else s.classList.remove('active');
  });
}

function resetStars(container) {}

// =================================================================
//  Toast
// =================================================================
var _toastTimer = null;

function showToast(icon, msg, duration) {
  var bar = document.getElementById('toast-bar');
  document.getElementById('toast-icon').textContent = icon;
  document.getElementById('toast-msg').textContent = msg;
  bar.classList.add('show');
  if (duration === undefined) duration = 3000;
  if (_toastTimer) clearTimeout(_toastTimer);
  _toastTimer = setTimeout(function() {
    bar.classList.remove('show');
  }, duration);
}

function closeToast() {
  var bar = document.getElementById('toast-bar');
  bar.classList.remove('show');
  if (_toastTimer) clearTimeout(_toastTimer);
}
