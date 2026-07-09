// =====================================================================
//  solve-choice.js — 选择题交互
// =====================================================================
var CHOICE_COOLDOWN = 10;
var choiceState = { selectedOption: null, submitted: false };

function selectOption(el) {
  if (choiceState.submitted) return;
  document.querySelectorAll('.option-btn').forEach(function(b) {
    b.classList.remove('selected');
  });
  el.classList.add('selected');
  choiceState.selectedOption = el.dataset.option;
}

function startChoiceCooldown() {
  var btn = document.getElementById('choice-submit-btn');
  var cd = document.getElementById('choice-cooldown');
  btn.disabled = true;
  var remain = CHOICE_COOLDOWN;
  cd.textContent = '⏳ 还剩 ' + remain + ' 秒可提交';
  var timer = setInterval(function() {
    remain--;
    if (remain <= 0) {
      clearInterval(timer);
      btn.disabled = false;
      cd.textContent = '✓ 可以提交了';
    } else {
      cd.textContent = '⏳ 还剩 ' + remain + ' 秒可提交';
    }
  }, 1000);
  return timer;
}

function submitChoice() {
  if (!choiceState.selectedOption) {
    showToast('⚠️', '请先选择一个选项');
    return;
  }
  if (choiceState.submitted) return;
  choiceState.submitted = true;

  var correctAnswer = 'A';
  var isCorrect = (choiceState.selectedOption === correctAnswer);
  document.getElementById('choice-action').style.display = 'none';
  var result = document.getElementById('choice-result');
  result.style.display = 'block';
  var badge = document.getElementById('choice-result-badge');
  badge.textContent = isCorrect ? '✓ 回答正确！' : '✗ 回答错误，正确答案是 ' + correctAnswer;
  badge.className = 'result-badge ' + (isCorrect ? 'correct' : 'wrong');

  document.querySelectorAll('.option-btn').forEach(function(b) {
    if (b.dataset.option === correctAnswer) b.classList.add('selected');
  });

  // 显示完成横幅
  document.getElementById('done-section').style.display = 'block';
}

function goNext() {
  showToast('📝', '进入下一题（Flutter 中执行路由跳转）');
}

function goRate() {
  location.href = 'solve-rate.html?from=solve-choice';
}

// 初始化：启动冷却
document.addEventListener('DOMContentLoaded', startChoiceCooldown);
