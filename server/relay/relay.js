const dgram = require("dgram");

const PORT = 11451;
const server = dgram.createSocket("udp4");

const activePeers = new Set();

server.on("message", (msg, rinfo) => {
  if (rinfo.address.startsWith("100.64.") && !activePeers.has(rinfo.address)) {
    activePeers.add(rinfo.address);
    console.log(
      `[+] Novo console/jogador registrado na rede: ${rinfo.address}`,
    );
  }

  console.log(`[>>] Pacote de descoberta de ${rinfo.address}:${rinfo.port}`);

  activePeers.forEach((peerIP) => {
    if (peerIP !== rinfo.address) {
      server.send(msg, 0, msg.length, PORT, peerIP, (err) => {
        if (err) {
          console.error(`[!] Erro ao retransmitir para ${peerIP}: ${err}`);
        }
      });
    }
  });
});

server.on("listening", () => {
  const address = server.address();
  console.log(` Relay Inteligente (Fan-out) rodando na porta ${address.port}`);
});

server.bind(PORT);
