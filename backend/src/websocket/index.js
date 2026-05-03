const { WebSocketServer } = require('ws');
const { verifyToken } = require('../utils/jwt');
const events = require('./events');

let wss;
const clients = new Map();

function initWebSocketServer(server) {
  wss = new WebSocketServer({ server, path: '/ws' });

  wss.on('connection', (ws, req) => {
    let userId = null;
    let userRole = null;

    ws.isAlive = true;
    ws.on('pong', () => { ws.isAlive = true; });

    ws.on('message', (data) => {
      try {
        const message = JSON.parse(data.toString());
        const { handleChatMessage } = require('./chat.handler');
        switch (message.event) {
          case events.CHAT_MESSAGE:
            if (userId) handleChatMessage(ws, message.data, userId);
            break;
          default:
            break;
        }
      } catch (e) {
        // ignore malformed messages
      }
    });

    ws.on('close', () => {
      if (userId && clients.has(userId)) {
        clients.get(userId).delete(ws);
        if (clients.get(userId).size === 0) clients.delete(userId);
      }
    });

    // Auto-authenticate from query token
    try {
      const url = new URL(req.url, 'http://localhost');
      const token = url.searchParams.get('token');
      if (token) {
        const decoded = verifyToken(token);
        userId = decoded.userId;
        userRole = decoded.role;
        if (!clients.has(userId)) clients.set(userId, new Set());
        clients.get(userId).add(ws);
        ws.send(JSON.stringify({ event: events.AUTHENTICATED, data: { userId, role: userRole } }));
      }
    } catch (e) {
      ws.send(JSON.stringify({ event: events.ERROR, data: { message: 'Authentication failed' } }));
    }
  });

  // Heartbeat to detect dead connections
  setInterval(() => {
    wss.clients.forEach((ws) => {
      if (!ws.isAlive) return ws.terminate();
      ws.isAlive = false;
      ws.ping();
    });
  }, 30000);

  return wss;
}

function broadcastToUsers(userIds, event, data) {
  const payload = JSON.stringify({ event, data });
  userIds.forEach((uid) => {
    const userClients = clients.get(uid);
    if (userClients) {
      userClients.forEach((ws) => {
        if (ws.readyState === 1) ws.send(payload);
      });
    }
  });
}

function broadcastToAll(event, data) {
  const payload = JSON.stringify({ event, data });
  wss?.clients.forEach((ws) => {
    if (ws.readyState === 1) ws.send(payload);
  });
}

module.exports = { initWebSocketServer, broadcastToUsers, broadcastToAll, events };
