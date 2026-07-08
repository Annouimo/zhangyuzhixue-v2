// =====================================================================
//  solve-core.js — 解答题状态机、步骤渲染、方法切换
//  解题模式核心逻辑，与题目类型无关的通用渲染层
// =====================================================================

// =================================================================
//  全局配置
// =================================================================
const CHOICE_COOLDOWN = 10;
const FILL_COOLDOWN = 10;
var _demoPrevious = false;
var _cooldownTimers = {};

const SUB_QUESTIONS = [
  { index: 1, label: '(1)', methods: ['余弦定理法', '向量法'] },
  { index: 2, label: '(2)', methods: [''] }
];

// =================================================================
//  解答题状态机
// =================================================================
var solve = {
  currentSubQIndex: 1,
  subQOrder: [1, 2],
  completedSubQs: {},
  currentMethod: { '1': '余弦定理法', '2': '' },
  stepState: {},
  currentSubQIdx: 0,
};

function getStepsFor(subQ, method) {
  return document.querySelectorAll(
    '.step-card[data-subq="' + subQ + '"][data-method="' + method + '"]'
  );
}

function initStepStates() {
  SUB_QUESTIONS.forEach(function(sq) {
    sq.methods.forEach(function(m) {
      var cards = getStepsFor(sq.index, m);
      cards.forEach(function(card, idx) {
        var key = sq.index + '-' + m + '-' + (idx + 1);
        solve.stepState[key] = {
          card: (idx === 0),
          content: false,
          arrowHidden: false,
          feedbackGiven: false,
        };
      });
    });
  });
}

// =================================================================
//  小问 tabs 渲染
// =================================================================
function renderSubQTabs() {
  var container = document.getElementById('subq-tabs');
  if (!container) return;
  if (SUB_QUESTIONS.length <= 1) { container.style.display = 'none'; return; }
  container.style.display = 'flex';
  container.innerHTML = '';
  SUB_QUESTIONS.forEach(function(sq, idx) {
    var btn = document.createElement('button');
    btn.className = 'subq-tab';
    btn.dataset.subq = sq.index;
    btn.textContent = sq.label;
    if (solve.completedSubQs[sq.index]) btn.classList.add('done');
    if (sq.index === solve.currentSubQIndex) btn.classList.add('active');
    else if (!isSubQUnlocked(sq.index)) btn.classList.add('locked');
    btn.onclick = function() { switchSubQuestion(sq.index); };
    container.appendChild(btn);
  });
}

function isSubQUnlocked(index) {
  var pos = solve.subQOrder.indexOf(index);
  if (pos === 0) return true;
  var prev = solve.subQOrder[pos - 1];
  return !!solve.completedSubQs[prev];
}

function switchSubQuestion(index) {
  if (!isSubQUnlocked(index)) return;
  solve.currentSubQIndex = index;
  renderSubQTabs();
  renderMethodToggle();
  renderSteps();
}

// =================================================================
//  解法切换渲染
// =================================================================
function renderMethodToggle() {
  var toggle = document.getElementById('method-toggle');
  var pills = document.getElementById('method-pills');
  if (!toggle || !pills) return;

  var sq = SUB_QUESTIONS.find(function(s) { return s.index === solve.currentSubQIndex; });
  if (!sq || sq.methods.length <= 1 || (sq.methods.length === 1 && sq.methods[0] === '')) {
    toggle.style.display = 'none';
    return;
  }
  toggle.style.display = 'flex';
  pills.innerHTML = '';
  sq.methods.forEach(function(m) {
    var pill = document.createElement('button');
    pill.className = 'method-pill';
    if (m === solve.currentMethod[sq.index]) pill.classList.add('active');
    pill.textContent = m;
    pill.onclick = function() { switchMethod(m); };
    pills.appendChild(pill);
  });
}

function switchMethod(method) {
  var idx = solve.currentSubQIndex;
  if (solve.currentMethod[idx] === method) return;

  var alreadyDone = !!solve.completedSubQs[idx];

  var oldMethod = solve.currentMethod[idx];
  var cards = getStepsFor(idx, oldMethod);
  cards.forEach(function(card, order) {
    var key = idx + '-' + oldMethod + '-' + (order + 1);
    delete solve.stepState[key];
  });

  var newCards = getStepsFor(idx, method);
  newCards.forEach(function(card, order) {
    var key = idx + '-' + method + '-' + (order + 1);
    solve.stepState[key] = {
      card: (order === 0),
      content: false,
      arrowHidden: false,
      feedbackGiven: false,
    };
  });

  solve.currentMethod[idx] = method;

  if (!alreadyDone) {
    delete solve.completedSubQs[idx];
  }

  renderMethodToggle();
  renderSteps();
  document.getElementById('subq-complete-toast').style.display = 'none';
  document.getElementById('congrats-section').style.display = 'none';
  scrollToSteps();
}

// =================================================================
//  步骤渲染
// =================================================================
function renderSteps() {
  var idx = solve.currentSubQIndex;
  var method = solve.currentMethod[idx];

  var locked = document.getElementById('subq-locked-placeholder');
  if (!isSubQUnlocked(idx)) {
    if (locked) locked.style.display = 'block';
    document.getElementById('step-container').style.display = 'none';
    return;
  }
  if (locked) locked.style.display = 'none';
  document.getElementById('step-container').style.display = 'block';

  var allCards = document.querySelectorAll('.step-card');
  allCards.forEach(function(card) {
    var sq = card.dataset.subq;
    var m = card.dataset.method;
    if (parseInt(sq) === idx && m === method) {
      card.style.display = 'block';
    } else {
      card.style.display = 'none';
    }
  });

  var visibleCards = getStepsFor(idx, method);
  visibleCards.forEach(function(card, order) {
    var key = idx + '-' + method + '-' + (order + 1);
    var st = solve.stepState[key];
    if (!st) return;
    var content = card.querySelector('.step-content');
    var feedback = card.querySelector('.feedback-row');
    var arrow = card.querySelector('.next-btn');
    if (content) content.style.display = st.content ? 'block' : 'none';
    if (feedback) feedback.style.display = st.content ? 'flex' : 'none';
    if (arrow) arrow.style.display = st.arrowHidden ? 'none' : '';
    if (order > 0) {
      var prevKey = idx + '-' + method + '-' + order;
      var prevSt = solve.stepState[prevKey];
      if (prevSt && prevSt.feedbackGiven) {
        card.style.display = 'block';
        if (st.card === false) {
          st.card = true;
        }
      } else if (!st.feedbackGiven && !st.content) {
        card.style.display = 'none';
      }
    }
  });
}

// =================================================================
//  初始化
// =================================================================
function initSolvePage() {
  initStepStates();
  renderSubQTabs();
  renderMethodToggle();
  renderSteps();
}
