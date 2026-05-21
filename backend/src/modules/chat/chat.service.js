const prisma = require('../../utils/prisma');
const { parsePagination } = require('../../utils/pagination');

const getConversations = async (userId, query) => {
  const { page, limit, skip } = parsePagination(query);
  const where = { userId };
  const [data, total] = await Promise.all([
    prisma.chatConversation.findMany({
      where, skip, take: limit,
      orderBy: { lastActivityAt: 'desc' },
      include: {
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          select: { content: true, role: true, createdAt: true },
        },
      },
    }),
    prisma.chatConversation.count({ where }),
  ]);
  return { data, total, page, limit };
};

const createConversation = async (userId) => {
  return prisma.chatConversation.create({
    data: { userId },
  });
};

const getMessages = async (conversationId, userId, query = {}) => {
  const conversation = await prisma.chatConversation.findFirst({
    where: { id: conversationId, userId },
  });
  if (!conversation) throw Object.assign(new Error('Conversation not found'), { statusCode: 404 });

  const where = { conversationId };

  if (query.page !== undefined || query.limit !== undefined) {
    const { page, limit, skip } = parsePagination(query);
    const [data, total] = await Promise.all([
      prisma.chatMessage.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.chatMessage.count({ where }),
    ]);
    return { data: data.reverse(), total, page, limit };
  }

  const messages = await prisma.chatMessage.findMany({
    where,
    orderBy: { createdAt: 'desc' },
    take: 200,
  });
  return messages.reverse();
};

const sendMessage = async (conversationId, content, userId) => {
  const conversation = await prisma.chatConversation.findFirst({
    where: { id: conversationId, userId },
  });
  if (!conversation) throw Object.assign(new Error('Conversation not found'), { statusCode: 404 });

  return prisma.chatMessage.create({
    data: {
      conversationId,
      content,
      role: 'user',
    },
  });
};

const deleteConversation = async (id, userId) => {
  const conversation = await prisma.chatConversation.findFirst({
    where: { id, userId },
  });
  if (!conversation) throw Object.assign(new Error('Conversation not found'), { statusCode: 404 });

  // Delete messages first
  await prisma.chatMessage.deleteMany({ where: { conversationId: id } });
  await prisma.chatConversation.delete({ where: { id } });
  return { message: 'Conversation deleted successfully' };
};

module.exports = { getConversations, createConversation, getMessages, sendMessage, deleteConversation };
