// =====================================================================
//  solve-interact.js — 步骤交互、冷却、题型切换、演示数据
//  依赖 solve-core.js（使用 solve / renderSteps / SUB_QUESTIONS 等）
// =====================================================================

// =================================================================
//  题型分支切换
// =================================================================
function activateBranch(type, skipCooldown) {
  Object.keys(_cooldownTimers).forEach(function(k) {
    clearInterval(_cooldownTimers[k]);
  });
  _cooldownTimers = {};

  // 清理步骤冷却
  Object.keys(_stepCooldowns).forEach(function(k) {
    clearInterval(_stepCooldowns[k].timer);
  });
  _stepCooldowns = {};

  document.querySelectorAll('.branch-container').forEach(function(el) {
    el.classList.remove('active');
  });
  var map = { '选择': 'branch-choice', '填空': 'branch-fill', '解答': 'branch-solve' };
  var target = document.getElementById(map[type]);
  if (target) target.classList.add('active');

  if (skipCooldown) return;
  if (type === '选择') startChoiceCooldown();
  else if (type === '填空') startFillCooldown();
}

// =================================================================
//  调试工具栏
// =================================================================
function debugSwitch(type) {
  document.querySelectorAll('.debug-btn').forEach(function(btn) {
    btn.classList.toggle('active', btn.dataset.type === type);
  });
  document.getElementById('debug-current').textContent = '当前：' + type;

  resetChoiceState();
  resetFillState();
  resetSolveState();

  var meta = {
    '选择': { number: '2', type: '选择', assign: '三角函数小测', qtype: '选择' },
    '填空': { number: '3', type: '填空', assign: '导数第 1 讲课后练习', qtype: '填空' },
    '解答': { number: '3', type: '解答', assign: '导数第 1 讲课后练习', qtype: '解答' },
  };
  var d = meta[type];
  document.querySelector('[data-db="question.getDetail.number"]').textContent = d.number;
  var typeSpan = document.querySelector('[data-db="question.getDetail.questionType"]');
  if (typeSpan) typeSpan.textContent = d.qtype;
  var assignSpan = document.querySelector('[data-db="question.getDetail.assignName"]');
  if (assignSpan) assignSpan.textContent = d.assign;

  // 复访模式：不启动冷却，直接重建状态
  activateBranch(type, _demoPrevious);
  if (_demoPrevious) {
    reconstructFromPreviousState(DEMO_PREVIOUS_STATE);
  }
}

function toggleDemoMode() {
  _demoPrevious = !_demoPrevious;
  var btn = document.getElementById('debug-mode-btn');
  btn.textContent = _demoPrevious ? '复访' : '首次';
  btn.classList.toggle('revisit', _demoPrevious);

  var currentType = '解答';
  document.querySelectorAll('.debug-btn.active').forEach(function(b) {
    currentType = b.dataset.type;
  });
  resetChoiceState();
  resetFillState();
  resetSolveState();

  // 复访不启动冷却，首次正常启动
  activateBranch(currentType, _demoPrevious);
  if (_demoPrevious) {
    reconstructFromPreviousState(DEMO_PREVIOUS_STATE);
  }
}

function resetChoiceState() {
  choiceState = { selectedOption: null, submitted: false };
  document.querySelectorAll('#branch-choice .option-btn').forEach(function(b) {
    b.classList.remove('selected');
  });
  document.getElementById('choice-action').style.display = '';
  document.getElementById('choice-result').style.display = 'none';
  document.getElementById('choice-submit-btn').disabled = true;
  document.getElementById('choice-cooldown').textContent = '⏳ 还剩 10 秒可提交';
}

function resetFillState() {
  document.getElementById('fill-action').style.display = '';
  document.getElementById('fill-result').style.display = 'none';
  document.getElementById('fill-reveal-btn').disabled = true;
  document.getElementById('fill-cooldown').textContent = '⏳ 还剩 10 秒可查看';
}

function resetSolveState() {
  // 清理步骤冷却
  Object.keys(_stepCooldowns).forEach(function(k) {
    clearInterval(_stepCooldowns[k].timer);
  });
  _stepCooldowns = {};

  _goToDoneFired = false;
  solve = {
    currentSubQIndex: 1,
    subQOrder: [1, 2],
    completedSubQs: {},
    currentMethod: { '1': '余弦定理法', '2': '' },
    stepState: {},
    currentSubQIdx: 0,
  };
  initStepStates();
  document.getElementById('congrats-section').style.display = 'none';
  document.getElementById('subq-complete-banner').style.display = 'none';
  document.getElementById('subq-locked-placeholder').style.display = 'none';
  renderSubQTabs();
  renderMethodToggle();
  renderSteps();
}

// =================================================================
//  复访重建（Demo）
// =================================================================
var _goToDoneFired = false;

var DEMO_PREVIOUS_STATE = {
  // 选择题历史记录（供复访演示）
  choiceSelected: 'A',
  choiceSubmitted: true,
  // 填空题历史记录
  fillRevealed: true,
  // 解答题历史记录
  subQRecords: [
    {
      index: 1, activeMethod: '余弦定理法', completed: true,
      methods: [
        { methodName: '余弦定理法', steps: [
          { stepOrder: 1, feedbackGiven: true, feedbackType: 'correct' },
          { stepOrder: 2, feedbackGiven: true, feedbackType: 'wrong' },
        ]},
        { methodName: '向量法', steps: [
          { stepOrder: 1, feedbackGiven: false, feedbackType: null },
        ]},
      ],
    },
    {
      index: 2, activeMethod: '', completed: true,
      methods: [
        { methodName: '', steps: [
          { stepOrder: 1, feedbackGiven: true, feedbackType: 'correct' },
          { stepOrder: 2, feedbackGiven: true, feedbackType: 'correct' },
        ]},
      ],
    },
  ],
  isRated: false,
};

function reconstructFromPreviousState(state) {
  // 复位所有步骤卡的 DOM 冷却态
  // (resetSolveState 内的 renderSteps 可能已触发 startStepCooldowns 并修改了 DOM：
  //  按钮被 disabled、冷却文字被显示。需要手动复位)
  document.querySelectorAll('.step-card .next-btn').forEach(function(btn) {
    btn.disabled = false;
    btn.classList.remove('cooldown');
  });
  document.querySelectorAll('.step-card .cooldown-text').forEach(function(el) {
    el.style.display = 'none';
  });

  // 清理所有步骤冷却计时器
  Object.keys(_stepCooldowns).forEach(function(k) {
    clearInterval(_stepCooldowns[k].timer);
  });
  _stepCooldowns = {};

  // === 选择题重建 ===
  if (state.choiceSubmitted && state.choiceSelected) {
    var correctAnswer = 'A';
    choiceState = { selectedOption: state.choiceSelected, submitted: true };
    document.getElementById('choice-action').style.display = 'none';
    var result = document.getElementById('choice-result');
    result.style.display = 'block';
    var badge = document.getElementById('choice-result-badge');
    var isCorrect = (state.choiceSelected === correctAnswer);
    badge.textContent = isCorrect ? '✓ 回答正确！' : '✗ 回答错误，正确答案是 ' + correctAnswer;
    badge.className = 'result-badge ' + (isCorrect ? 'correct' : 'wrong');
    document.querySelectorAll('#branch-choice .option-btn').forEach(function(b) {
      if (b.dataset.option === correctAnswer) b.classList.add('selected');
    });
  }

  // === 填空题重建 ===
  if (state.fillRevealed) {
    document.getElementById('fill-action').style.display = 'none';
    document.getElementById('fill-result').style.display = 'block';
  }

  // === 解答题重建 ===
  state.subQRecords.forEach(function(sq) {
    var sqDone = sq.methods.some(function(m) {
      return m.steps.every(function(s) { return s.feedbackGiven; });
    });
    if (sqDone) solve.completedSubQs[sq.index] = true;
    solve.currentMethod[sq.index] = sq.activeMethod;
    sq.methods.forEach(function(m) {
      m.steps.forEach(function(step) {
        var key = sq.index + '-' + m.methodName + '-' + step.stepOrder;
        var hasFeedback = step.feedbackGiven;
        solve.stepState[key] = {
          card: true, content: hasFeedback, arrowHidden: hasFeedback, feedbackGiven: hasFeedback,
          cooldownStarted: hasFeedback,  // 已展开的步骤不再需要冷却
        };
      });
    });
  });

  var allDone = SUB_QUESTIONS.every(function(sq) {
    return !!solve.completedSubQs[sq.index];
  });

  renderSubQTabs();
  renderMethodToggle();
  renderSteps();
  renderCompleteBanner();

  if (allDone) {
    _goToDoneFired = true;
    document.getElementById('congrats-section').style.display = 'block';
  }
}

// =================================================================
//  步骤交互（箭头→展开、反馈）
// =================================================================
function onArrow(key) {
  var st = solve.stepState[key];
  if (!st) return;
  var parts = key.split('-');
  var idx = parseInt(parts[0]);
  var method = parts.slice(1, -1).join('-');
  var order = parseInt(parts[parts.length - 1]);

  if (!st.card) return;

  var cards = getStepsFor(idx, method);
  var cardEl = cards[order - 1];
  if (!cardEl) return;

  // 冷却保护：按钮 disabled 时不可点击
  var btn = cardEl.querySelector('.next-btn');
  if (btn && btn.disabled) return;

  // 展开步骤内容和反馈行
  var content = cardEl.querySelector('.step-content');
  var feedback = cardEl.querySelector('.feedback-row');
  var arrow = cardEl.querySelector('.next-btn');
  if (content) content.style.display = 'block';
  if (feedback) feedback.style.display = 'flex';
  st.content = true;
  if (arrow) arrow.style.display = 'none';
  st.arrowHidden = true;

  // 清除该步骤的冷却状态
  if (_stepCooldowns[key]) {
    clearInterval(_stepCooldowns[key].timer);
    delete _stepCooldowns[key];
  }
  if (cardEl) {
    var cdText = cardEl.querySelector('.cooldown-text');
    if (cdText) cdText.style.display = 'none';
  }
}

function selectFeedback(key, type) {
  var st = solve.stepState[key];
  if (!st) return;
  st.feedbackGiven = true;

  var parts = key.split('-');
  var idx = parseInt(parts[0]);
  var method = parts.slice(1, -1).join('-');
  var order = parseInt(parts[parts.length - 1]);

  var cards = getStepsFor(idx, method);
  var cardEl = cards[order - 1];
  if (cardEl) {
    var row = cardEl.querySelector('.feedback-row');
    if (row) {
      var btns = row.querySelectorAll('.feedback-btn');
      btns.forEach(function(b) {
        b.classList.remove('selected');
        if ((type === 'correct' && b.classList.contains('correct')) ||
            (type === 'partial' && b.classList.contains('partial')) ||
            (type === 'wrong' && b.classList.contains('wrong'))) {
          b.classList.add('selected');
        }
      });
    }
  }

  var allCards = getStepsFor(idx, method);
  var isLastStep = (order >= allCards.length);

  if (isLastStep) {
    var newlyCompleted = !solve.completedSubQs[idx];
    if (newlyCompleted) solve.completedSubQs[idx] = true;
    renderSubQTabs();

    // 持久横幅：当前小问完成
    var banner = document.getElementById('subq-complete-banner');
    if (newlyCompleted) {
      var sqLabel = SUB_QUESTIONS.find(function(s) { return s.index === idx; });
      banner.textContent = '✅ 第' + sqLabel.label + '问已完成';
      banner.style.display = 'block';
    }

    var allDone = SUB_QUESTIONS.every(function(sq) {
      return !!solve.completedSubQs[sq.index];
    });

    if (allDone && !_goToDoneFired) {
      _goToDoneFired = true;
      goToDone();
    } else if (allDone && _goToDoneFired) {
      renderSteps();
    } else if (newlyCompleted) {
      var currentPos = solve.subQOrder.indexOf(idx);
      if (currentPos >= 0 && currentPos < solve.subQOrder.length - 1) {
        var nextIdx = solve.subQOrder[currentPos + 1];
        // 横幅已经持久显示，仅自动跳转到下一问
        setTimeout(function() {
          switchSubQuestion(nextIdx);
          scrollToSteps();
        }, 1500);
      }
    } else {
      renderSteps();
    }
  } else {
    renderSteps();
  }
}

function goToDone() {
  document.getElementById('congrats-section').style.display = 'block';
  window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
}

// =================================================================
//  选择题交互
// =================================================================
var choiceState = { selectedOption: null, submitted: false };

function selectOption(el) {
  if (choiceState.submitted) return;
  document.querySelectorAll('#branch-choice .option-btn').forEach(function(b) {
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
  _cooldownTimers['choice'] = timer;
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

  document.querySelectorAll('#branch-choice .option-btn').forEach(function(b) {
    if (b.dataset.option === correctAnswer) b.classList.add('selected');
  });
}

// =================================================================
//  填空题交互
// =================================================================
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
  _cooldownTimers['fill'] = timer;
}

function showFillAnswer() {
  document.getElementById('fill-action').style.display = 'none';
  document.getElementById('fill-result').style.display = 'block';
}

// =================================================================
//  初始化入口
// =================================================================
document.addEventListener('DOMContentLoaded', initSolvePage);
