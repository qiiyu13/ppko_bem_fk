const prisma = require('../../utils/prisma');
const { sendToUser } = require('../../utils/fcm');

const registerToken = async (userId, fcmToken) => {
  await prisma.user.update({
    where: { id: userId },
    data: { fcmToken },
  });
  return { registered: true };
};

const getNotifications = async (userId) => {
  return prisma.notification.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
    take: 100,
  });
};

const markAllRead = async (userId) => {
  await prisma.notification.updateMany({
    where: { userId, isRead: false },
    data: { isRead: true },
  });
  return { updated: true };
};

const markRead = async (id, userId) => {
  const notif = await prisma.notification.findFirst({ where: { id, userId } });
  if (!notif) throw Object.assign(new Error('Notification not found'), { statusCode: 404 });
  await prisma.notification.update({ where: { id }, data: { isRead: true } });
  return { updated: true };
};

const createAndSend = async (userId, { title, body, type, data = {} }) => {
  const notif = await prisma.notification.create({
    data: { userId, title, body, type, data },
  });
  try {
    await sendToUser(userId, { title, body, data: { type, notificationId: notif.id, ...data } });
  } catch (e) {
    console.error('FCM send failed:', e.message);
  }
  return notif;
};

module.exports = { registerToken, getNotifications, markAllRead, markRead, createAndSend };
