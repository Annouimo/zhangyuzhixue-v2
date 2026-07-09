// =====================================================================
//  solve-rate.js — 评分页交互
//  三个维度各 10 星，允许复访修改
// =====================================================================
var ratings = {
  difficulty: 0,
  calculation: 0,
  elegance: 0,
};
var submitted = false;

function getStars(dim) {
  return document.querySelectorAll('.star-rating[data-dim="' + dim + '"] .star');
}

function setRating(dim, value) {
  ratings[dim] = value;
  var stars = getStars(dim);
  stars.forEach(function(s) {
    var v = parseInt(s.dataset.value);
    s.classList.toggle('active', v <= value);
    s.classList.remove('hover');
  });
  document.getElementById('user-' + dim).textContent = value;
}

function resetStars(dim) {
  var stars = getStars(dim);
  var currentValue = ratings[dim];
  stars.forEach(function(s) {
    var v = parseInt(s.dataset.value);
    s.classList.toggle('active', v <= currentValue);
    s.classList.remove('hover');
  });
}

function hoverStar(el) {
  var dim = el.closest('.star-rating').dataset.dim;
  var value = parseInt(el.dataset.value);
  var stars = getStars(dim);
  stars.forEach(function(s) {
    var v = parseInt(s.dataset.value);
    s.classList.toggle('hover', v <= value);
  });
}

function submitRating() {
  if (submitted) return;
  // 检查至少有一项评分
  var hasRating = Object.values(ratings).some(function(v) { return v > 0; });
  if (!hasRating) {
    showToast('⚠️', '请至少评一项');
    return;
  }
  submitted = true;
  document.getElementById('rate-submit-btn').disabled = true;
  document.getElementById('rate-submit-btn').textContent = '✓ 评分已提交';

  var total = ratings.difficulty + ratings.calculation + ratings.elegance;
  var bonus = (total >= 3 ? 0.3 : 0.1).toFixed(1);
  showToast('⭐', '评分已提交！+ ' + bonus + ' 赠送积分');
}

// 让 star 响应 hover
document.addEventListener('DOMContentLoaded', function() {
  document.querySelectorAll('.star').forEach(function(s) {
    s.addEventListener('mouseenter', function() { hoverStar(this); });
  });
});
