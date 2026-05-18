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

async function sendToUsers(userIds, payload) {
  if (!admin.apps.length || !userIds.length) return;

  const users = await prisma.user.findMany({
    where: { id: { in: userIds }, fcmToken: { not: null } },
    select: { id: true, fcmToken: true },
  });

  await Promise.all(
    users.map(async (u) => {
      try {
        await admin.messaging().send(buildMessage(u.fcmToken, payload));
      } catch (err) {
        await clearInvalidToken(err, u.id);
      }
    })
  );
}

module.exports = { sendToUser, sendToUsers };
