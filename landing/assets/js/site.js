
(() => {
  const config = window.SITE_CONFIG || {};
  const page = document.body.dataset.page || "";

  const icons = {
    menu: `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 7h16M4 12h16M4 17h16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>`,
    close: `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="m6 6 12 12M18 6 6 18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>`,
    wechat: `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9.7 5.2c-4 0-7.2 2.6-7.2 5.8 0 1.8 1 3.4 2.6 4.5l-.7 2.3 2.6-1.3c.8.2 1.7.4 2.7.4 4 0 7.2-2.6 7.2-5.9s-3.2-5.8-7.2-5.8Z" fill="currentColor" opacity=".95"/><path d="M15 9.1c3.6 0 6.5 2.3 6.5 5.2 0 1.6-.8 3-2.3 4l.6 2-2.3-1.1c-.8.2-1.6.3-2.5.3-3.6 0-6.5-2.3-6.5-5.2S11.4 9 15 9Z" fill="currentColor" opacity=".7"/><circle cx="7.3" cy="10.3" r=".8" fill="#fff"/><circle cx="11.7" cy="10.3" r=".8" fill="#fff"/><circle cx="13" cy="14" r=".75" fill="#fff"/><circle cx="17.2" cy="14" r=".75" fill="#fff"/></svg>`,
    download: `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3v12m0 0 4-4m-4 4-4-4M5 20h14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`
  };

  const navItems = [
    ["index.html", "首页", "home"],
    ["software.html", "软件下载", "software"],
    ["media.html", "圆明智学", "media"],
    ["team.html", "团队介绍", "team"],
    ["about.html", "关于我们", "about"]
  ];

  function activeClass(key) {
    if (page === key) return " is-active";
    return "";
  }

  function headerHTML() {
    return `
      <header class="site-header">
        <div class="container site-header__inner">
          <a class="brand" href="index.html" aria-label="返回章鱼智学首页">
            <span class="brand__mark">
              <img src="assets/images/icon-app-48x48.png" alt="" aria-hidden="true">
            </span>
            <span class="brand__text">
              <span class="brand__name">${config.siteName || "章鱼智学"}</span>
              <span class="brand__tagline">${config.siteTagline || ""}</span>
            </span>
          </a>

          <nav class="nav" id="site-nav" aria-label="主导航">
            ${navItems.map(([href, label, key]) =>
              `<a class="nav__link${activeClass(key)}" href="${href}">${label}</a>`
            ).join("")}
          </nav>

          <div class="header-actions">
            <a class="button button--ghost" href="software.html">下载软件</a>
            <button class="button button--primary" type="button" data-open-wechat>咨询服务</button>
            <button class="menu-toggle" type="button" aria-label="展开导航" aria-controls="site-nav" aria-expanded="false">
              ${icons.menu}
            </button>
          </div>
        </div>
      </header>
    `;
  }

  function footerHTML() {
    const year = new Date().getFullYear();
    const start = config.footer?.copyrightStartYear || year;
    const yearText = start === year ? year : `${start}–${year}`;

    return `
      <footer class="site-footer">
        <div class="container site-footer__main">
          <div class="site-footer__brand">
            <h3>${config.siteName || "章鱼智学"}</h3>
            <p>${config.slogan || "围绕高考数学，系统改进学习过程"}。通过软件、公开内容、学习咨询与个性化学习支持连接不同学习环节。</p>
          </div>
          <div>
            <h4>产品与服务</h4>
            <div class="footer-links">
              <a href="software.html">软件下载</a>
              <a href="media.html">圆明智学视频</a>
              <button class="text-link" type="button" data-open-wechat>学习咨询</button>
              <button class="text-link" type="button" data-open-wechat>个性化学习支持</button>
            </div>
          </div>
          <div>
            <h4>了解项目</h4>
            <div class="footer-links">
              <a href="team.html">团队介绍</a>
              <a href="about.html">关于我们</a>
              <a href="/internal/">团队入口</a>
            </div>
          </div>
          <div>
            <h4>关注圆明智学</h4>
            <div class="footer-links">
              <a href="${config.media?.bilibili || "https://b23.tv/64D6X7S"}" target="_blank" rel="noopener noreferrer">哔哩哔哩</a>
              <a href="${config.media?.xiaohongshu || "https://xhslink.cn/m/7yhO5z9sbjR"}" target="_blank" rel="noopener noreferrer">小红书</a>
              <a href="${config.media?.douyin || "https://v.douyin.com/BZl4YGhfE0E/"}" target="_blank" rel="noopener noreferrer">抖音</a>
              <button class="text-link" type="button" data-open-channels>微信视频号</button>
            </div>
          </div>
          <div>
            <h4>联系方式</h4>
            <div class="footer-links">
              <a href="${config.phoneHref || "tel:18500794866"}">电话：${config.phoneDisplay || "18500794866"}</a>
              <button class="text-link" type="button" data-open-wechat>微信：${config.wechatName || "章鱼宝宝"}${config.wechatId ? "（"+config.wechatId+"）" : ""}</button>
            </div>
          </div>
        </div>
        <div class="container site-footer__bottom">
          <span>© ${yearText} ${config.footer?.operatorName || "章鱼智学项目团队"}</span>
          <div class="legal-links">
            ${page === 'privacy' || page === 'terms' ? `<a href="privacy.html">隐私政策</a>` : ''}
            ${page === 'privacy' || page === 'terms' ? `<a href="terms.html">用户协议</a>` : ''}
            ${page === 'privacy' || page === 'terms' && config.footer?.icp ? `<span>${config.footer.icp}</span>` : ''}
            ${config.footer?.police ? `<span>${config.footer.police}</span>` : ""}
          </div>
        </div>
      </footer>
    `;
  }

  function modalHTML() {
    return `
      <div class="modal" id="wechat-modal" role="dialog" aria-modal="true" aria-labelledby="wechat-title" aria-hidden="true">
        <div class="modal__dialog">
          <button class="modal__close" type="button" aria-label="关闭微信二维码">${icons.close}</button>
          <p class="eyebrow">学习咨询与个性化学习支持</p>
          <h2 id="wechat-title">联系章鱼智学</h2>
          <p class="muted">微信：<strong>${config.wechatName || "章鱼宝宝"}</strong></p>
          ${config.wechatId ? `<p class="muted" style="margin-top:0">微信号：<strong>${config.wechatId}</strong> · 备注「章鱼智学」</p>` : ""}
          <div class="note" style="text-align:left;margin-top:16px">
            可咨询具体学习问题、学习路径和针对性答疑，也可了解一对一或团队多对一学习支持。添加时可备注所在年级和主要问题；无需提供身份证号、住址等敏感信息。
          </div>
          <div class="modal__qr">
            <img src="${config.wechatQr || "assets/images/qr-wechat-placeholder.svg"}" alt="微信二维码">
          </div>
          <a class="button button--secondary button--block" href="${config.phoneHref || "tel:18500794866"}">电话联系：${config.phoneDisplay || "18500794866"}</a>
        </div>
      </div>
    `;
  }

  function channelsModalHTML() {
    const name = config.media?.name || "圆明智学";
    return `
      <div class="modal" id="channels-modal" role="dialog" aria-modal="true" aria-labelledby="channels-title" aria-hidden="true">
        <div class="modal__dialog modal__dialog--compact">
          <button class="modal__close" type="button" aria-label="关闭视频号提示">${icons.close}</button>
          <p class="eyebrow">微信视频号</p>
          <h2 id="channels-title">搜索“${name}”</h2>
          <p class="muted">账号名称已自动复制。请在微信视频号中粘贴搜索。</p>
          <div class="copy-value">${name}</div>
          <button class="button button--primary button--block" type="button" data-copy-channels>再次复制账号名称</button>
          <button class="button button--secondary button--block" type="button" data-open-wechat data-close-channels>查看微信二维码</button>
        </div>
      </div>
    `;
  }

  function auxiliaryHTML() {
    return `
      <div class="floating-contact">
        <button class="floating-contact__button" type="button" data-open-wechat>
          ${icons.wechat}
          微信咨询
        </button>
      </div>

      <div class="mobile-bar" aria-label="手机快捷操作">
        <a class="mobile-bar__link" href="software.html">${icons.download} 下载软件</a>
        <button class="mobile-bar__link" type="button" data-open-wechat>${icons.wechat} 微信咨询</button>
      </div>

      <div class="toast" role="status" aria-live="polite"></div>
      ${modalHTML()}
      ${channelsModalHTML()}
    `;
  }

  document.querySelectorAll("[data-site-header]").forEach(el => el.innerHTML = headerHTML());
  document.querySelectorAll("[data-site-footer]").forEach(el => el.innerHTML = footerHTML());
  document.body.insertAdjacentHTML("beforeend", auxiliaryHTML());

  document.querySelectorAll("[data-config-phone]").forEach(el => {
    el.textContent = config.phoneDisplay || "18500794866";
    if (el.tagName === "A") el.href = config.phoneHref || "tel:18500794866";
  });

  document.querySelectorAll("[data-config-wechat]").forEach(el => {
    el.textContent = config.wechatName || "章鱼宝宝";
  });

  document.querySelectorAll("[data-config-qr]").forEach(el => {
    el.src = config.wechatQr || "assets/images/qr-wechat-placeholder.svg";
  });

  document.querySelectorAll("[data-download-platform]").forEach(el => {
    const platform = el.dataset.downloadPlatform;
    const href = config.downloads?.[platform] || "#";
    el.href = href;
    if (!href || href === "#") {
      el.addEventListener("click", event => {
        event.preventDefault();
        showToast(`${platformLabel(platform)} 下载链接尚未替换`);
      });
    }
  });

  const nav = document.querySelector(".nav");
  const menuToggle = document.querySelector(".menu-toggle");
  if (nav && menuToggle) {
    const closeNav = () => {
      nav.classList.remove("is-open");
      menuToggle.setAttribute("aria-expanded", "false");
      menuToggle.setAttribute("aria-label", "展开导航");
    };

    menuToggle.addEventListener("click", () => {
      const open = nav.classList.toggle("is-open");
      menuToggle.setAttribute("aria-expanded", String(open));
      menuToggle.setAttribute("aria-label", open ? "收起导航" : "展开导航");
    });

    nav.querySelectorAll("a").forEach(link => link.addEventListener("click", closeNav));

    document.addEventListener("click", event => {
      if (!nav.classList.contains("is-open")) return;
      if (nav.contains(event.target) || menuToggle.contains(event.target)) return;
      closeNav();
    });

    document.addEventListener("keydown", event => {
      if (event.key === "Escape" && nav.classList.contains("is-open")) {
        closeNav();
        menuToggle.focus();
      }
    });
  }

  const modal = document.getElementById("wechat-modal");
  const closeButton = modal?.querySelector(".modal__close");
  let lastFocused = null;

  function openModal() {
    if (!modal) return;
    lastFocused = document.activeElement;
    modal.classList.add("is-open");
    modal.setAttribute("aria-hidden", "false");
    document.body.classList.add("modal-open");
    closeButton?.focus();
  }

  function closeModal() {
    if (!modal) return;
    modal.classList.remove("is-open");
    modal.setAttribute("aria-hidden", "true");
    document.body.classList.remove("modal-open");
    lastFocused?.focus?.();
  }

  document.querySelectorAll("[data-open-wechat]").forEach(button => {
    button.addEventListener("click", openModal);
  });

  closeButton?.addEventListener("click", closeModal);
  modal?.addEventListener("click", event => {
    if (event.target === modal) closeModal();
  });

  const channelsModal = document.getElementById("channels-modal");
  const channelsClose = channelsModal?.querySelector(".modal__close");
  const channelsName = config.media?.name || "圆明智学";

  function fallbackCopy(value) {
    const input = document.createElement("textarea");
    input.value = value;
    input.setAttribute("readonly", "");
    input.style.position = "fixed";
    input.style.opacity = "0";
    document.body.appendChild(input);
    input.select();
    const copied = document.execCommand("copy");
    input.remove();
    return copied;
  }

  async function copyText(value) {
    let copied = false;
    try {
      copied = fallbackCopy(value);
    } catch (_) {}
    if (!navigator.clipboard?.writeText) return copied;
    try {
      await navigator.clipboard.writeText(value);
      return true;
    } catch (_) {}
    return copied;
  }

  async function openChannelsModal() {
    if (!channelsModal) return;
    lastFocused = document.activeElement;
    channelsModal.classList.add("is-open");
    channelsModal.setAttribute("aria-hidden", "false");
    document.body.classList.add("modal-open");
    channelsClose?.focus();
    const copied = await copyText(channelsName);
    showToast(copied ? `已复制：${channelsName}` : `请搜索：${channelsName}`);
  }

  function closeChannelsModal() {
    if (!channelsModal) return;
    channelsModal.classList.remove("is-open");
    channelsModal.setAttribute("aria-hidden", "true");
    document.body.classList.remove("modal-open");
    lastFocused?.focus?.();
  }

  document.querySelectorAll("[data-open-channels]").forEach(button => button.addEventListener("click", openChannelsModal));
  document.querySelectorAll("[data-copy-channels]").forEach(button => button.addEventListener("click", async () => {
    const copied = await copyText(channelsName);
    showToast(copied ? `已复制：${channelsName}` : `请搜索：${channelsName}`);
  }));
  channelsClose?.addEventListener("click", closeChannelsModal);
  channelsModal?.addEventListener("click", event => { if (event.target === channelsModal) closeChannelsModal(); });
  document.querySelectorAll("[data-close-channels]").forEach(button => button.addEventListener("click", closeChannelsModal));

  document.addEventListener("keydown", event => {
    if (channelsModal?.classList.contains("is-open") && event.key === "Escape") {
      closeChannelsModal();
      return;
    }
    if (!modal?.classList.contains("is-open")) return;
    if (event.key === "Escape") closeModal();
    if (event.key === "Tab") {
      const focusable = [...modal.querySelectorAll('button, a[href], [tabindex]:not([tabindex="-1"])')]
        .filter(element => !element.hasAttribute("disabled"));
      if (!focusable.length) return;
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    }
  });

  function platformLabel(platform) {
    return {
      android: "Android",
      ios: "iOS",
      windows: "Windows",
      netdisk: "网盘"
    }[platform] || "软件";
  }

  let toastTimer;
  function showToast(message) {
    const toast = document.querySelector(".toast");
    if (!toast) return;
    toast.textContent = message;
    toast.classList.add("is-visible");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove("is-visible"), 2600);
  }

  // ── 平台感知下载卡片排序 ──
  if (page === 'software') {
    const container = document.getElementById('download-cards');
    if (container) {
      const ua = navigator.userAgent.toLowerCase();
      let detected = 'unknown';
      if (/android/.test(ua)) detected = 'android';
      else if (/iphone|ipad|ipod/.test(ua)) detected = 'ios';
      else if (/windows/.test(ua)) detected = 'windows';

      const detectedCard = container.querySelector(`[data-platform="${detected}"]`);
      if (detectedCard && detected !== 'unknown') {
        const cards = [...container.querySelectorAll('.platform-card')];
        const others = cards.filter(c => c !== detectedCard);
        container.innerHTML = '';
        detectedCard.classList.add('platform-card--detected');
        container.appendChild(detectedCard);
        const row = document.createElement('div');
        row.className = 'platform-row';
        row.style.gridTemplateColumns = 'repeat(3, minmax(0, 1fr))';
        others.forEach(c => row.appendChild(c));
        container.appendChild(row);
      }
    }
  }

  // ── 首页设备展示：根据当前设备切换 ──
  if (page === 'home') {
    const hero = document.querySelector('.hero-visual');
    if (hero) {
      const ua = navigator.userAgent.toLowerCase();
      const isMobile = /android|iphone|ipad|ipod/.test(ua);
      hero.classList.add(isMobile ? 'device-mode-mobile' : 'device-mode-desktop');
    }
  }
})();
