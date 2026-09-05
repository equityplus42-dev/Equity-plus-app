const prisma = require('../config/database');

const DEFAULT_CATEGORIES = [
  { name: 'Time Management', description: 'Strategies and techniques for effective time allocation and productivity', orderIndex: 1 },
  { name: 'Habit Building', description: 'Forming positive daily habits and routines for personal growth', orderIndex: 2 },
  { name: 'Communication Skills', description: 'Public speaking, interpersonal influence, and clear messaging', orderIndex: 3 },
  { name: 'Social Media Influence', description: 'Building online presence, personal branding, and audience growth', orderIndex: 4 },
  { name: 'Mental Health & Mindset', description: 'Stress management, mental wellness, resilience, and emotional intelligence', orderIndex: 5 },
  { name: 'Personal Finance', description: 'Budgeting, wealth creation, debt management, and financial planning', orderIndex: 6 },
  { name: 'Multiple Streams of Income', description: 'Diversifying income, passive revenue, and entrepreneurial ventures', orderIndex: 7 },
  { name: 'Parenting & Family', description: 'Nurturing family relationships and positive parenting approaches', orderIndex: 8 },
  { name: 'Bhagavad Gita Wisdom', description: 'Timeless spiritual philosophy and life principles from the Bhagavad Gita', orderIndex: 9 },
];

class CategoryService {
  /**
   * Seed default 9 English categories if table is empty
   */
  async seedDefaultCategoriesIfEmpty() {
    const count = await prisma.category.count();
    if (count === 0) {
      for (const cat of DEFAULT_CATEGORIES) {
        await prisma.category.upsert({
          where: { name: cat.name },
          update: {},
          create: cat,
        });
      }
    }
  }

  /**
   * Get all active categories ordered by orderIndex
   */
  async getAllCategories() {
    await this.seedDefaultCategoriesIfEmpty();
    const categories = await prisma.category.findMany({
      orderBy: [{ orderIndex: 'asc' }, { name: 'asc' }],
      include: {
        _count: {
          select: { videos: true },
        },
      },
    });

    return categories.map((cat) => ({
      id: cat.id,
      name: cat.name,
      description: cat.description,
      orderIndex: cat.orderIndex,
      videoCount: cat._count.videos,
      createdAt: cat.createdAt,
    }));
  }

  /**
   * Create a new category
   */
  async createCategory({ name, description, orderIndex }) {
    if (!name || name.trim().length === 0) {
      throw new Error('Category name is required');
    }

    const trimmedName = name.trim();
    const existing = await prisma.category.findUnique({
      where: { name: trimmedName },
    });

    if (existing) {
      throw new Error(`Category "${trimmedName}" already exists`);
    }

    const maxOrder = await prisma.category.aggregate({
      _max: { orderIndex: true },
    });

    const nextOrder = orderIndex !== undefined ? parseInt(orderIndex, 10) : (maxOrder._max.orderIndex || 0) + 1;

    return prisma.category.create({
      data: {
        name: trimmedName,
        description: description ? description.trim() : null,
        orderIndex: nextOrder,
      },
    });
  }

  /**
   * Delete a category by ID
   */
  async deleteCategory(id) {
    const category = await prisma.category.findUnique({
      where: { id },
      include: { _count: { select: { videos: true } } },
    });

    if (!category) {
      throw new Error('Category not found');
    }

    // Unlink videos attached to this category
    await prisma.video.updateMany({
      where: { categoryId: id },
      data: { categoryId: null, categoryName: null },
    });

    await prisma.category.delete({
      where: { id },
    });

    return { message: `Category "${category.name}" deleted successfully` };
  }
}

module.exports = new CategoryService();
