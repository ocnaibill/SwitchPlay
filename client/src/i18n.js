const translations = {
  'en-US': {
    'app-subtitle': 'Connect, play, dominate — no configuration needed.',
    'settings-title': '⚙️ Settings',
    'setting-headscale': 'Headscale URL',
    'setting-authkey': 'Tailscale Auth Key',
    'setting-lanplay': 'LAN Play Server IP:PORT',
    'status-vpn': 'VPN',
    'status-lanplay': 'LAN Play',
    'status-server': 'Server',
    'btn-connect': 'Connect',
    'btn-disconnect': 'Disconnect',
    'btn-connecting': 'Connecting...',
    'btn-disconnecting': 'Disconnecting...',
    'btn-transmitter': '📡 Transmitter Mode',
    'transmitter-header': '📡 Transmitter Mode — Physical Switch',
    'transmitter-label': 'Configure your Switch Gateway to:',
    'log-header': '📋 Console',
    'btn-clear-log': 'Clear',
    'status-disconnected': 'Disconnected',
    'status-connected': 'Connected',
    'status-pending': 'Pending',
    'status-active': 'Active',
    'status-error': 'Error',
    'log-ready': 'SwitchPlay v1.0.0 — Ready.',
    'err-settings': 'Error: Fill in Headscale URL and Auth Key in settings first.',
    'err-connect': 'Error when connecting:',
    'err-disconnect': 'Error when disconnecting:'
  },
  'pt-BR': {
    'app-subtitle': 'Conecte, jogue, domine — sem configuração.',
    'settings-title': '⚙️ Configurações',
    'setting-headscale': 'Headscale URL',
    'setting-authkey': 'Tailscale Auth Key',
    'setting-lanplay': 'Servidor LAN Play IP:PORT',
    'status-vpn': 'VPN',
    'status-lanplay': 'LAN Play',
    'status-server': 'Servidor',
    'btn-connect': 'Conectar',
    'btn-disconnect': 'Desconectar',
    'btn-connecting': 'Conectando...',
    'btn-disconnecting': 'Desconectando...',
    'btn-transmitter': '📡 Modo Transmissor',
    'transmitter-header': '📡 Modo Transmissor — Switch Físico',
    'transmitter-label': 'Configure o Gateway do Switch para:',
    'log-header': '📋 Console',
    'btn-clear-log': 'Limpar',
    'status-disconnected': 'Desconectado',
    'status-connected': 'Conectado',
    'status-pending': 'Pendente',
    'status-active': 'Ativo',
    'status-error': 'Erro',
    'log-ready': 'SwitchPlay v1.0.0 — Pronto.',
    'err-settings': 'Erro: Preencha Headscale URL e Auth Key nas configurações primeiro.',
    'err-connect': 'Erro ao conectar:',
    'err-disconnect': 'Erro ao desconectar:'
  }
};

let currentLang = localStorage.getItem('sp_lang') || 'en-US';

function setLanguage(lang) {
  if (!translations[lang]) return;
  currentLang = lang;
  localStorage.setItem('sp_lang', lang);
  document.documentElement.lang = lang;
  applyTranslations();
}

function t(key) {
  return translations[currentLang][key] || key;
}

function applyTranslations() {
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (el.tagName === 'INPUT' && el.type === 'text' || el.tagName === 'INPUT' && el.type === 'url' || el.tagName === 'INPUT' && el.type === 'password') {
      // Inputs already have labels usually, placeholder translations can be handled if needed, 
      // but let's just stick to innerHTML for labels/spans/etc
    } else {
      el.innerHTML = t(key);
    }
  });

  // Update specific elements that might change dynamically
  const connectBtnText = document.getElementById('btn-connect-text');
  if (connectBtnText) {
    if (window.isConnecting) {
      connectBtnText.textContent = t('btn-connecting');
    } else if (window.isConnected) {
      connectBtnText.textContent = t('btn-disconnect');
    } else {
      connectBtnText.textContent = t('btn-connect');
    }
  }

  const logReady = document.querySelector('.log-info');
  if (logReady && logReady.textContent.includes('SwitchPlay')) {
    logReady.textContent = t('log-ready');
  }

  // Set the current language in the selector
  const langSelect = document.getElementById('lang-select');
  if (langSelect) {
    langSelect.value = currentLang;
  }
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
  applyTranslations();
  const select = document.getElementById('lang-select');
  if (select) {
    select.addEventListener('change', (e) => setLanguage(e.target.value));
  }
});

// Export for global use
window.t = t;
window.setLanguage = setLanguage;
