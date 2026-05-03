const http = require('http');
const app = require('./app');
const config = require('./config');
const { initWebSocketServer } = require('./websocket');

const server = http.createServer(app);
initWebSocketServer(server);

server.listen(config.port, () => {
  console.log(`Server running on port ${config.port}`);
  console.log(`WebSocket available at ws://localhost:${config.port}/ws`);
});
