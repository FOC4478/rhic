import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/community_group_model.dart';
import '../../../repositories/content_repository.dart';
import '../../../services/b2_upload_service.dart';
import '../../../services/media_url_service.dart';
import 'community_management_screen.dart';

class AdminCommunityScreen extends StatefulWidget {
  const AdminCommunityScreen({super.key});

  @override
  State<AdminCommunityScreen> createState() =>
      _AdminCommunityScreenState();
}

class _AdminCommunityScreenState
    extends State<AdminCommunityScreen> {
  final ContentRepository _repository =
      ContentRepository.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  String _filter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F7FA),
      child: StreamBuilder<List<CommunityGroupModel>>(
        stream: _repository.adminCommunityGroupsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: _ErrorState(
                    message: snapshot.error.toString(),
                  ),
                ),
              ],
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return Column(
              children: [
                _buildTopBar(context),
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            );
          }

          final groups = snapshot.data ?? [];

          final filteredGroups = groups.where((group) {
            final query =
                _searchQuery.toLowerCase().trim();

            final matchesSearch =
                query.isEmpty ||
                    group.name
                        .toLowerCase()
                        .contains(query) ||
                    group.description
                        .toLowerCase()
                        .contains(query) ||
                    group.department
                        .toLowerCase()
                        .contains(query) ||
                    group.adminName
                        .toLowerCase()
                        .contains(query);

            final matchesFilter = switch (_filter) {
              'Published' => group.isPublished,
              'Unpublished' => !group.isPublished,
              _ => true,
            };

            return matchesSearch && matchesFilter;
          }).toList();

          final publishedCount =
              groups.where((e) => e.isPublished).length;

          final unpublishedCount =
              groups.length - publishedCount;

          final totalMembers = groups.fold<int>(
            0,
            (sum, group) => sum + group.memberCount,
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 700;

              return Column(
                children: [
                  _buildTopBar(context),

                  Expanded(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          padding: EdgeInsets.all(
                            isMobile ? 16 : 24,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _Header(
                                totalCommunities:
                                    groups.length,
                                published:
                                    publishedCount,
                                unpublished:
                                    unpublishedCount,
                                members:
                                    totalMembers,
                              ),

                              const SizedBox(height: 24),

                              _SearchAndFilters(
                                controller:
                                    _searchController,
                                selectedFilter:
                                    _filter,
                                onSearchChanged:
                                    (value) {
                                  setState(() {
                                    _searchQuery =
                                        value;
                                  });
                                },
                                onFilterChanged:
                                    (value) {
                                  setState(() {
                                    _filter = value;
                                  });
                                },
                              ),

                              const SizedBox(height: 24),

                              if (filteredGroups.isEmpty)
                                const _EmptyState()
                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount:
                                      filteredGroups.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        _getCrossAxisCount(
                                      width,
                                    ),
                                    crossAxisSpacing: 18,
                                    mainAxisSpacing: 18,
                                    mainAxisExtent:
                                        _getCardHeight(
                                      width,
                                    ),
                                  ),
                                  itemBuilder:
                                      (context, index) {
                                    final group =
                                        filteredGroups[
                                            index];

                                    return _CommunityCard(
                                      group: group,
                                      onManage: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    CommunityManagementScreen(
                                              groupId:
                                                  group.id,
                                            ),
                                          ),
                                        );
                                      },
                                      onEdit: () {
                                        _showEditCommunityDialog(
                                          group,
                                        );
                                      },
                                      onDelete: () {
                                        _deleteCommunity(
                                          group,
                                        );
                                      },
                                      onTogglePublished:
                                          () {
                                        _togglePublished(
                                          group,
                                        );
                                      },
                                    );
                                  },
                                ),

                              const SizedBox(height: 100),
                            ],
                          ),
                        ),

                        Positioned(
                          right: isMobile ? 16 : 24,
                          bottom: isMobile ? 16 : 24,
                          child: FloatingActionButton.extended(
                            backgroundColor:
                                const Color(0xFF6B1FA2),
                            foregroundColor:
                                Colors.white,
                            icon: const Icon(
                              Icons.add,
                            ),
                            label: Text(
                              isMobile
                                  ? 'Add'
                                  : 'Add Community',
                            ),
                            onPressed:
                                _showCreateCommunityDialog,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 64,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Builder(
        builder: (menuContext) {
          return Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Open menu',
              onPressed: () {
                final scaffold =
                    Scaffold.maybeOf(menuContext);

                if (scaffold != null &&
                    scaffold.hasDrawer) {
                  scaffold.openDrawer();
                }
              },
              icon: const Icon(
                Icons.menu,
                color: Color(0xFF3D004D),
              ),
            ),
          );
        },
      ),
    );
  }

  int _getCrossAxisCount(double width) {
    if (width >= 1400) return 4;
    if (width >= 1000) return 3;
    if (width >= 700) return 2;
    return 1;
  }

  double _getCardHeight(double width) {
    if (width >= 1400) return 430;
    if (width >= 1000) return 445;
    if (width >= 700) return 465;
    return 475;
  }

  Future<void> _showCreateCommunityDialog() async {
    final user = FirebaseAuth.instance.currentUser;

    final result =
        await showDialog<_CommunityFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _CommunityFormDialog(
          title: 'Create Community',
          currentAdminId: user?.uid ?? '',
          currentAdminName:
              user?.displayName ?? '',
        );
      },
    );

    if (result == null) return;

    if (result.name.trim().isEmpty) {
      _showMessage(
        'Community name is required.',
        isError: true,
      );
      return;
    }

    if (result.adminId.trim().isEmpty) {
      _showMessage(
        'Admin user ID is required.',
        isError: true,
      );
      return;
    }

    if (result.adminName.trim().isEmpty) {
      _showMessage(
        'Admin name is required.',
        isError: true,
      );
      return;
    }

    try {
      final coverObjectKey =
          await _uploadCoverIfNeeded(result);

      await _repository.createCommunityGroup(
        name: result.name.trim(),
        description: result.description.trim(),
        department: result.department.trim(),
        coverImageObjectKey:
            coverObjectKey.trim(),
        requiresApproval:
            result.requiresApproval,
        adminId: result.adminId.trim(),
        adminName: result.adminName.trim(),
        isPublished: result.isPublished,
      );

      if (!mounted) return;

      _showMessage(
        'Community created successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        isError: true,
      );
    }
  }

  Future<void> _showEditCommunityDialog(
    CommunityGroupModel group,
  ) async {
    final result =
        await showDialog<_CommunityFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _CommunityFormDialog(
          title: 'Edit Community',
          group: group,
        );
      },
    );

    if (result == null) return;

    if (result.name.trim().isEmpty) {
      _showMessage(
        'Community name is required.',
        isError: true,
      );
      return;
    }

    if (result.adminId.trim().isEmpty) {
      _showMessage(
        'Admin user ID is required.',
        isError: true,
      );
      return;
    }

    if (result.adminName.trim().isEmpty) {
      _showMessage(
        'Admin name is required.',
        isError: true,
      );
      return;
    }

    try {
      final newCoverObjectKey =
          await _uploadCoverIfNeeded(result);

      final finalCoverObjectKey =
          newCoverObjectKey.trim().isNotEmpty
              ? newCoverObjectKey.trim()
              : group.coverImageObjectKey.trim();

      await _repository.updateCommunityGroup(
        groupId: group.id,
        name: result.name.trim(),
        description: result.description.trim(),
        department: result.department.trim(),
        coverImageObjectKey:
            finalCoverObjectKey,
        requiresApproval:
            result.requiresApproval,
      );

      if (result.adminId.trim() != group.adminId ||
          result.adminName.trim() != group.adminName) {
        await _repository.changeCommunityGroupAdmin(
          groupId: group.id,
          newAdminId: result.adminId.trim(),
          newAdminName: result.adminName.trim(),
        );
      }

      if (result.isPublished != group.isPublished) {
        await _repository.setCommunityGroupPublished(
          groupId: group.id,
          isPublished: result.isPublished,
        );
      }

      if (!mounted) return;

      _showMessage(
        'Community updated successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        isError: true,
      );
    }
  }

  Future<String> _uploadCoverIfNeeded(
    _CommunityFormResult result,
  ) async {
    final bytes = result.coverBytes;

    if (bytes == null || bytes.isEmpty) {
      return '';
    }

    final extension =
        result.coverExtension.toLowerCase().trim();

    if (![
      'jpg',
      'jpeg',
      'png',
      'webp',
    ].contains(extension)) {
      throw Exception(
        'Community cover must be JPG, PNG, or WEBP.',
      );
    }

    final upload =
        await B2UploadService.instance.uploadFile(
      fileName: result.coverFileName,
      bytes: bytes,
      contentType:
          _contentTypeForExtension(extension),
      mediaType: 'image',
      resourceType: 'community',
    );

    return upload.objectKey;
  }

  String _contentTypeForExtension(
    String extension,
  ) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _togglePublished(
    CommunityGroupModel group,
  ) async {
    try {
      await _repository.setCommunityGroupPublished(
        groupId: group.id,
        isPublished: !group.isPublished,
      );

      if (!mounted) return;

      _showMessage(
        group.isPublished
            ? 'Community unpublished.'
            : 'Community published.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        isError: true,
      );
    }
  }

  Future<void> _deleteCommunity(
    CommunityGroupModel group,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Community',
          ),
          content: Text(
            'Delete "${group.name}"?\n\n'
            'This will permanently remove the community '
            'and its associated community data.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteCommunityGroup(
        group.id,
      );

      if (!mounted) return;

      _showMessage(
        'Community deleted successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        isError: true,
      );
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : null,
        ),
      );
  }

  String _cleanError(Object error) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();

    return message.isEmpty
        ? 'Something went wrong.'
        : message;
  }
}

/* -------------------------------------------------------------------------- */
/* FORM RESULT                                                                */
/* -------------------------------------------------------------------------- */

class _CommunityFormResult {
  final String name;
  final String description;
  final String department;
  final String adminId;
  final String adminName;
  final bool requiresApproval;
  final bool isPublished;

  final Uint8List? coverBytes;
  final String coverFileName;
  final String coverExtension;

  const _CommunityFormResult({
    required this.name,
    required this.description,
    required this.department,
    required this.adminId,
    required this.adminName,
    required this.requiresApproval,
    required this.isPublished,
    required this.coverBytes,
    required this.coverFileName,
    required this.coverExtension,
  });
}

/* -------------------------------------------------------------------------- */
/* FORM DIALOG                                                                */
/* -------------------------------------------------------------------------- */

class _CommunityFormDialog extends StatefulWidget {
  final String title;
  final CommunityGroupModel? group;
  final String currentAdminId;
  final String currentAdminName;

  const _CommunityFormDialog({
    required this.title,
    this.group,
    this.currentAdminId = '',
    this.currentAdminName = '',
  });

  @override
  State<_CommunityFormDialog> createState() =>
      _CommunityFormDialogState();
}

class _CommunityFormDialogState
    extends State<_CommunityFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController
      _descriptionController;
  late final TextEditingController
      _departmentController;
  late final TextEditingController
      _adminIdController;
  late final TextEditingController
      _adminNameController;

  late bool _requiresApproval;
  late bool _isPublished;

  Uint8List? _selectedCoverBytes;
  String _selectedCoverFileName = '';
  String _selectedCoverExtension = '';

  bool _saving = false;

  bool get isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();

    final group = widget.group;

    _nameController = TextEditingController(
      text: group?.name ?? '',
    );

    _descriptionController =
        TextEditingController(
      text: group?.description ?? '',
    );

    _departmentController =
        TextEditingController(
      text: group?.department ?? '',
    );

    _adminIdController =
        TextEditingController(
      text: group?.adminId ??
          widget.currentAdminId,
    );

    _adminNameController =
        TextEditingController(
      text: group?.adminName ??
          widget.currentAdminName,
    );

    _requiresApproval =
        group?.requiresApproval ?? false;

    _isPublished =
        group?.isPublished ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _departmentController.dispose();
    _adminIdController.dispose();
    _adminNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final isMobile = size.width < 600;

    final horizontalPadding =
        isMobile ? 16.0 : 24.0;

    final maxHeight =
        size.height * 0.92;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 20,
        vertical: isMobile ? 12 : 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 650,
          maxHeight: maxHeight,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            horizontalPadding,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize:
                              isMobile ? 19 : 22,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              const Color(0xFF3D004D),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () =>
                              Navigator.pop(context),
                      icon:
                          const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _buildTextField(
                  controller: _nameController,
                  label: 'Community Name',
                  hint:
                      'e.g. Youth Community',
                  icon: Icons.groups_outlined,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Community name is required.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller:
                      _descriptionController,
                  label: 'Description',
                  hint:
                      'Describe this community',
                  icon:
                      Icons.description_outlined,
                  maxLines: 4,
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller:
                      _departmentController,
                  label: 'Department',
                  hint:
                      'e.g. Youth, Men, Women',
                  icon:
                      Icons.account_tree_outlined,
                ),

                const SizedBox(height: 20),

                _CoverPicker(
                  selectedBytes:
                      _selectedCoverBytes,
                  selectedFileName:
                      _selectedCoverFileName,
                  existingObjectKey:
                      widget.group
                              ?.coverImageObjectKey ??
                          '',
                  onSelected: ({
                    required Uint8List bytes,
                    required String fileName,
                    required String extension,
                  }) {
                    setState(() {
                      _selectedCoverBytes = bytes;
                      _selectedCoverFileName =
                          fileName;
                      _selectedCoverExtension =
                          extension;
                    });
                  },
                  onRemove: () {
                    setState(() {
                      _selectedCoverBytes = null;
                      _selectedCoverFileName = '';
                      _selectedCoverExtension = '';
                    });
                  },
                ),

                const SizedBox(height: 20),

                _buildTextField(
                  controller:
                      _adminIdController,
                  label: 'Admin User ID',
                  hint:
                      'Firebase UID of the community admin',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Admin user ID is required.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller:
                      _adminNameController,
                  label: 'Admin Name',
                  hint:
                      'Display name of the admin',
                  icon:
                      Icons.person_pin_outlined,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Admin name is required.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _SettingTile(
                  title: 'Requires Approval',
                  subtitle:
                      'Members must be approved before joining this community.',
                  value: _requiresApproval,
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _requiresApproval =
                                value;
                          });
                        },
                ),

                const SizedBox(height: 8),

                _SettingTile(
                  title: 'Published',
                  subtitle:
                      'Published communities can appear in the member app.',
                  value: _isPublished,
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _isPublished = value;
                          });
                        },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF6B1FA2),
                    ),
                    onPressed:
                        _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isEditing
                                ? Icons.save_outlined
                                : Icons.add,
                          ),
                    label: Text(
                      _saving
                          ? 'Saving...'
                          : isEditing
                              ? 'Save Changes'
                              : 'Create Community',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF6B1FA2),
            width: 2,
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    Navigator.pop(
      context,
      _CommunityFormResult(
        name: _nameController.text,
        description:
            _descriptionController.text,
        department:
            _departmentController.text,
        adminId: _adminIdController.text,
        adminName:
            _adminNameController.text,
        requiresApproval:
            _requiresApproval,
        isPublished: _isPublished,
        coverBytes: _selectedCoverBytes,
        coverFileName:
            _selectedCoverFileName,
        coverExtension:
            _selectedCoverExtension,
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* COVER PICKER                                                               */
/* -------------------------------------------------------------------------- */

class _CoverPicker extends StatelessWidget {
  final Uint8List? selectedBytes;
  final String selectedFileName;
  final String existingObjectKey;

  final void Function({
    required Uint8List bytes,
    required String fileName,
    required String extension,
  }) onSelected;

  final VoidCallback onRemove;

  const _CoverPicker({
    required this.selectedBytes,
    required this.selectedFileName,
    required this.existingObjectKey,
    required this.onSelected,
    required this.onRemove,
  });

  Future<void> _pickFile(
    BuildContext context,
  ) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'webp',
        ],
      );

      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();

      if (!context.mounted) {
        return;
      }

      if (bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to read the selected image.',
            ),
          ),
        );
        return;
      }

      final extension =
          file.extension?.toLowerCase() ?? '';

      if (![
        'jpg',
        'jpeg',
        'png',
        'webp',
      ].contains(extension)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Only JPG, PNG, and WEBP images are supported.',
            ),
          ),
        );
        return;
      }

      onSelected(
        bytes: bytes,
        fileName: file.name,
        extension: extension,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelected =
        selectedBytes != null &&
            selectedBytes!.isNotEmpty;

    final hasExisting =
        existingObjectKey.trim().isNotEmpty;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Community Cover Image',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Upload a JPG, PNG, or WEBP image. '
          'The image will be stored in B2 and '
          'only its object key will be saved in Firestore.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 12),

        AspectRatio(
          aspectRatio: 16 / 8,
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: hasSelected
                ? Image.memory(
                    selectedBytes!,
                    fit: BoxFit.cover,
                  )
                : hasExisting
                    ? _ExistingCover(
                        objectKey:
                            existingObjectKey,
                      )
                    : const _EmptyCover(),
          ),
        ),

        const SizedBox(height: 12),

        if (hasSelected &&
            selectedFileName.trim().isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.only(bottom: 8),
            child: Text(
              selectedFileName,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _pickFile(context),
                icon: const Icon(
                  Icons.cloud_upload_outlined,
                ),
                label: Text(
                  hasSelected || hasExisting
                      ? 'Change Cover'
                      : 'Choose Cover',
                ),
              ),
            ),
            if (hasSelected) ...[
              const SizedBox(width: 10),
              IconButton(
                tooltip:
                    'Remove selected image',
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/* EXISTING COVER                                                             */
/* -------------------------------------------------------------------------- */

class _ExistingCover extends StatefulWidget {
  final String objectKey;

  const _ExistingCover({
    required this.objectKey,
  });

  @override
  State<_ExistingCover> createState() =>
      _ExistingCoverState();
}

class _ExistingCoverState
    extends State<_ExistingCover> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(
    covariant _ExistingCover oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.objectKey !=
        widget.objectKey) {
      _future = _load();
    }
  }

  Future<String> _load() {
    return MediaUrlService.instance
        .getCommunityMediaUrl(
      objectKey: widget.objectKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return const _EmptyCover(
            message:
                'Unable to load current cover',
          );
        }

        return Image.network(
          snapshot.data!,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) {
            return const _EmptyCover(
              message:
                  'Unable to display cover',
            );
          },
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/* EMPTY COVER                                                                */
/* -------------------------------------------------------------------------- */

class _EmptyCover extends StatelessWidget {
  final String message;

  const _EmptyCover({
    this.message = 'No cover image selected',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* COMMUNITY CARD                                                             */
/* -------------------------------------------------------------------------- */

class _CommunityCard extends StatelessWidget {
  final CommunityGroupModel group;
  final VoidCallback onManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublished;

  const _CommunityCard({
    required this.group,
    required this.onManage,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublished,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            width: double.infinity,
            child: _CoverImage(
              objectKey:
                  group.coverImageObjectKey,
            ),
          ),

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                Color(0xFF3D004D),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _StatusChip(
                          published:
                              group.isPublished,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (group.department
                      .trim()
                      .isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons
                              .account_tree_outlined,
                          size: 15,
                          color:
                              Colors.grey.shade600,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            group.department,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors
                                  .grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),

                  Text(
                    group.description
                            .trim()
                            .isEmpty
                        ? 'No description'
                        : group.description,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                      height: 1.35,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 17,
                        color:
                            Colors.grey.shade600,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${group.memberCount} members',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        group.requiresApproval
                            ? Icons.lock_outline
                            : Icons.public,
                        size: 16,
                        color:
                            Colors.grey.shade600,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        group.requiresApproval
                            ? 'Approval'
                            : 'Open',
                        style: TextStyle(
                          color:
                              Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons
                            .admin_panel_settings_outlined,
                        size: 17,
                        color:
                            Colors.grey.shade600,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          group.adminName
                                  .trim()
                                  .isEmpty
                              ? 'No admin'
                              : group.adminName,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: FilledButton(
                            style:
                                FilledButton.styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF6B1FA2,
                              ),
                            ),
                            onPressed: onManage,
                            child: const Text(
                              'Manage',
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              onEdit();
                              break;

                            case 'publish':
                              onTogglePublished();
                              break;

                            case 'delete':
                              onDelete();
                              break;
                          }
                        },
                        itemBuilder:
                            (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .edit_outlined,
                                  size: 19,
                                ),
                                SizedBox(width: 10),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'publish',
                            child: Row(
                              children: [
                                Icon(
                                  group.isPublished
                                      ? Icons
                                          .visibility_off_outlined
                                      : Icons
                                          .visibility_outlined,
                                  size: 19,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  group.isPublished
                                      ? 'Unpublish'
                                      : 'Publish',
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons
                                      .delete_outline,
                                  color:
                                      Colors.red,
                                  size: 19,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color:
                                        Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* COVER IMAGE                                                                */
/* -------------------------------------------------------------------------- */

class _CoverImage extends StatefulWidget {
  final String objectKey;

  const _CoverImage({
    required this.objectKey,
  });

  @override
  State<_CoverImage> createState() =>
      _CoverImageState();
}

class _CoverImageState
    extends State<_CoverImage> {
  Future<String>? _future;

  @override
  void initState() {
    super.initState();
    _loadFuture();
  }

  @override
  void didUpdateWidget(
    covariant _CoverImage oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.objectKey !=
        widget.objectKey) {
      _loadFuture();
    }
  }

  void _loadFuture() {
    if (widget.objectKey.trim().isEmpty) {
      _future = null;
      return;
    }

    _future = MediaUrlService.instance
        .getCommunityMediaUrl(
      objectKey: widget.objectKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.objectKey.trim().isEmpty) {
      return const _CardImagePlaceholder();
    }

    return FutureBuilder<String>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _CardImagePlaceholder(
            loading: true,
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return const _CardImagePlaceholder();
        }

        return Image.network(
          snapshot.data!,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) {
            return const _CardImagePlaceholder();
          },
        );
      },
    );
  }
}

class _CardImagePlaceholder
    extends StatelessWidget {
  final bool loading;

  const _CardImagePlaceholder({
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0EAF3),
      child: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Icon(
                Icons.groups_outlined,
                size: 50,
                color:
                    Colors.deepPurple.shade200,
              ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* HEADER                                                                     */
/* -------------------------------------------------------------------------- */

class _Header extends StatelessWidget {
  final int totalCommunities;
  final int published;
  final int unpublished;
  final int members;

  const _Header({
    required this.totalCommunities,
    required this.published,
    required this.unpublished,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final cardWidth = width >= 1000
            ? 210.0
            : width >= 700
                ? 190.0
                : (width - 14) / 2;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _StatCard(
              width: cardWidth,
              title: 'Communities',
              value:
                  totalCommunities.toString(),
              icon: Icons.groups_outlined,
            ),
            _StatCard(
              width: cardWidth,
              title: 'Published',
              value: published.toString(),
              icon:
                  Icons.visibility_outlined,
            ),
            _StatCard(
              width: cardWidth,
              title: 'Unpublished',
              value:
                  unpublished.toString(),
              icon:
                  Icons.visibility_off_outlined,
            ),
            _StatCard(
              width: cardWidth,
              title: 'Members',
              value: members.toString(),
              icon: Icons.people_outline,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  const Color(0xFF6B1FA2)
                      .withValues(alpha: .10),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 21,
              color:
                  const Color(0xFF6B1FA2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF3D004D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* SEARCH + FILTER                                                            */
/* -------------------------------------------------------------------------- */

class _SearchAndFilters
    extends StatelessWidget {
  final TextEditingController controller;
  final String selectedFilter;
  final ValueChanged<String>
      onSearchChanged;
  final ValueChanged<String>
      onFilterChanged;

  const _SearchAndFilters({
    required this.controller,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow =
            constraints.maxWidth < 560;

        if (isNarrow) {
          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              _buildSearchField(),
              const SizedBox(height: 12),
              _buildFilter(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 500,
                ),
                child: _buildSearchField(),
              ),
            ),
            const SizedBox(width: 12),
            _buildFilter(),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: controller,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText:
            'Search communities...',
        prefixIcon:
            const Icon(Icons.search),
        suffixIcon:
            controller.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      controller.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(
                      Icons.clear,
                    ),
                  )
                : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
    );
  }

  Widget _buildFilter() {
    return DropdownButtonHideUnderline(
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: DropdownButton<String>(
          value: selectedFilter,
          items: const [
            DropdownMenuItem(
              value: 'All',
              child: Text('All'),
            ),
            DropdownMenuItem(
              value: 'Published',
              child: Text('Published'),
            ),
            DropdownMenuItem(
              value: 'Unpublished',
              child: Text('Unpublished'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onFilterChanged(value);
            }
          },
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* SETTING TILE                                                               */
/* -------------------------------------------------------------------------- */

class _SettingTile
    extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color:
                  Colors.grey.shade600,
            ),
          ),
        ),
        value: value,
        activeThumbColor:
            const Color(0xFF6B1FA2),
        onChanged: onChanged,
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* STATUS CHIP                                                                */
/* -------------------------------------------------------------------------- */

class _StatusChip
    extends StatelessWidget {
  final bool published;

  const _StatusChip({
    required this.published,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: published
            ? Colors.green
                .withValues(alpha: .10)
            : Colors.orange
                .withValues(alpha: .10),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        published
            ? 'Published'
            : 'Unpublished',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight:
              FontWeight.w700,
          color: published
              ? Colors.green.shade700
              : Colors.orange.shade700,
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* EMPTY / ERROR STATES                                                       */
/* -------------------------------------------------------------------------- */

class _EmptyState
    extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 70,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          const Text(
            'No communities found',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a community or change your search/filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load communities',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}