const screens = {
  records: ['投稿记录', '查看进度，并优先处理被打回的投稿', '我的投稿'],
  type: ['选择投稿类型', '先选择内容类型，再确认原创或外部来源', '开始投稿'],
  import: ['AI 转写导入', '外部 AI JSON 是新题投稿的主要入口', '投稿新题'],
  verify: ['核对题目', '以最终题库效果为中心完成校对', '投稿新题'],
  metadata: ['补充信息', '补齐来源、标签和题目特征', '投稿新题'],
  confirm: ['确认提交', '提交前展示审核员将看到的完整内容', '投稿新题'],
  detail: ['投稿详情', '查看最终收录结果和完整处理记录', '投稿详情'],
};

function showScreen(name) {
  if (!screens[name]) return;
  document.querySelectorAll('[data-screen-panel]').forEach(el => el.classList.toggle('active', el.dataset.screenPanel === name));
  document.querySelectorAll('.nav-item').forEach(el => el.classList.toggle('active', el.dataset.screen === name));
  document.querySelector('#screen-title').textContent = screens[name][0];
  document.querySelector('#screen-note').textContent = screens[name][1];
  document.querySelector('#app-title').textContent = screens[name][2];
  document.querySelector('#app-frame').scrollTop = 0;
}

document.querySelectorAll('[data-goto]').forEach(button => button.addEventListener('click', () => showScreen(button.dataset.goto)));
document.querySelectorAll('.nav-item').forEach(button => button.addEventListener('click', () => showScreen(button.dataset.screen)));
document.querySelectorAll('[data-width]').forEach(button => button.addEventListener('click', () => {
  document.querySelectorAll('[data-width]').forEach(item => item.classList.remove('active'));
  button.classList.add('active');
  document.querySelector('#app-frame').classList.toggle('mobile', button.dataset.width === 'mobile');
}));
document.querySelectorAll('.choice-card').forEach(button => button.addEventListener('click', () => {
  document.querySelectorAll('.choice-card').forEach(item => item.classList.remove('selected'));
  button.classList.add('selected');
}));

const toast = document.querySelector('#toast');
function showToast(message) {
  toast.textContent = message;
  toast.classList.add('show');
  window.setTimeout(() => toast.classList.remove('show'), 1800);
}
document.querySelector('#copy-prompt').addEventListener('click', () => showToast('提示词已复制'));
document.querySelector('#verify-next').addEventListener('click', () => {
  const checked = document.querySelector('#verified-check').checked;
  document.querySelector('#verify-error').classList.toggle('hidden', checked);
  if (checked) showScreen('metadata');
});
document.querySelector('#submit-button').addEventListener('click', () => {
  showToast('投稿已提交审核');
  window.setTimeout(() => showScreen('records'), 700);
});
