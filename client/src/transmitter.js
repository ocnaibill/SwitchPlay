// ========================================
// BillPlay — Transmitter Mode
// Bridge mode for physical Nintendo Switch.
// Detects local IP and guides the user to
// configure the Switch gateway.
// ========================================

const os = require('os');

class TransmitterMode {
    constructor(mainWindow) {
        this.mainWindow = mainWindow;
    }

    _sendLog(message, level = 'info') {
        if (this.mainWindow && !this.mainWindow.isDestroyed()) {
            this.mainWindow.webContents.send('log', { message, level });
        }
    }

    _sendStatus(type, status, message) {
        if (this.mainWindow && !this.mainWindow.isDestroyed()) {
            this.mainWindow.webContents.send('status-update', { type, status, message });
        }
    }

    // --- Detect the local IPv4 address ---
    getLocalIP() {
        const interfaces = os.networkInterfaces();
        const candidates = [];

        for (const [name, addrs] of Object.entries(interfaces)) {
            for (const addr of addrs) {
                // Skip internal (loopback) and non-IPv4
                if (addr.internal || addr.family !== 'IPv4') continue;

                // Skip VPN/virtual interfaces
                const lower = name.toLowerCase();
                if (lower.includes('tailscale') || lower.includes('tun') || lower.includes('utun')) continue;

                candidates.push({
                    name,
                    address: addr.address,
                    netmask: addr.netmask
                });
            }
        }

        // Prefer common interface names
        const preferred = ['en0', 'eth0', 'Ethernet', 'Wi-Fi', 'wlan0'];
        for (const pref of preferred) {
            const match = candidates.find(c => c.name === pref || c.name.includes(pref));
            if (match) return match;
        }

        // Fallback to first candidate
        return candidates[0] || null;
    }

    // --- Get transmitter info for the UI ---
    getInfo() {
        const localNet = this.getLocalIP();

        if (!localNet) {
            return {
                available: false,
                message: 'Nenhuma interface de rede local detectada.'
            };
        }

        return {
            available: true,
            interfaceName: localNet.name,
            localIP: localNet.address,
            netmask: localNet.netmask,
            instructions: [
                'No seu Nintendo Switch:',
                '1. Vá em Configurações → Internet → Configurações da Internet',
                '2. Selecione sua rede Wi-Fi',
                '3. Alterar Configurações',
                `4. Gateway: ${localNet.address}`,
                '5. DNS: 1.1.1.1',
                '6. Salvar e Conectar'
            ]
        };
    }

    // --- Activate transmitter mode ---
    activate() {
        const info = this.getInfo();

        if (!info.available) {
            this._sendLog(info.message, 'error');
            return info;
        }

        this._sendLog(`Modo Transmissor ativado!`, 'success');
        this._sendLog(`Interface: ${info.interfaceName}`, 'info');
        this._sendLog(`IP Local: ${info.localIP}`, 'success');
        this._sendLog('---', 'info');

        for (const instruction of info.instructions) {
            this._sendLog(instruction, 'info');
        }

        this._sendStatus('server', 'active', `Bridge: ${info.localIP}`);

        return info;
    }
}

module.exports = TransmitterMode;
