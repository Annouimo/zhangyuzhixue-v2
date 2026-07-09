// =====================================================================
//  solve-fill.js — 填空题交互
// =====================================================================
var FILL_COOLDOWN = 10;

function startFillCooldown() {
  var btn = document.getElementById('fill-reveal-btn');
  var cd = document.getElementById('fill-cooldown');
  btn.disabled = true;
  var remain = FILL_COOLDOWN;
  cd.textContent = '⏳ 还剩 ' + remain + ' 秒可查看';
  var timer = setInterval(function() {
    remain--;
    if (remain <= 0) {
      clearInterval(timer);
      btn.disabled = false;
      cd.textContent = '✓ 可以查看答案了';
    } else {
      cd.textContent = '⏳ 还剩 ' + remain + ' 秒可查看';
    }
  }, 1000);
  return timer;
}

function showFillAnswer() {
  document.getElementById('fill-action').style.display = 'none';
  document.getElementById('fill-result').style.display = 'block';
  // 显示完成横幅
  document.getElementById('done-section').style.display = 'block';
}

function goNext() {
  showToast('📝', '进入下一题（Flutter 中执行路由跳转）');
}

function goRate() {
  location.href = 'solve-rate.html?from=solve-fill';
}

// 初始化：启动冷却
document.addEventListener('DOMContentLoaded', startFillCooldown);
