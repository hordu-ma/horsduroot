const header = document.querySelector(".site-header");
const revealItems = document.querySelectorAll(".reveal");
const copyWechatButton = document.querySelector(".copy-wechat");
const navToggle = document.querySelector(".nav-toggle");
const mobileNav = document.querySelector(".mobile-nav");

function updateHeader() {
  header.classList.toggle("scrolled", window.scrollY > 28);
}

window.addEventListener("scroll", updateHeader, { passive: true });
updateHeader();

const revealObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add("in-view");
        revealObserver.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.16 }
);

revealItems.forEach((item, index) => {
  item.style.transitionDelay = `${Math.min(index * 40, 180)}ms`;
  revealObserver.observe(item);
});

// 移动端导航汉堡菜单
if (navToggle && mobileNav) {
  const closeNav = () => {
    navToggle.setAttribute("aria-expanded", "false");
    navToggle.setAttribute("aria-label", "打开导航菜单");
    mobileNav.hidden = true;
  };

  navToggle.addEventListener("click", () => {
    const isOpen = navToggle.getAttribute("aria-expanded") === "true";
    if (isOpen) {
      closeNav();
    } else {
      navToggle.setAttribute("aria-expanded", "true");
      navToggle.setAttribute("aria-label", "关闭导航菜单");
      mobileNav.hidden = false;
    }
  });

  // 点击链接后收起菜单
  mobileNav.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", closeNav);
  });

  // Esc 关闭，窗口放大到桌面尺寸时重置
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeNav();
  });
  window.addEventListener("resize", () => {
    if (window.innerWidth > 1020) closeNav();
  });
}

// 复制微信号：成功后 2 秒回滚，并通过 aria-live 区域播报；不支持剪贴板时降级提示
if (copyWechatButton) {
  const status = document.querySelector(".copy-status");
  const label = copyWechatButton.querySelector(".copy-label");
  const wechatId = copyWechatButton.dataset.copy || "";
  let resetTimer;

  const announce = (message) => {
    if (status) status.textContent = message;
  };

  copyWechatButton.addEventListener("click", async () => {
    clearTimeout(resetTimer);
    let copied = false;
    try {
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(wechatId);
        copied = true;
      }
    } catch {
      copied = false;
    }

    if (copied) {
      if (label) label.textContent = "已复制";
      announce(`微信号 ${wechatId} 已复制到剪贴板`);
      resetTimer = setTimeout(() => {
        if (label) label.textContent = "微信";
        announce("");
      }, 2000);
    } else {
      announce(`请手动复制微信号：${wechatId}`);
    }
  });
}
