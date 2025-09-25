// script.js — comportamiento del menú interactivo
// Hecho para ser legible y fácil de modificar

document.addEventListener('DOMContentLoaded', () => {
  const mainMenu = document.getElementById('main-menu');
  const contentContainer = document.getElementById('content-container');
  const cards = document.querySelectorAll('.hexagon-btn.card');
  const backBtn = document.querySelector('.back-btn');
  const searchInput = document.getElementById('search');
  const themeToggle = document.getElementById('theme-toggle');

  // === Helpers ===
  const showMainMenu = () => {
    mainMenu.style.display = '';
    contentContainer.classList.remove('show');
    // hide all sections
    document.querySelectorAll('.content-section').forEach(sec => {
      sec.classList.remove('active');
      sec.setAttribute('aria-hidden','true');
    });
    // clean hash without reloading (pushState)
    if (location.hash) history.replaceState(null, '', ' ');
    // focus container for accessibility
    document.getElementById('main').focus();
  };

  const showSection = (id, push = true) => {
    const target = document.getElementById(id);
    if (!target) return;
    // hide menu, show panel
    mainMenu.style.display = 'none';
    contentContainer.classList.add('show');

    // hide others, show target
    document.querySelectorAll('.content-section').forEach(sec => {
      sec.classList.remove('active');
      sec.setAttribute('aria-hidden','true');
    });
    target.classList.add('active');
    target.setAttribute('aria-hidden','false');

    // update hash so back button works
    if (push) history.pushState({section:id}, '', `#${id}`);
    // move focus into content for screen readers
    target.querySelector('h2')?.focus?.();
  };

  // === Card click & keyboard support (delegation) ===
  cards.forEach(card => {
    // click
    card.addEventListener('click', (e) => {
      e.preventDefault();
      const target = card.dataset.target;
      showSection(target);
    });
    // keyboard (Enter / Space)
    card.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        card.click();
      }
    });
  });

  // Back button
  backBtn.addEventListener('click', (e) => {
    e.preventDefault();
    showMainMenu();
  });

  // Handle browser back/forward
  window.addEventListener('popstate', (e) => {
    const hash = location.hash.replace('#','');
    if (hash) {
      showSection(hash, false);
    } else {
      showMainMenu();
    }
  });

  // If page opened with a hash, open that section
  if (location.hash) {
    const hashId = location.hash.replace('#','');
    // small timeout ensures CSS transitions run nicely on load
    setTimeout(() => showSection(hashId, false), 150);
  }

  // === Simple search/filter for cards (client-side) ===
  searchInput.addEventListener('input', (e) => {
    const q = e.target.value.trim().toLowerCase();
    cards.forEach(card => {
      const text = (card.textContent || '').toLowerCase();
      card.style.display = text.includes(q) ? '' : 'none';
    });
  });

  // === Theme toggle (light/dark) ===
  const applyTheme = (dark) => {
    if (dark) {
      document.documentElement.classList.add('dark');
      themeToggle.setAttribute('aria-pressed','true');
      localStorage.setItem('theme','dark');
    } else {
      document.documentElement.classList.remove('dark');
      themeToggle.setAttribute('aria-pressed','false');
      localStorage.setItem('theme','light');
    }
  };
  // initialize from preference or system
  const saved = localStorage.getItem('theme');
  if (saved) applyTheme(saved === 'dark');
  else applyTheme(window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches);

  themeToggle.addEventListener('click', () => {
    const isDark = document.documentElement.classList.toggle('dark');
    applyTheme(isDark);
  });

  // Accessibility: allow ESC to go back to menu
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      showMainMenu();
    }
  });

  // Expose small API to window for quick edits in console or scripts
  window.appMenu = {
    showSection,
    showMainMenu,
    cards,
  };
});