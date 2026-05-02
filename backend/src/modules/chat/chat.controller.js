const chatService = require('./chat.service');
const { success, error } = require('../../utils/response');

const getConversations = async (req, res, next) => {
  try {
    const conversations = await chatService.getConversations(req.user.id);
    return success(res, conversations);
  } catch (err) {
    next(err);
  }
};

const createConversation = async (req, res, next) => {
  try {
    const conversation = await chatService.createConversation(req.user.id);
    return success(res, conversation, 'Conversation created successfully', 201);
  } catch (err) {
    next(err);
  }
};

const getMessages = async (req, res, next) => {
  try {
    const messages = await chatService.getMessages(req.params.id, req.user.id);
    return success(res, messages);
  } catch (err) {
    if (err.message === 'Conversation not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

const sendMessage = async (req, res, next) => {
  try {
    const message = await chatService.sendMessage(req.params.id, req.body.content, req.body.role, req.user.id);
    return success(res, message, 'Message sent successfully', 201);
  } catch (err) {
    if (err.message === 'Conversation not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

const deleteConversation = async (req, res, next) => {
  try {
    const result = await chatService.deleteConversation(req.params.id, req.user.id);
    return success(res, result);
  } catch (err) {
    if (err.message === 'Conversation not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

module.exports = { getConversations, createConversation, getMessages, sendMessage, deleteConversation };
