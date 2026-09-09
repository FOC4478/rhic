import 'package:cloud_firestore/cloud_firestore.dart';
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

  final SermonRepository _repository =
      SermonRepository.instance;

  final TextEditingController
      _categoryController =
      TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            error
                ? Colors.red.shade700
                : null,
      ),
    );
  }

  // ============================================================
  // CHECK DUPLICATE CATEGORY
  // ============================================================

  Future<bool> _categoryExists(
    String name, {
    String? ignoreName,
  }) async {
    final snapshot =
        await _repository
            .categoriesCollection
            .get();

    final cleaned =
        name.trim().toLowerCase();

    final ignored =
        ignoreName
            ?.trim()
            .toLowerCase();

    return snapshot.docs.any(
      (doc) {
        final existing =
            doc.data()['name']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        if (ignored != null &&
            existing == ignored) {
          return false;
        }

        return existing == cleaned;
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F6F9),

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        surfaceTintColor:
            Colors.white,
        elevation: 0,

        leading: IconButton(
          icon:
              const Icon(
            Icons
                .arrow_back_ios_new_rounded,
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
            fontWeight:
                FontWeight.w800,
            color: darkPurple,
          ),
        ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor:
            primaryColor,
        foregroundColor:
            Colors.white,
        icon:
            const Icon(Icons.add),
        label:
            const Text(
          'Add Category',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),
        onPressed: () {
          _showCategoryForm();
        },
      ),

      body: StreamBuilder<
          List<String>>(
        stream:
            _repository
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
              child: Padding(
                padding:
                    const EdgeInsets
                        .all(24),
                child: Text(
                  'Unable to load categories.\n\n'
                  '${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          final categories =
              (snapshot.data ?? [])
                  .where(
                    (category) =>
                        category
                            .trim()
                            .isNotEmpty &&
                        category
                            .trim()
                            .toLowerCase() !=
                            'all',
                  )
                  .toList();

          if (categories.isEmpty) {
            return _buildEmpty();
          }

          return ListView.separated(
            padding:
                const EdgeInsets
                    .fromLTRB(
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
            itemBuilder: (
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
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
              const Color(0xFFEDE3F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration:
                const BoxDecoration(
              color:
                  Color(0xFFF3EAF5),
              shape:
                  BoxShape.circle,
            ),
            child:
                const Icon(
              Icons
                  .category_outlined,
              color:
                  primaryColor,
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child: Text(
              category,
              style:
                  const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w700,
                color:
                    darkPurple,
              ),
            ),
          ),

          IconButton(
            tooltip: 'Edit',
            icon:
                const Icon(
              Icons
                  .edit_outlined,
              color:
                  primaryColor,
            ),
            onPressed: () {
              _showCategoryForm(
                category:
                    category,
              );
            },
          ),

          IconButton(
            tooltip: 'Delete',
            icon:
                const Icon(
              Icons
                  .delete_outline,
              color:
                  Colors.red,
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
  // ADD / EDIT CATEGORY
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
      builder:
          (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? 'Edit Category'
                    : 'Add Category',
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  color:
                      darkPurple,
                ),
              ),

              content:
                  TextField(
                controller:
                    _categoryController,
                autofocus: true,
                enabled:
                    !saving,
                textCapitalization:
                    TextCapitalization
                        .words,
                decoration:
                    InputDecoration(
                  labelText:
                      'Category name',
                  hintText:
                      'e.g. Faith, Prayer, Leadership',
                  filled: true,
                  fillColor:
                      const Color(
                    0xFFF7F3F8,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed:
                      saving
                          ? null
                          : () {
                              Navigator.of(
                                dialogContext,
                              ).pop();
                            },
                  child:
                      const Text(
                    'Cancel',
                  ),
                ),

                ElevatedButton(
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        primaryColor,
                    foregroundColor:
                        Colors.white,
                  ),
                  onPressed:
                      saving
                          ? null
                          : () async {
                              final name =
                                  _categoryController
                                      .text
                                      .trim();

                              if (name
                                  .isEmpty) {
                                _showMessage(
                                  'Enter a category name.',
                                  error:
                                      true,
                                );
                                return;
                              }

                              if (name
                                      .toLowerCase() ==
                                  'all') {
                                _showMessage(
                                  '"All" is reserved and cannot be used.',
                                  error:
                                      true,
                                );
                                return;
                              }

                              setDialogState(
                                () {
                                  saving =
                                      true;
                                },
                              );

                              try {
                                final exists =
                                    await _categoryExists(
                                  name,
                                  ignoreName:
                                      category,
                                );

                                if (exists) {
                                  throw Exception(
                                    'A category with this name already exists.',
                                  );
                                }

                                if (isEditing) {
                                  await _renameCategory(
                                    oldName:
                                        category,
                                    newName:
                                        name,
                                  );
                                } else {
                                  await _repository
                                      .createCategory(
                                    name,
                                  );
                                }

                                if (!dialogContext
                                    .mounted) {
                                  return;
                                }

                                Navigator.of(
                                  dialogContext,
                                ).pop();

                                _showMessage(
                                  isEditing
                                      ? 'Category updated.'
                                      : 'Category created.',
                                );
                              } catch (error) {
                                if (!dialogContext
                                    .mounted) {
                                  return;
                                }

                                setDialogState(
                                  () {
                                    saving =
                                        false;
                                  },
                                );

                                _showMessage(
                                  'Unable to save category: $error',
                                  error:
                                      true,
                                );
                              }
                            },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                            color:
                                Colors.white,
                          ),
                        )
                      : Text(
                          isEditing
                              ? 'Save'
                              : 'Create',
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // RENAME CATEGORY
  // ============================================================

  Future<void> _renameCategory({
    required String oldName,
    required String newName,
  }) async {
    final snapshot =
        await _repository
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

    final categoryId =
        snapshot.docs.first.id;

    // ----------------------------------------------------------
    // Update category document
    // ----------------------------------------------------------

    await _repository.updateCategory(
      categoryId:
          categoryId,
      name: newName,
    );

    // ----------------------------------------------------------
    // Update existing sermons using
    // the old category.
    // ----------------------------------------------------------

    final sermonsSnapshot =
        await FirebaseFirestore
            .instance
            .collection('sermons')
            .where(
              'category',
              isEqualTo: oldName,
            )
            .get();

    if (sermonsSnapshot
        .docs
        .isEmpty) {
      return;
    }

    final batch =
        FirebaseFirestore
            .instance
            .batch();

    for (final doc
        in sermonsSnapshot.docs) {
      batch.update(
        doc.reference,
        {
          'category': newName,
          'updatedAt':
              FieldValue
                  .serverTimestamp(),
        },
      );
    }

    await batch.commit();
  }

  // ============================================================
  // DELETE CATEGORY
  // ============================================================

  void _confirmDelete(
    String category,
  ) {
    showDialog(
      context: context,
      builder:
          (dialogContext) {
        bool deleting = false;

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title:
                  const Text(
                'Delete Category?',
              ),

              content:
                  Text(
                'Are you sure you want to delete "$category"?\n\n'
                'Any sermons using this category will be moved to "General".',
              ),

              actions: [
                TextButton(
                  onPressed:
                      deleting
                          ? null
                          : () {
                              Navigator.of(
                                dialogContext,
                              ).pop();
                            },
                  child:
                      const Text(
                    'Cancel',
                  ),
                ),

                ElevatedButton(
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        Colors.red,
                    foregroundColor:
                        Colors.white,
                  ),
                  onPressed:
                      deleting
                          ? null
                          : () async {
                              setDialogState(
                                () {
                                  deleting =
                                      true;
                                },
                              );

                              try {
                                // ------------------------------------------------
                                // Find category document
                                // ------------------------------------------------

                                final snapshot =
                                    await _repository
                                        .categoriesCollection
                                        .where(
                                          'name',
                                          isEqualTo:
                                              category,
                                        )
                                        .limit(
                                          1,
                                        )
                                        .get();

                                if (snapshot
                                    .docs
                                    .isEmpty) {
                                  throw Exception(
                                    'Category not found.',
                                  );
                                }

                                final categoryId =
                                    snapshot
                                        .docs
                                        .first
                                        .id;

                                // ------------------------------------------------
                                // Find sermons using this category
                                // ------------------------------------------------

                                final sermonsSnapshot =
                                    await FirebaseFirestore
                                        .instance
                                        .collection(
                                          'sermons',
                                        )
                                        .where(
                                          'category',
                                          isEqualTo:
                                              category,
                                        )
                                        .get();

                                final batch =
                                    FirebaseFirestore
                                        .instance
                                        .batch();

                                // ------------------------------------------------
                                // Move sermons to General
                                // ------------------------------------------------

                                for (final doc
                                    in sermonsSnapshot
                                        .docs) {
                                  batch.update(
                                    doc.reference,
                                    {
                                      'category':
                                          'General',
                                      'updatedAt':
                                          FieldValue
                                              .serverTimestamp(),
                                    },
                                  );
                                }

                                // ------------------------------------------------
                                // Delete category
                                // ------------------------------------------------

                                batch.delete(
                                  _repository
                                      .categoriesCollection
                                      .doc(
                                    categoryId,
                                  ),
                                );

                                await batch
                                    .commit();

                                if (!dialogContext
                                    .mounted) {
                                  return;
                                }

                                Navigator.of(
                                  dialogContext,
                                ).pop();

                                _showMessage(
                                  'Category deleted.',
                                );
                              } catch (error) {
                                if (!dialogContext
                                    .mounted) {
                                  return;
                                }

                                setDialogState(
                                  () {
                                    deleting =
                                        false;
                                  },
                                );

                                _showMessage(
                                  'Unable to delete category: $error',
                                  error:
                                      true,
                                );
                              }
                            },
                  child: deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Text(
                          'Delete',
                        ),
                ),
              ],
            );
          },
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
            const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,
          children: [
            const Icon(
              Icons
                  .category_outlined,
              size: 65,
              color:
                  Color(0xFFD5D5D5),
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'No categories yet',
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xFF777777),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Create categories to organize your sermons.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade500,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton.icon(
              onPressed: () {
                _showCategoryForm();
              },
              icon:
                  const Icon(
                Icons.add,
              ),
              label:
                  const Text(
                'Add Category',
              ),
              style:
                  ElevatedButton
                      .styleFrom(
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