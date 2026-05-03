const { PrismaClient } = require('@prisma/client');
const events = require('./events');

const prisma = new PrismaClient();

async function handleChatMessage(ws, data, userId) {
  const { conversationId, content } = data;

  if (!conversationId || !content) {
    ws.send(JSON.stringify({ event: events.ERROR, data: { message: 'conversationId and content required' } }));
    return;
  }

  const conversation = await prisma.chatConversation.findFirst({
    where: { id: conversationId, userId },
  });
  if (!conversation) {
    ws.send(JSON.stringify({ event: events.ERROR, data: { message: 'Conversation not found' } }));
    return;
  }

  // Save user message
  const userMessage = await prisma.chatMessage.create({
    data: { conversationId, content, role: 'user' },
  });

  // Confirm user message
  ws.send(JSON.stringify({
    event: events.CHAT_MESSAGE_NEW,
    data: {
      conversationId,
      message: {
        id: userMessage.id,
        content: userMessage.content,
        role: 'user',
        createdAt: userMessage.createdAt.toISOString(),
      },
    },
  }));

  // Generate AI response
  const aiContent = `Terima kasih atas pertanyaan Anda. Saya mencatat: "${content}". Fitur AI akan segera tersedia.`;

  const assistantMessage = await prisma.chatMessage.create({
    data: { conversationId, content: aiContent, role: 'assistant' },
  });

  await prisma.chatConversation.update({
    where: { id: conversationId },
    data: { lastActivityAt: new Date() },
  });

  // Send AI response
  ws.send(JSON.stringify({
    event: events.CHAT_MESSAGE_NEW,
    data: {
      conversationId,
      message: {
        id: assistantMessage.id,
        content: assistantMessage.content,
        role: 'assistant',
        createdAt: assistantMessage.createdAt.toISOString(),
      },
    },
  }));
}

module.exports = { handleChatMessage };
