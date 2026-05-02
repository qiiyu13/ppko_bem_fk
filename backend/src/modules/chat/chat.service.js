const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const getConversations = async (userId) => {
  return prisma.chatConversation.findMany({
    where: { userId },
    orderBy: { lastActivityAt: 'desc' },
    include: {
      messages: {
        orderBy: { createdAt: 'desc' },
        take: 1,
        select: { content: true, role: true, createdAt: true },
      },
    },
  });
};

const createConversation = async (userId) => {
  return prisma.chatConversation.create({
    data: { userId },
  });
};

const getMessages = async (conversationId, userId) => {
  const conversation = await prisma.chatConversation.findFirst({
    where: { id: conversationId, userId },
  });
  if (!conversation) throw Object.assign(new Error('Conversation not found'), { statusCode: 404 });

  return prisma.chatMessage.findMany({
    where: { conversationId },
    orderBy: { createdAt: 'asc' },
  });
};

const sendMessage = async (conversationId, content, role, userId) => {
  const conversation = await prisma.chatConversation.findFirst({
    where: { id: conversationId, userId },
  });
  if (!conversation) throw Object.assign(new Error('Conversation not found'), { statusCode: 404 });

  return prisma.chatMessage.create({
    data: {
      conversationId,
      content,
      role: role || 'user',
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
