(function () {
  'use strict';

  function make(tag, className, text) {
    var element = document.createElement(tag);
    if (className) element.className = className;
    if (text !== undefined) element.textContent = text;
    return element;
  }

  function renderMath(container) {
    if (!container || typeof window.renderMathInElement !== 'function') return;
    window.renderMathInElement(container, {
      delimiters: [
        {left: '$$', right: '$$', display: true},
        {left: '$', right: '$', display: false},
        {left: '\\(', right: '\\)', display: false},
        {left: '\\[', right: '\\]', display: true}
      ],
      throwOnError: false
    });
  }

  function initQueue() {
    document.querySelectorAll('.queue-row[data-href]').forEach(function (row) {
      function openRow(event) {
        if (event.target.closest('a,button,input,select')) return;
        window.location.href = row.dataset.href;
      }
      row.addEventListener('click', openRow);
      row.addEventListener('keydown', function (event) {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          window.location.href = row.dataset.href;
        }
      });
    });
    document.querySelectorAll('.math-content').forEach(renderMath);
  }

  function textValue(value) {
    if (value === null || value === undefined || value === '') return '-';
    if (Array.isArray(value)) return value.join('\n');
    if (typeof value === 'object') return JSON.stringify(value, null, 2);
    return String(value);
  }

  function optionText(value) {
    if (!value) return '-';
    if (!Array.isArray(value)) {
      return Object.entries(value).map(function (entry) {
        return entry[0] + '. ' + entry[1];
      }).join('\n');
    }
    return value.map(function (item) {
      return (item.key || '?') + '. ' + (item.content || '');
    }).join('\n');
  }

  function subQuestionText(value, field) {
    if (!Array.isArray(value) || !value.length) return '-';
    return value.map(function (item, index) {
      var prefix = value.length > 1 ? '第 ' + (index + 1) + ' 小题：' : '';
      return prefix + (item[field] || '-');
    }).join('\n');
  }

  function sourceText(value) {
    value = value || {};
    var sourceLabels = {
      gaokao: '高考', mock_exam: '模拟考试', school_exam: '校内考试',
      textbook: '教材', self_created: '原创', other: '其他'
    };
    return [
      '来源类型：' + (sourceLabels[value.source_type] || value.source_type || '-'),
      '年份：' + textValue(value.year),
      '地区：' + textValue(value.region),
      '试卷或资料名称：' + textValue(value.source_name || value.exam_name),
      '题号：' + textValue(value.question_number || value.number)
    ].join('\n');
  }

  function renderQuestion(container, payload) {
    container.replaceChildren();
    if (!payload || typeof payload !== 'object') {
      container.appendChild(make('div', 'preview-error', '题目 JSON 无法解析，修复后才能预览。'));
      return;
    }
    var stem = make('div', 'question-stem math-content', payload.stem || '（题干为空）');
    container.appendChild(stem);
    if (payload.question_type === 'choice' && Array.isArray(payload.options)) {
      var options = make('ol', 'question-options');
      payload.options.forEach(function (option) {
        var item = make('li', 'math-content');
        item.appendChild(make('span', 'option-key', (option.key || '?') + '.'));
        item.appendChild(document.createTextNode(option.content || ''));
        options.appendChild(item);
      });
      container.appendChild(options);
    }
    var answerBlock = make('div', 'answer-block');
    (payload.sub_questions || []).forEach(function (subQuestion, index) {
      var item = make('section', 'subquestion-preview');
      item.appendChild(make('h3', '', payload.sub_questions.length > 1 ? '第 ' + (index + 1) + ' 小题' : '答案与解析'));
      if (subQuestion.stem) item.appendChild(make('p', 'math-content', subQuestion.stem));
      var answer = make('p', 'math-content');
      answer.appendChild(make('strong', '', '答案：'));
      answer.appendChild(document.createTextNode(subQuestion.answer || '（未填写）'));
      item.appendChild(answer);
      var explanation = make('p', 'math-content');
      explanation.appendChild(make('strong', '', '解析：'));
      explanation.appendChild(document.createTextNode(subQuestion.explanation || '（未填写）'));
      item.appendChild(explanation);
      answerBlock.appendChild(item);
    });
    container.appendChild(answerBlock);
    var source = payload.source || {};
    var meta = make('div', 'question-meta');
    [
      '题型：' + textValue(payload.question_type),
      '来源：' + textValue(source.source_type),
      '年份：' + textValue(source.year),
      '地区：' + textValue(source.region),
      '试卷或资料：' + textValue(source.source_name || source.exam_name),
      '题号：' + textValue(source.question_number || source.number),
      '难度：' + textValue(payload.difficulty),
      '计算量：' + textValue(payload.calculation)
    ].forEach(function (value) { meta.appendChild(make('span', '', value)); });
    container.appendChild(meta);
    renderMath(container);
  }

  function addField(parent, labelText, control) {
    var label = make('label');
    label.appendChild(make('span', '', labelText));
    label.appendChild(control);
    parent.appendChild(label);
    return control;
  }

  function input(type, value, name) {
    var control = document.createElement('input');
    control.type = type;
    control.value = value === null || value === undefined ? '' : value;
    if (name) control.dataset.field = name;
    return control;
  }

  function textarea(value, name, rows) {
    var control = document.createElement('textarea');
    control.value = value || '';
    control.rows = rows || 3;
    if (name) control.dataset.field = name;
    return control;
  }

  function select(values, selected, name) {
    var control = document.createElement('select');
    values.forEach(function (entry) {
      var option = document.createElement('option');
      option.value = entry[0];
      option.textContent = entry[1];
      option.selected = entry[0] === selected;
      control.appendChild(option);
    });
    if (name) control.dataset.field = name;
    return control;
  }

  function initReviewForm(form) {
    var contentJson = document.getElementById('id_content_json');
    var preview = document.getElementById('question-preview');
    var structured = document.getElementById('structured-editor');
    var liveError = document.getElementById('json-live-error');
    var terminal = form.dataset.terminal === 'true';
    var originalScript = document.getElementById('original-question-payload');
    var originalPayload = originalScript ? JSON.parse(originalScript.textContent) : null;
    var currentPayload = null;
    var dirty = false;
    var submitting = false;
    var saveState = document.getElementById('save-state');
    var version = document.getElementById('id_version').value;
    var draftKey = 'review-draft:' + form.dataset.contributionId;
    var draftTimer;

    function setDirty(value) {
      dirty = value;
      if (!saveState) return;
      saveState.textContent = value ? '修改已保存在本机草稿' : '尚未修改';
      saveState.classList.toggle('is-dirty', value);
    }

    function parseJson(showError) {
      try {
        currentPayload = JSON.parse(contentJson.value);
        if (liveError) liveError.hidden = true;
        renderQuestion(preview, currentPayload);
        renderDiff();
        return currentPayload;
      } catch (error) {
        currentPayload = null;
        if (showError && liveError) {
          liveError.textContent = 'JSON 格式错误：' + error.message;
          liveError.hidden = false;
        }
        renderQuestion(preview, null);
        return null;
      }
    }

    function renderDiff() {
      var diff = document.getElementById('diff-preview');
      if (!diff || !originalPayload || !currentPayload) return;
      diff.replaceChildren();
      var rows = [
        ['题干', originalPayload.stem, currentPayload.stem, textValue],
        ['选项', originalPayload.options, currentPayload.options, optionText],
        ['答案', originalPayload.sub_questions, currentPayload.sub_questions, function (value) { return subQuestionText(value, 'answer'); }],
        ['解析', originalPayload.sub_questions, currentPayload.sub_questions, function (value) { return subQuestionText(value, 'explanation'); }],
        ['来源', originalPayload.source, currentPayload.source, sourceText]
      ];
      rows.forEach(function (values) {
        var oldText = values[3](values[1]);
        var newText = values[3](values[2]);
        var row = make('div', 'diff-row' + (oldText === newText ? ' is-same' : ''));
        row.appendChild(make('div', 'diff-label', values[0]));
        row.appendChild(make('div', 'diff-value math-content' + (oldText !== newText ? ' is-old' : ''), oldText));
        row.appendChild(make('div', 'diff-arrow', '→'));
        row.appendChild(make('div', 'diff-value math-content' + (oldText !== newText ? ' is-new' : ''), newText));
        diff.appendChild(row);
      });
      renderMath(diff);
    }

    function initCopyButtons() {
      document.querySelectorAll('[data-copy-source]').forEach(function (button) {
        button.addEventListener('click', async function () {
          var source = document.getElementById(button.dataset.copySource);
          if (!source) return;
          try {
            await navigator.clipboard.writeText(source.textContent || '');
            var original = button.textContent;
            button.textContent = '已复制';
            window.setTimeout(function () { button.textContent = original; }, 1200);
          } catch (error) {
            window.alert('复制失败，请手动选择原文。');
          }
        });
      });
    }

    function queueDraftSave() {
      if (terminal) return;
      window.clearTimeout(draftTimer);
      draftTimer = window.setTimeout(function () {
        var tagIds = Array.from(form.querySelectorAll('.tag-options input:checked')).map(function (item) { return item.value; });
        localStorage.setItem(draftKey, JSON.stringify({version: version, content: contentJson.value, note: document.getElementById('id_note').value, tags: tagIds}));
      }, 250);
    }

    function changed() {
      setDirty(true);
      queueDraftSave();
    }

    function syncJsonFromStructured() {
      if (!currentPayload) return;
      var source = currentPayload.source || {};
      currentPayload.question_type = structured.querySelector('[data-field="question_type"]').value;
      currentPayload.stem = structured.querySelector('[data-field="stem"]').value;
      source.source_type = structured.querySelector('[data-field="source_type"]').value;
      var yearValue = structured.querySelector('[data-field="year"]').value;
      source.year = yearValue ? Number(yearValue) : null;
      source.region = structured.querySelector('[data-field="region"]').value;
      source.source_name = structured.querySelector('[data-field="source_name"]').value;
      source.question_number = structured.querySelector('[data-field="question_number"]').value;
      delete source.exam_name;
      delete source.number;
      currentPayload.source = source;
      currentPayload.difficulty = structured.querySelector('[data-field="difficulty"]').value;
      currentPayload.calculation = structured.querySelector('[data-field="calculation"]').value;
      currentPayload.options = Array.from(structured.querySelectorAll('.option-item')).map(function (row) {
        return {key: row.querySelector('[data-option="key"]').value, content: row.querySelector('[data-option="content"]').value};
      });
      currentPayload.sub_questions = Array.from(structured.querySelectorAll('.subquestion-item')).map(function (row) {
        return {
          stem: row.querySelector('[data-sub="stem"]').value,
          answer: row.querySelector('[data-sub="answer"]').value,
          explanation: row.querySelector('[data-sub="explanation"]').value
        };
      });
      contentJson.value = JSON.stringify(currentPayload, null, 2);
      renderQuestion(preview, currentPayload);
      renderDiff();
      changed();
    }

    function repeatHeader(title, addText, onAdd) {
      var header = make('div', 'editor-section-header');
      header.appendChild(make('h3', '', title));
      var button = make('button', '', addText);
      button.type = 'button';
      button.addEventListener('click', onAdd);
      header.appendChild(button);
      return header;
    }

    function optionRow(option) {
      var row = make('div', 'repeat-item option-item');
      var key = input('text', option.key || ''); key.dataset.option = 'key';
      var content = input('text', option.content || ''); content.dataset.option = 'content';
      addField(row, '标识', key); addField(row, '选项内容', content);
      var remove = make('button', 'remove-item', '×'); remove.type = 'button'; remove.title = '删除选项';
      remove.addEventListener('click', function () { row.remove(); syncJsonFromStructured(); });
      row.appendChild(remove);
      return row;
    }

    function subQuestionRow(item) {
      var row = make('div', 'repeat-item subquestion-item');
      var stem = textarea(item.stem || '', '', 2); stem.dataset.sub = 'stem';
      var answer = textarea(item.answer || '', '', 2); answer.dataset.sub = 'answer';
      var explanation = textarea(item.explanation || '', '', 4); explanation.dataset.sub = 'explanation';
      addField(row, '小题题干（可空）', stem); addField(row, '答案', answer); addField(row, '解析', explanation);
      var remove = make('button', 'remove-item', '×'); remove.type = 'button'; remove.title = '删除小题';
      remove.addEventListener('click', function () { row.remove(); syncJsonFromStructured(); });
      row.appendChild(remove);
      return row;
    }

    function buildStructured(payload) {
      if (!structured || !payload) return;
      structured.replaceChildren();
      var basic = make('div', 'field-grid');
      addField(basic, '题型', select([['choice', '选择题'], ['fill', '填空题'], ['solution', '解答题']], payload.question_type, 'question_type'));
      addField(basic, '难度', select([['basic', '基础'], ['easy', '容易'], ['medium', '中等'], ['hard', '困难'], ['very_hard', '很难']], payload.difficulty, 'difficulty'));
      addField(basic, '计算量', select([['very_low', '很低'], ['low', '低'], ['high', '高'], ['very_high', '很高']], payload.calculation, 'calculation'));
      structured.appendChild(basic);
      addField(structured, '题干（Markdown / LaTeX）', textarea(payload.stem, 'stem', 6));
      var source = payload.source || {};
      var sourceGrid = make('div', 'field-grid');
      addField(sourceGrid, '来源', select([['gaokao', '高考'], ['mock_exam', '模拟考试'], ['school_exam', '校内考试'], ['textbook', '教材'], ['self_created', '原创'], ['other', '其他']], source.source_type || 'other', 'source_type'));
      addField(sourceGrid, '年份', input('number', source.year, 'year'));
      addField(sourceGrid, '地区', input('text', source.region, 'region'));
      addField(sourceGrid, '试卷或资料名称', input('text', source.source_name || source.exam_name, 'source_name'));
      addField(sourceGrid, '题号', input('text', source.question_number || source.number, 'question_number'));
      structured.appendChild(sourceGrid);
      var optionsSection = make('section', 'editor-section');
      var optionsList = make('div', 'options-list');
      optionsSection.appendChild(repeatHeader('选项', '添加选项', function () { optionsList.appendChild(optionRow({key: '', content: ''})); syncJsonFromStructured(); }));
      (payload.options || []).forEach(function (option) { optionsList.appendChild(optionRow(option)); });
      optionsSection.appendChild(optionsList); structured.appendChild(optionsSection);
      var subSection = make('section', 'editor-section');
      var subList = make('div', 'subquestions-list');
      subSection.appendChild(repeatHeader('答案与解析', '添加小题', function () { subList.appendChild(subQuestionRow({stem: '', answer: '', explanation: ''})); syncJsonFromStructured(); }));
      (payload.sub_questions || []).forEach(function (item) { subList.appendChild(subQuestionRow(item)); });
      subSection.appendChild(subList); structured.appendChild(subSection);
      structured.addEventListener('input', syncJsonFromStructured);
      structured.addEventListener('change', syncJsonFromStructured);
    }

    function updateSelectedTags() {
      var target = document.getElementById('selected-tags');
      if (!target) return;
      target.replaceChildren();
      var checked = Array.from(form.querySelectorAll('.tag-options input:checked'));
      if (!checked.length) target.appendChild(make('span', 'tag-empty', '尚未选择标签'));
      checked.forEach(function (checkbox) {
        var label = checkbox.closest('label');
        var chip = make('span', 'tag-chip', label ? label.textContent.trim() : checkbox.value);
        if (!terminal) {
          var remove = make('button', '', '×'); remove.type = 'button'; remove.title = '移除标签';
          remove.addEventListener('click', function () { checkbox.checked = false; updateSelectedTags(); changed(); });
          chip.appendChild(remove);
        }
        target.appendChild(chip);
      });
    }

    function initTags() {
      var dialog = document.getElementById('tag-dialog');
      var open = document.getElementById('open-tag-dialog');
      var search = document.getElementById('tag-search');
      var count = document.getElementById('tag-result-count');
      var options = Array.from(dialog.querySelectorAll('.tag-options label'));
      if (open) open.addEventListener('click', function () { dialog.showModal(); search.focus(); });
      dialog.querySelectorAll('[data-close-dialog]').forEach(function (button) { button.addEventListener('click', function () { dialog.close(); }); });
      search.addEventListener('input', function () {
        var query = search.value.trim().toLowerCase();
        var visible = 0;
        options.forEach(function (item) {
          var show = !query || item.textContent.toLowerCase().includes(query);
          item.hidden = !show;
          if (show) visible += 1;
        });
        count.textContent = '显示 ' + visible + ' 个标签';
      });
      dialog.querySelectorAll('input[type="checkbox"]').forEach(function (checkbox) { checkbox.addEventListener('change', function () { updateSelectedTags(); changed(); }); });
      updateSelectedTags();
    }

    function initTabs() {
      document.querySelectorAll('[data-tab]').forEach(function (button) {
        button.addEventListener('click', function () {
          document.querySelectorAll('[data-tab]').forEach(function (item) { item.classList.toggle('is-active', item === button); });
          document.querySelectorAll('[data-panel]').forEach(function (panel) { panel.classList.toggle('is-active', panel.dataset.panel === button.dataset.tab); });
          if (button.dataset.tab === 'structured') buildStructured(parseJson(true));
          if (button.dataset.tab === 'preview') renderQuestion(preview, parseJson(true));
        });
      });
    }

    function initDraft() {
      if (terminal) { localStorage.removeItem(draftKey); return; }
      if (document.querySelector('.messages')) localStorage.removeItem(draftKey);
      var raw = localStorage.getItem(draftKey);
      if (!raw) return;
      try {
        var draft = JSON.parse(raw);
        if (draft.version !== version || (draft.content === contentJson.value && draft.note === document.getElementById('id_note').value)) return;
        var banner = document.getElementById('draft-banner');
        banner.hidden = false;
        banner.querySelector('[data-draft="restore"]').addEventListener('click', function () {
          contentJson.value = draft.content;
          document.getElementById('id_note').value = draft.note || '';
          form.querySelectorAll('.tag-options input').forEach(function (checkbox) { checkbox.checked = draft.tags.includes(checkbox.value); });
          banner.hidden = true; parseJson(true); updateSelectedTags(); setDirty(true);
        });
        banner.querySelector('[data-draft="discard"]').addEventListener('click', function () {
          localStorage.removeItem(draftKey);
          dirty = false;
          window.location.reload();
        });
      } catch (error) { localStorage.removeItem(draftKey); }
    }

    function initActions() {
      if (terminal) return;
      var dialog = document.getElementById('confirm-dialog');
      var title = document.getElementById('confirm-title');
      var description = document.getElementById('confirm-description');
      var summary = document.getElementById('confirm-summary');
      var pendingAction = '';
      var configs = {
        processing: ['标记为处理中', '其他审核员将看到当前处理人。'],
        needs_revision: ['打回投稿修改', '投稿人将看到审核意见，并可修改后重新提交。'],
        rejected: ['确认不采纳', '投稿将结束，不能直接重新提交此记录。'],
        publish: ['审核通过并录入', originalPayload ? '将修改关联的正式题目，请确认最终内容。' : '将创建一条新的正式题目。']
      };
      document.querySelectorAll('[data-review-action]').forEach(function (button) {
        button.addEventListener('click', function () {
          pendingAction = button.dataset.reviewAction;
          var note = document.getElementById('id_note');
          if ((pendingAction === 'needs_revision' || pendingAction === 'rejected') && !note.value.trim()) {
            note.setCustomValidity('请先填写审核意见'); note.reportValidity(); note.focus(); return;
          }
          note.setCustomValidity('');
          if (pendingAction === 'publish' && !parseJson(true)) {
            document.querySelector('[data-tab="json"]').click(); contentJson.focus(); return;
          }
          var selectedTags = form.querySelectorAll('.tag-options input:checked').length;
          var newTags = Array.from(form.querySelectorAll('.suggestion-decision')).filter(function (item) { return item.value === 'create'; }).length;
          var undecidedSuggestions = Array.from(form.querySelectorAll('.suggestion-decision')).filter(function (item) { return !item.value; });
          if (pendingAction === 'publish' && undecidedSuggestions.length) {
            undecidedSuggestions[0].reportValidity(); undecidedSuggestions[0].focus(); return;
          }
          if (pendingAction === 'publish' && selectedTags + newTags === 0) {
            document.getElementById('open-tag-dialog').click(); return;
          }
          title.textContent = configs[pendingAction][0];
          description.textContent = configs[pendingAction][1];
          summary.replaceChildren();
          summary.appendChild(make('div', '', '审核意见：' + (note.value.trim() || '无')));
          if (pendingAction === 'publish') {
            summary.appendChild(make('div', '', '题型：' + currentPayload.question_type + ' · 小题：' + currentPayload.sub_questions.length + ' · 已选标签：' + selectedTags));
          }
          dialog.showModal();
        });
      });
      dialog.querySelector('[data-cancel-confirm]').addEventListener('click', function () { dialog.close(); });
      dialog.querySelector('[data-confirm-action]').addEventListener('click', function () {
        document.getElementById('action-input').value = pendingAction;
        submitting = true; dirty = false; localStorage.removeItem(draftKey); dialog.close(); form.submit();
      });
    }

    contentJson.addEventListener('input', function () { parseJson(true); changed(); });
    var note = document.getElementById('id_note');
    if (note) note.addEventListener('input', changed);
    var format = document.getElementById('format-json');
    if (format) format.addEventListener('click', function () { var payload = parseJson(true); if (payload) { contentJson.value = JSON.stringify(payload, null, 2); changed(); } });
    window.addEventListener('beforeunload', function (event) { if (dirty && !submitting) { event.preventDefault(); event.returnValue = ''; } });

    parseJson(false);
    initTabs();
    initTags();
    initCopyButtons();
    initDraft();
    initActions();
    document.querySelectorAll('.math-content').forEach(renderMath);
    var errorSummary = document.getElementById('error-summary');
    if (errorSummary) { errorSummary.focus(); errorSummary.scrollIntoView({behavior: 'smooth', block: 'start'}); }
  }

  document.addEventListener('DOMContentLoaded', function () {
    initQueue();
    var form = document.getElementById('review-form');
    if (form) initReviewForm(form);
  });
})();
