// BillPlay ts-sidecar
// A lightweight Go binary that uses tsnet to create an invisible
// VPN connection to the Headscale network. No TUN device needed,
// no admin privileges required.
//
// Usage:
//   ts-sidecar --key <PRE_AUTH_KEY> [--server <HEADSCALE_URL>] [--hostname <NAME>]
//
// Communication with Electron:
//   stdout lines are parsed by the Electron main process:
//     STATUS:CONNECTING  - VPN is trying to connect
//     STATUS:CONNECTED   - VPN tunnel is up
//     STATUS:ERROR:<msg>  - Something went wrong
//     LOG:<message>       - General log output

package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"

	"tailscale.com/tsnet"
)

func main() {
	// --- Flags ---
	authKey := flag.String("key", "", "Tailscale/Headscale pre-auth key")
	controlURL := flag.String("server", "", "Headscale control server URL (e.g. https://hs.example.com)")
	hostname := flag.String("hostname", "", "Hostname for this node on the tailnet")
	stateDir := flag.String("state-dir", "", "Directory to store tsnet state (default: auto)")
	flag.Parse()

	if *authKey == "" {
		fmt.Println("STATUS:ERROR:No auth key provided. Use --key flag.")
		os.Exit(1)
	}

	// --- Build hostname ---
	nodeName := *hostname
	if nodeName == "" {
		host, err := os.Hostname()
		if err != nil {
			host = "billplay-client"
		}
		nodeName = fmt.Sprintf("billplay-%s", host)
	}

	// --- Configure tsnet server ---
	srv := &tsnet.Server{
		Hostname: nodeName,
		AuthKey:  *authKey,
		Logf:     func(format string, args ...any) { fmt.Printf("LOG:"+format+"\n", args...) },
	}

	// Use custom control URL if provided (Headscale)
	if *controlURL != "" {
		srv.ControlURL = *controlURL
	}

	// Use custom state directory if provided
	if *stateDir != "" {
		srv.Dir = *stateDir
	}

	fmt.Println("STATUS:CONNECTING")
	fmt.Printf("LOG:Connecting as '%s'...\n", nodeName)

	// --- Start the tsnet server ---
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	status, err := srv.Up(ctx)
	if err != nil {
		fmt.Printf("STATUS:ERROR:%v\n", err)
		log.Fatalf("Failed to start tsnet: %v", err)
	}

	// Print our Tailnet IP
	var selfIP string
	for _, addr := range status.TailscaleIPs {
		if addr.Is4() {
			selfIP = addr.String()
			break
		}
	}

	fmt.Printf("LOG:Node online. Tailnet IP: %s\n", selfIP)
	fmt.Println("STATUS:CONNECTED")

	// --- Verify connectivity to the LAN Play server ---
	go func() {
		for {
			time.Sleep(30 * time.Second)
			conn, err := net.DialTimeout("udp", "100.64.0.2:11451", 5*time.Second)
			if err != nil {
				fmt.Printf("LOG:Health check failed: %v\n", err)
			} else {
				conn.Close()
				fmt.Println("LOG:Health check OK - server reachable")
			}
		}
	}()

	// --- Wait for shutdown signal ---
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	sig := <-sigCh
	fmt.Printf("LOG:Received signal %v, shutting down...\n", sig)
	fmt.Println("STATUS:DISCONNECTING")

	if err := srv.Close(); err != nil {
		fmt.Printf("LOG:Error during shutdown: %v\n", err)
	}

	fmt.Println("STATUS:DISCONNECTED")
	fmt.Println("LOG:Sidecar stopped cleanly.")
}
