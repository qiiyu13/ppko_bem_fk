const { admin } = require('./firebase');
const prisma = require('./prisma');

function buildMessage(token, { title, body, data = {} }) {
  return {
    token,
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    ),
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default' } } },
  };
}

async function clearInvalidToken(err, userId) {
  if (
    err.code === 'messaging/registration-token-not-registered' ||
    err.code === 'messaging/invalid-registration-token'
  ) {
    await prisma.user.update({
      where: { id: userId },
      data: { fcmToken: null },
    });
  }
}

async function sendToUser(userId, payload) {
  if (!admin.apps.length) return;

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { fcmToken: true },
  });

  if (!user?.fcmToken) return;

  try {
    await admin.messaging().send(buildMessage(user.fcmToken, payload));
  } catch (err) {
    await clearInvalidToken(err, userId);
  }
}

const FCM_MULTICAST_LIMIT = 500; // FCM hard cap per multicast request

function buildMulticastMessage(tokens, { title, body, data = {} }) {
  return {
    tokens,
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    ),
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default' } } },
  };
}

async function sendToUsers(userIds, payload) {
  if (!admin.apps.length || !userIds.length) return;

  const users = await prisma.user.findMany({
    where: { id: { in: userIds }, fcmToken: { not: null } },
    select: { id: true, fcmToken: true },
  });
  if (!users.length) return;

  // Batch into multicast requests (≤500 tokens each) instead of one HTTP
  // round-trip per token. Clear tokens that FCM reports as unregistered.
  for (let i = 0; i < users.length; i += FCM_MULTICAST_LIMIT) {
    const batch = users.slice(i, i + FCM_MULTICAST_LIMIT);
    const tokens = batch.map((u) => u.fcmToken);
    try {
      const res = await admin.messaging().sendEachForMulticast(
        buildMulticastMessage(tokens, payload)
      );
      await Promise.all(
        res.responses.map((r, idx) =>
          r.success ? null : clearInvalidToken(r.error, batch[idx].id)
        )
      );
    } catch (err) {
      console.error('FCM multicast send failed:', err.message);
    }
  }
}

module.exports = { sendToUser, sendToUsers };
