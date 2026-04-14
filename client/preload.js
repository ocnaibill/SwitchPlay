const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("switchplay", {
  // Platform info
  platform: process.platform,

  // Window controls
  minimize: () => ipcRenderer.send("window-minimize"),
  maximize: () => ipcRenderer.send("window-maximize"),
  close: () => ipcRenderer.send("window-close"),

  // Status updates from main process
  onStatusUpdate: (callback) => {
    ipcRenderer.on("status-update", (_event, data) => callback(data));
  },

  // Connection controls
  connect: (config) => ipcRenderer.invoke("connect", config),
  disconnect: () => ipcRenderer.invoke("disconnect"),

  // Transmitter mode
  getTransmitterInfo: () => ipcRenderer.invoke("get-transmitter-info"),

  // Process logs
  onLog: (callback) => {
    ipcRenderer.on("log", (_event, data) => callback(data));
  },
});
