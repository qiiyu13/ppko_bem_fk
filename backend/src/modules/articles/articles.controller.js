const articlesService = require('./articles.service');
const { success, error } = require('../../utils/response');

// Public
const getPublishedArticles = async (req, res, next) => {
  try {
    const articles = await articlesService.getPublishedArticles();
    return success(res, articles);
  } catch (err) {
    next(err);
  }
};

const getPublishedArticle = async (req, res, next) => {
  try {
    const article = await articlesService.getPublishedArticle(req.params.id);
    return success(res, article);
  } catch (err) {
    if (err.message === 'Article not found') return error(res, err.message, 404, 'NOT_FOUND');
    next(err);
  }
};

// Admin
const getAllArticles = async (req, res, next) => {
  try {
    const articles = await articlesService.getAllArticles();
    return success(res, articles);
  } catch (err) {
    next(err);
  }
};

const createArticle = async (req, res, next) => {
  try {
    const article = await articlesService.createArticle(req.body, req.user.id);
    return success(res, article, 'Article created successfully', 201);
  } catch (err) {
    next(err);
  }
};

const updateArticle = async (req, res, next) => {
  try {
    const article = await articlesService.updateArticle(req.params.id, req.body);
    return success(res, article, 'Article updated successfully');
  } catch (err) {
    if (err.code === 'P2025') return error(res, 'Article not found', 404, 'NOT_FOUND');
    next(err);
  }
};

const deleteArticle = async (req, res, next) => {
  try {
    const result = await articlesService.deleteArticle(req.params.id);
    return success(res, result);
  } catch (err) {
    if (err.code === 'P2025') return error(res, 'Article not found', 404, 'NOT_FOUND');
    next(err);
  }
};

const publishArticle = async (req, res, next) => {
  try {
    const article = await articlesService.publishArticle(req.params.id);
    return success(res, article, 'Article published successfully');
  } catch (err) {
    if (err.code === 'P2025') return error(res, 'Article not found', 404, 'NOT_FOUND');
    next(err);
  }
};

module.exports = {
  getPublishedArticles, getPublishedArticle,
  getAllArticles, createArticle, updateArticle, deleteArticle, publishArticle,
};
