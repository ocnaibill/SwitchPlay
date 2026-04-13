// ========================================
// SwitchPlay — Npcap Detector
// Checks for Npcap on Windows and launches
// the silent installer if not present.
// ========================================

const { execSync, spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

class NpcapDetector {
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

    // --- Check if Npcap is installed ---
    isInstalled() {
        if (os.platform() !== 'win32') {
            // On macOS/Linux, libpcap is available by default
            return true;
        }

        const npcapPaths = [
            'C:\\Program Files\\Npcap',
            'C:\\Program Files (x86)\\Npcap'
        ];

        for (const p of npcapPaths) {
            if (fs.existsSync(p)) {
                this._sendLog('Npcap detectado.', 'success');
                return true;
            }
        }

        // Also check via registry
        try {
            execSync('reg query "HKLM\\SOFTWARE\\Npcap" /ve', { stdio: 'pipe' });
            this._sendLog('Npcap detectado via registro.', 'success');
            return true;
        } catch {
            // Not found
        }

        return false;
    }

    // --- Install Npcap silently ---
    async install() {
        if (os.platform() !== 'win32') {
            this._sendLog('Npcap não é necessário neste SO.', 'info');
            return true;
        }

        const installerPath = path.join(__dirname, '..', 'bin', 'npcap-installer.exe');

        if (!fs.existsSync(installerPath)) {
            this._sendLog('Instalador do Npcap não encontrado em bin/npcap-installer.exe', 'error');
            return false;
        }

        return new Promise((resolve) => {
            this._sendLog('Instalando Npcap silenciosamente...', 'warning');

            // /S = silent, /winpcap_mode = WinPcap compatibility
            const installer = spawn(installerPath, ['/S', '/winpcap_mode=yes'], {
                stdio: 'pipe'
            });

            installer.on('close', (code) => {
                if (code === 0) {
                    this._sendLog('Npcap instalado com sucesso!', 'success');
                    resolve(true);
                } else {
                    this._sendLog(`Falha na instalação do Npcap (código: ${code})`, 'error');
                    resolve(false);
                }
            });

            installer.on('error', (err) => {
                this._sendLog(`Erro ao lançar instalador: ${err.message}`, 'error');
                resolve(false);
            });
        });
    }

    // --- Check and install if needed ---
    async ensure() {
        if (this.isInstalled()) {
            return true;
        }

        this._sendLog('Npcap não detectado. Tentando instalar...', 'warning');
        return await this.install();
    }
}

module.exports = NpcapDetector;
