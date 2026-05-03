const { broadcastToUsers, broadcastToAll, events } = require('../../websocket');

const prisma = require('../../utils/prisma');

// Public
const getPublishedArticles = async () => {
  return prisma.article.findMany({
    where: { isPublished: true, isDraft: false },
    orderBy: { publishDate: 'desc' },
    select: { id: true, title: true, content: true, imagePath: true, tags: true, publishDate: true, author: { select: { responsibleName: true } } },
  });
};

const getPublishedArticle = async (id) => {
  const article = await prisma.article.findFirst({
    where: { id, isPublished: true, isDraft: false },
    select: { id: true, title: true, content: true, imagePath: true, tags: true, publishDate: true, createdAt: true, author: { select: { responsibleName: true } } },
  });
  if (!article) throw Object.assign(new Error('Article not found'), { statusCode: 404 });
  return article;
};

// Admin
const getAllArticles = async () => {
  return prisma.article.findMany({
    orderBy: { createdAt: 'desc' },
    include: { author: { select: { responsibleName: true } } },
  });
};

const createArticle = async (data, authorId) => {
  const isDraft = data.isDraft !== undefined ? data.isDraft : true;
  const isPublished = data.isPublished !== undefined ? data.isPublished : false;

  const result = await prisma.article.create({
    data: {
      authorId,
      title: data.title,
      content: data.content,
      imagePath: data.imagePath || null,
      tags: data.tags || [],
      isPublished,
      isDraft,
      publishDate: isPublished ? new Date() : null,
    },
  });
  try { broadcastToAll(events.DATA_UPDATE, { type: 'articles', action: 'create', id: result.id }); } catch (e) { console.error('WebSocket broadcast failed:', e.message); }
  return result;
};

const updateArticle = async (id, data) => {
  const updateData = {};
  if (data.title !== undefined) updateData.title = data.title;
  if (data.content !== undefined) updateData.content = data.content;
  if (data.imagePath !== undefined) updateData.imagePath = data.imagePath || null;
  if (data.tags !== undefined) updateData.tags = data.tags;
  if (data.isDraft !== undefined) updateData.isDraft = data.isDraft;
  if (data.isPublished !== undefined) updateData.isPublished = data.isPublished;

  const result = await prisma.article.update({
    where: { id },
    data: updateData,
  });
  try { broadcastToAll(events.DATA_UPDATE, { type: 'articles', action: 'update', id }); } catch (e) { console.error('WebSocket broadcast failed:', e.message); }
  return result;
};

const deleteArticle = async (id) => {
  await prisma.article.delete({ where: { id } });
  try { broadcastToAll(events.DATA_UPDATE, { type: 'articles', action: 'delete', id }); } catch (e) { console.error('WebSocket broadcast failed:', e.message); }
  return { message: 'Article deleted successfully' };
};

const publishArticle = async (id) => {
  const result = await prisma.article.update({
    where: { id },
    data: { isPublished: true, isDraft: false, publishDate: new Date() },
  });
  try { broadcastToAll(events.DATA_UPDATE, { type: 'articles', action: 'publish', id }); } catch (e) { console.error('WebSocket broadcast failed:', e.message); }
  return result;
};

module.exports = {
  getPublishedArticles, getPublishedArticle,
  getAllArticles, createArticle, updateArticle, deleteArticle, publishArticle,
};
