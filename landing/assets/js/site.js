
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
    ["software.html", "免费软件", "software"],
    ["courses.html", "系统课程", "courses"],
    ["team.html", "团队介绍", "team"],
    ["about.html", "关于我们", "about"]
  ];

  function activeClass(key) {
    if (page === key) return " is-active";
    if (page.startsWith("course-") && key === "courses") return " is-active";
    return "";
  }

  function headerHTML() {
    return `
      <header class="site-header">
        <div class="container site-header__inner">
          <a class="brand" href="index.html" aria-label="返回章鱼智学首页">
            <span class="brand__mark">
              <img src="assets/images/icon-app-48.png" alt="" aria-hidden="true">
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
            <button class="button button--primary" type="button" data-open-wechat>微信了解课程</button>
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
            <p>${config.slogan || "专注高考数学，让学习更高效"}。软件、学习社群与公益讲座现阶段免费开放；系统课程为付费教学服务，详情请添加微信了解。</p>
          </div>
          <div>
            <h4>产品与服务</h4>
            <div class="footer-links">
              <a href="software.html">免费软件</a>
              <a href="courses.html">系统课程</a>
              <a href="course-innovation.html">创新题课程</a>
            </div>
          </div>
          <div>
            <h4>了解项目</h4>
            <div class="footer-links">
              <a href="team.html">团队介绍</a>
              <a href="about.html">关于我们</a>
              <button class="text-link" type="button" data-open-wechat>微信咨询</button>
            </div>
          </div>
          <div>
            <h4>联系方式</h4>
            <div class="footer-links">
              <a href="${config.phoneHref || "tel:18500794866"}">电话：${config.phoneDisplay || "18500794866"}</a>
              <span>微信：${config.wechatName || "章鱼宝宝"}${config.wechatId ? "（"+config.wechatId+"）" : ""}</span>
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
          <p class="eyebrow">课程、试听与软件问题</p>
          <h2 id="wechat-title">添加微信了解详情</h2>
          <p class="muted">微信：<strong>${config.wechatName || "章鱼宝宝"}</strong></p>
          ${config.wechatId ? `<p class="muted" style="margin-top:0">微信号：<strong>${config.wechatId}</strong> · 备注「章鱼智学」</p>` : ""}
          <div class="modal__qr">
            <img src="${config.wechatQr || "assets/images/qr-wechat-placeholder.svg"}" alt="微信二维码">
          </div>
          <a class="button button--secondary button--block" href="${config.phoneHref || "tel:18500794866"}">电话联系：${config.phoneDisplay || "18500794866"}</a>
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
    menuToggle.addEventListener("click", () => {
      const open = nav.classList.toggle("is-open");
      menuToggle.setAttribute("aria-expanded", String(open));
      menuToggle.setAttribute("aria-label", open ? "收起导航" : "展开导航");
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

  document.addEventListener("keydown", event => {
    if (event.key === "Escape" && modal?.classList.contains("is-open")) closeModal();
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
})();
