// =====================================================================
//  solve-solve-interact.js — 解答题交互
//  依赖 solve-solve-core.js
// =====================================================================

// =================================================================
//  调试工具栏
// =================================================================
function toggleDemoMode() {
  _demoPrevious = !_demoPrevious;
  var btn = document.getElementById('debug-mode-btn');
  btn.textContent = _demoPrevious ? '复访' : '首次';
  btn.classList.toggle('revisit', _demoPrevious);

  resetSolveState();
  if (_demoPrevious) {
    reconstructFromPreviousState(DEMO_PREVIOUS_STATE);
  }
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
  document.getElementById('done-section').style.display = 'none';
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
          cooldownStarted: hasFeedback,
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
    goToDone();
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

  // 冷却保护
  var btn = cardEl.querySelector('.next-btn');
  if (btn && btn.disabled) return;

  // 展开步骤
  var content = cardEl.querySelector('.step-content');
  var feedback = cardEl.querySelector('.feedback-row');
  var arrow = cardEl.querySelector('.next-btn');
  if (content) content.style.display = 'block';
  if (feedback) feedback.style.display = 'flex';
  st.content = true;
  if (arrow) arrow.style.display = 'none';
  st.arrowHidden = true;

  // 清除冷却
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
  document.getElementById('done-section').style.display = 'block';
  window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
}

function goNext() {
  showToast('📝', '进入下一题（Flutter 中执行路由跳转）');
}

function goRate() {
  location.href = 'solve-rate.html?from=solve-solve';
}

// =================================================================
//  初始化
// =================================================================
document.addEventListener('DOMContentLoaded', initSolvePage);
