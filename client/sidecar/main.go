// SwitchPlay ts-sidecar
// VPN invisível usando tsnet (Tailscale nativo em Go).
// Conecta automaticamente ao Headscale sem instalar cliente VPN no SO.
// Sem placa de rede virtual, sem permissões de admin.
//
// Protocolo stdout (lido pelo Electron main process):
//   [VPN_CONNECTING]            → Tentando conectar
//   [VPN_CONNECTED] <ip>        → Túnel ativo, IP recebido
//   [VPN_ERROR] <mensagem>      → Algo correu mal
//   [VPN_DISCONNECTED]          → Sidecar encerrado
//   [LOG] <mensagem>            → Log genérico

package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"path/filepath"
	"runtime"
	"syscall"
	"time"

	"tailscale.com/tsnet"
)

// ==========================================
// Runtime variables — injected via flags
// ==========================================
var (
        // URL do servidor Headscale (Control Server)
        controlURL string

        // Pre-Auth Key reutilizável do Headscale
        authKey string

        // IP do servidor LAN Play na tailnet (para health checks)
        lanPlayServer string

        // Version metadata
        Version = "dev"
)

// getStateDir retorna o caminho para armazenar o estado do tsnet.
// Windows: %APPDATA%\SwitchPlay\vpn-state
// macOS:   ~/Library/Application Support/SwitchPlay/vpn-state
// Linux:   ~/.config/switchplay/vpn-state
func getStateDir() string {
	var baseDir string

	switch runtime.GOOS {
	case "windows":
		baseDir = os.Getenv("APPDATA")
		if baseDir == "" {
			baseDir = filepath.Join(os.Getenv("USERPROFILE"), "AppData", "Roaming")
		}
		return filepath.Join(baseDir, "SwitchPlay", "vpn-state")

	case "darwin":
		home, _ := os.UserHomeDir()
		return filepath.Join(home, "Library", "Application Support", "SwitchPlay", "vpn-state")

	default: // linux e outros
		configDir := os.Getenv("XDG_CONFIG_HOME")
		if configDir == "" {
			home, _ := os.UserHomeDir()
			configDir = filepath.Join(home, ".config")
		}
		return filepath.Join(configDir, "switchplay", "vpn-state")
	}
}

func main() {
        flag.StringVar(&authKey, "auth-key", "", "Control Server Auth Key")
        flag.StringVar(&controlURL, "control-url", "", "Control Server URL")
        flag.StringVar(&lanPlayServer, "lan-play-server", "100.64.0.2:11451", "LAN Play server IP:PORT on Tailnet")
        flag.Parse()

        // --- Validar variáveis injectadas ---
        if authKey == "" {
                fmt.Println("[VPN_ERROR] Auth key not set. Please provide it via -auth-key flag.")
                os.Exit(1)
        }
        if controlURL == "" {
                fmt.Println("[VPN_ERROR] Control URL not set. Please provide it via -control-url flag.")
	}

	// --- Gerar hostname único para este nó ---
	host, err := os.Hostname()
	if err != nil {
		host = "switchplay-client"
	}
	nodeName := fmt.Sprintf("switchplay-%s", host)

	// --- Diretório de estado persistente ---
	stateDir := getStateDir()
	if err := os.MkdirAll(stateDir, 0700); err != nil {
		fmt.Printf("[VPN_ERROR] Falha ao criar diretório de estado: %v\n", err)
		os.Exit(1)
	}

	// --- Forçar login com auth key ---
	// Sem isto, se o tsnet encontrar estado anterior (mesmo falhado),
	// ele ignora a auth key e fica preso. Com TSNET_FORCE_LOGIN=1
	// ele usa sempre a chave injectada — zero intervenção do utilizador.
	os.Setenv("TSNET_FORCE_LOGIN", "1")

	// --- Configurar o servidor tsnet ---
	// tsnet abre sockets diretamente na Tailnet, sem criar
	// uma placa de rede virtual (TUN). Zero permissões de admin.
	srv := &tsnet.Server{
		Hostname:   nodeName,
		AuthKey:    authKey,
		ControlURL: controlURL,
		Dir:        stateDir,
		Logf:       func(format string, args ...any) { fmt.Printf("[LOG] "+format+"\n", args...) },
	}

	fmt.Println("[VPN_CONNECTING]")
	fmt.Printf("[LOG] SwitchPlay sidecar %s\n", Version)
	fmt.Printf("[LOG] Conectando como '%s' ao servidor %s...\n", nodeName, controlURL)
	fmt.Printf("[LOG] Estado armazenado em: %s\n", stateDir)

	// --- Iniciar o tsnet (bloqueante até conectar ou timeout) ---
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	status, err := srv.Up(ctx)
	if err != nil {
		fmt.Printf("[VPN_ERROR] %v\n", err)
		log.Fatalf("Falha ao iniciar tsnet: %v", err)
	}

	// --- Extrair o IP 100.64.x.x atribuído ---
	var selfIP string
	for _, addr := range status.TailscaleIPs {
		if addr.Is4() {
			selfIP = addr.String()
			break
		}
	}

	// Esta é a linha que o Electron procura para saber que a VPN está ativa
	fmt.Printf("[VPN_CONNECTED] %s\n", selfIP)
	fmt.Printf("[LOG] Nó online na Tailnet. IP: %s\n", selfIP)

	// --- Health check periódico ao servidor LAN Play ---
	go func() {
		for {
			time.Sleep(30 * time.Second)
			conn, err := net.DialTimeout("udp", lanPlayServer, 5*time.Second)
			if err != nil {
				fmt.Printf("[LOG] Health check falhou: %v\n", err)
			} else {
				conn.Close()
				fmt.Printf("[LOG] Health check OK — %s acessível\n", lanPlayServer)
			}
		}
	}()

	// --- Aguardar sinal de encerramento (SIGINT/SIGTERM) ---
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	sig := <-sigCh
	fmt.Printf("[LOG] Sinal recebido: %v. Encerrando...\n", sig)

	if err := srv.Close(); err != nil {
		fmt.Printf("[LOG] Erro ao encerrar: %v\n", err)
	}

	fmt.Println("[VPN_DISCONNECTED]")
	fmt.Println("[LOG] Sidecar encerrado corretamente.")
}
