const prisma = require('../../utils/prisma');
const { sendToUser, sendToUsers } = require('../../utils/fcm');
const { parsePagination } = require('../../utils/pagination');

const registerToken = async (userId, fcmToken) => {
  await prisma.user.update({
    where: { id: userId },
    data: { fcmToken },
  });
  return { registered: true };
};

const getNotifications = async (userId, query = {}) => {
  const where = { userId };

  if (query.page !== undefined || query.limit !== undefined) {
    const { page, limit, skip } = parsePagination(query);
    const [data, total] = await Promise.all([
      prisma.notification.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.notification.count({ where }),
    ]);
    return { data, total, page, limit };
  }

  return prisma.notification.findMany({
    where,
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

const deleteAll = async (userId) => {
  await prisma.notification.deleteMany({
    where: { userId },
  });
  return { deleted: true };
};

const markRead = async (id, userId) => {
  // Single scoped write — ownership enforced via the userId filter.
  const { count } = await prisma.notification.updateMany({
    where: { id, userId },
    data: { isRead: true },
  });
  if (count === 0) throw Object.assign(new Error('Notification not found'), { statusCode: 404 });
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

const createAndSendToAllPatients = async ({ title, body, type, data = {} }) => {
  const users = await prisma.user.findMany({
    where: { role: 'PATIENT', isActive: true },
    select: { id: true },
  });
  if (!users.length) return [];

  await prisma.notification.createMany({
    data: users.map((u) => ({ userId: u.id, title, body, type, data })),
  });

  try {
    await sendToUsers(users.map((u) => u.id), {
      title,
      body,
      data: { type, ...data },
    });
  } catch (e) {
    console.error('FCM bulk send failed:', e.message);
  }

  return users.map((u) => u.id);
};

module.exports = { registerToken, getNotifications, markAllRead, markRead, deleteAll, createAndSend, createAndSendToAllPatients };
