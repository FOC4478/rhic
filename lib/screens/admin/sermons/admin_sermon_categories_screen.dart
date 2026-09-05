import 'package:flutter/material.dart';

import '../../../repositories/sermon_repository.dart';

class AdminSermonCategoriesScreen
    extends StatefulWidget {
  const AdminSermonCategoriesScreen({
    super.key,
  });

  @override
  State<AdminSermonCategoriesScreen>
      createState() =>
          _AdminSermonCategoriesScreenState();
}

class _AdminSermonCategoriesScreenState
    extends State<AdminSermonCategoriesScreen> {
  static const Color primaryColor =
      Color(0xFF6B1FA2);

  static const Color darkPurple =
      Color(0xFF3D004D);

  final TextEditingController
      _categoryController =
      TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F6F9),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Sermon Categories',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: darkPurple,
          ),
        ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Category',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: () {
          _showCategoryForm();
        },
      ),

      body: StreamBuilder<
          List<String>>(
        stream: SermonRepository
            .instance
            .categoriesStream(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load categories.\n\n${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            );
          }

          final categories =
              (snapshot.data ?? [])
                  .where(
                    (category) =>
                        category != 'All',
                  )
                  .toList();

          if (categories.isEmpty) {
            return _buildEmpty();
          }

          return ListView.separated(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              20,
              16,
              100,
            ),
            itemCount:
                categories.length,
            separatorBuilder:
                (
              context,
              index,
            ) =>
                    const SizedBox(
              height: 10,
            ),
            itemBuilder:
                (
              context,
              index,
            ) {
              final category =
                  categories[index];

              return _buildCategoryCard(
                category,
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // CATEGORY CARD
  // ============================================================

  Widget _buildCategoryCard(
    String category,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.
            circular(16),
        border: Border.all(
          color: const Color(
            0xFFEDE3F0,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(
                0xFFF3EAF5,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.category_outlined,
              color: primaryColor,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w700,
                color: darkPurple,
              ),
            ),
          ),

          IconButton(
            tooltip: 'Edit',
            icon: const Icon(
              Icons.edit_outlined,
              color: primaryColor,
            ),
            onPressed: () {
              _showCategoryForm(
                category: category,
              );
            },
          ),

          IconButton(
            tooltip: 'Delete',
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
            onPressed: () {
              _confirmDelete(
                category,
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADD / EDIT
  // ============================================================

  void _showCategoryForm({
    String? category,
  }) {
    final isEditing =
        category != null;

    _categoryController.text =
        category ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isEditing
                ? 'Edit Category'
                : 'Add Category',
          ),

          content: TextField(
            controller:
                _categoryController,
            autofocus: true,
            textCapitalization:
                TextCapitalization.words,
            decoration:
                InputDecoration(
              labelText: 'Category name',
              hintText:
                  'e.g. Faith, Prayer, Leadership',
              filled: true,
              fillColor:
                  const Color(0xFFF7F3F8),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primaryColor,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () async {
                final name =
                    _categoryController
                        .text
                        .trim();

                if (name.isEmpty) {
                  return;
                }

                try {
                  if (isEditing) {
                    await _updateCategoryByName(
                      oldName: category,
                      newName: name,
                    );
                  } else {
                    await SermonRepository
                        .instance
                        .createCategory(
                      name,
                    );
                  }

                  if (!dialogContext
                      .mounted) {
                    return;
                  }
                  Navigator.pop(
                    dialogContext,
                  );

                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? 'Category updated.'
                            : 'Category created.',
                      ),
                      behavior:
                          SnackBarBehavior
                              .floating,
                    ),
                  );
                } catch (e) {
                  if (!dialogContext
                      .mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Unable to save category: $e',
                      ),
                    ),
                  );
                }
              },
              child: Text(
                isEditing
                    ? 'Save'
                    : 'Create',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // FIND CATEGORY ID AND UPDATE
  // ============================================================

  Future<void> _updateCategoryByName({
    required String oldName,
    required String newName,
  }) async {
    final firestore =
        SermonRepository.instance;

    final snapshot =
        await firestore
            .categoriesCollection
            .where(
              'name',
              isEqualTo: oldName,
            )
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      throw Exception(
        'Category not found.',
      );
    }

    await firestore.updateCategory(
      categoryId:
          snapshot.docs.first.id,
      name: newName,
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  void _confirmDelete(
    String category,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Category?',
          ),
          content: Text(
            'Are you sure you want to delete "$category"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                try {
                  final repository =
                      SermonRepository
                          .instance;

                  final snapshot =
                      await repository
                          .categoriesCollection
                          .where(
                            'name',
                            isEqualTo:
                                category,
                          )
                          .limit(1)
                          .get();

                  if (snapshot
                      .docs
                      .isEmpty) {
                    throw Exception(
                      'Category not found.',
                    );
                  }

                  await repository
                      .deleteCategory(
                    snapshot
                        .docs
                        .
                        first
                        .id,
                  );

                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Category deleted.',
                      ),
                      behavior:
                          SnackBarBehavior
                              .floating,
                    ),
                  );
                } catch (e) {
                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Unable to delete category: $e',
                      ),
                      behavior:
                          SnackBarBehavior
                              .floating,
                    ),
                  );
                }
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.category_outlined,
              size: 65,
              color: Color(0xFFD5D5D5),
            ),

            const SizedBox(height: 18),

            const Text(
              'No categories yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w700,
                color: Color(0xFF777777),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Create categories to organize your sermons.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade500,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                _showCategoryForm();
              },
              icon:
                  const Icon(Icons.add),
              label: const Text(
                'Add Category',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primaryColor,
                foregroundColor:
                    Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}