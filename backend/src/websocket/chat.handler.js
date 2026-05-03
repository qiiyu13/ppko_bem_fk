const prisma = require('../utils/prisma');
const OpenAI = require('openai');
const events = require('./events');

const openai = process.env.OPENAI_API_KEY
  ? new OpenAI({ apiKey: process.env.OPENAI_API_KEY })
  : null;

const SYSTEM_PROMPT = `Kamu adalah asisten kesehatan digital untuk Posyandu/Puskesmas di Indonesia. 
Namamu MediBot. Tugasmu adalah memberikan informasi kesehatan umum, tips pola hidup sehat, 
dan menjawab pertanyaan seputar kesehatan keluarga. 
Kamu BUKAN pengganti dokter. Selalu sarankan untuk berkonsultasi dengan tenaga medis profesional 
untuk diagnosis atau pengobatan. Jawab dalam Bahasa Indonesia yang mudah dipahami.`;

async function getChatHistory(conversationId, limit = 20) {
  const messages = await prisma.chatMessage.findMany({
    where: { conversationId },
    orderBy: { createdAt: 'desc' },
    take: limit,
  });
  return messages.reverse().map((m) => ({
    role: m.role === 'user' ? 'user' : 'assistant',
    content: m.content,
  }));
}

async function generateAIResponse(conversationId, userContent) {
  if (!openai) {
    return 'Maaf, fitur AI belum dikonfigurasi. Silakan hubungi admin untuk mengaktifkan asisten AI.';
  }

  try {
    const history = await getChatHistory(conversationId);
    const messages = [
      { role: 'system', content: SYSTEM_PROMPT },
      ...history,
      { role: 'user', content: userContent },
    ];

    const completion = await openai.chat.completions.create({
      model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
      messages,
      max_tokens: 500,
      temperature: 0.7,
    });

    return completion.choices[0].message.content;
  } catch (err) {
    console.error('OpenAI API error:', err.message);
    return 'Maaf, terjadi kesalahan saat menghubungi asisten AI. Silakan coba lagi nanti.';
  }
}

const MAX_CONTENT_LENGTH = 2000;

async function handleChatMessage(ws, data, userId) {
  try {
    const { conversationId, content } = data;

    if (!conversationId || !content) {
      ws.send(JSON.stringify({ event: events.ERROR, data: { message: 'conversationId and content required' } }));
      return;
    }

    if (typeof content !== 'string' || content.length > MAX_CONTENT_LENGTH) {
      ws.send(JSON.stringify({ event: events.ERROR, data: { message: `Content must be a string of ${MAX_CONTENT_LENGTH} characters or less` } }));
      return;
    }

    if (typeof conversationId !== 'string') {
      ws.send(JSON.stringify({ event: events.ERROR, data: { message: 'Invalid conversationId' } }));
      return;
    }

    const conversation = await prisma.chatConversation.findFirst({
      where: { id: conversationId, userId },
    });
    if (!conversation) {
      ws.send(JSON.stringify({ event: events.ERROR, data: { message: 'Conversation not found' } }));
      return;
    }

    const userMessage = await prisma.chatMessage.create({
      data: { conversationId, content: content.trim(), role: 'user' },
    });

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

    const aiContent = await generateAIResponse(conversationId, content.trim());

    const assistantMessage = await prisma.chatMessage.create({
      data: { conversationId, content: aiContent, role: 'assistant' },
    });

    await prisma.chatConversation.update({
      where: { id: conversationId },
      data: { lastActivityAt: new Date() },
    });

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
  } catch (err) {
    console.error('Chat handler error:', err);
    try {
      ws.send(JSON.stringify({ event: events.ERROR, data: { message: 'An error occurred processing your message' } }));
    } catch (sendErr) {
      // WebSocket may be closed
    }
  }
}

module.exports = { handleChatMessage };
