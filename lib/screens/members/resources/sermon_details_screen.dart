import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../repositories/library_repository.dart';
import '../../../models/sermon_model.dart';

class SermonDetailsScreen
    extends StatelessWidget {
  final SermonModel sermon;

  const SermonDetailsScreen({
    super.key,
    required this.sermon,
  });

  static const Color primaryColor =
      Color(0xFF6B1FA2);

  static const Color darkPurple =
      Color(0xFF3D004D);

  static const Color orangeColor =
      Color(0xFFF7931E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

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
          'Sermon',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: darkPurple,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          35,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ======================================================
            // IMAGE
            // ======================================================

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child:
                    sermon.imageUrl
                            .isNotEmpty
                        ? Image.network(
                            sermon.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return _imagePlaceholder();
                            },
                          )
                        : _imagePlaceholder(),
              ),
            ),

            const SizedBox(height: 22),

            // ======================================================
            // CATEGORY
            // ======================================================

            if (sermon.category
                .trim()
                .isNotEmpty)
              Text(
                sermon.category
                    .toUpperCase(),
                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w800,
                  color: orangeColor,
                  letterSpacing: 1,
                ),
              ),

            const SizedBox(height: 7),

            // ======================================================
            // TITLE
            // ======================================================

            Text(
              sermon.title,
              style:
                  const TextStyle(
                fontSize: 25,
                fontWeight:
                    FontWeight.w800,
                color: darkPurple,
              ),
            ),

            const SizedBox(height: 8),

            // ======================================================
            // SPEAKER
            // ======================================================

            Text(
              sermon.speaker,
              style:
                  const TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w600,
                color: orangeColor,
              ),
            ),

            if (sermon.description
                .trim()
                .isNotEmpty) ...[
              const SizedBox(height: 18),

              Text(
                sermon.description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color:
                      Colors.grey.shade700,
                ),
              ),
            ],

            const SizedBox(height: 28),

            const Text(
              'Available Resources',
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.w800,
                color: darkPurple,
              ),
            ),

            const SizedBox(height: 14),

            // ======================================================
            // VIDEO
            // ======================================================

            if (sermon.videoUrl
                .trim()
                .isNotEmpty)
              _ResourceOption(
                icon: Icons
                    .play_circle_outline_rounded,
                title: 'Video',
                subtitle:
                    sermon.duration
                            .isNotEmpty
                        ? sermon.duration
                        : 'Watch this sermon',
                color: primaryColor,
                onTap: () {
                  _showLinkMessage(
                    context,
                    'Video',
                    sermon.videoUrl,
                  );
                },
              ),

            // ======================================================
            // AUDIO
            // ======================================================

            if (sermon.audioUrl
                .trim()
                .isNotEmpty) ...[
              const SizedBox(height: 12),

              _ResourceOption(
                icon: Icons
                    .headphones_outlined,
                title: 'Audio',
                subtitle:
                    'Listen to this sermon',
                color: orangeColor,
                onTap: () {
                  _showLinkMessage(
                    context,
                    'Audio',
                    sermon.audioUrl,
                  );
                },
              ),
            ],

            // ======================================================
            // EBOOK
            // ======================================================

            if (sermon.ebookUrl
                .trim()
                .isNotEmpty) ...[
              const SizedBox(height: 12),

              _ResourceOption(
                icon: Icons
                    .menu_book_outlined,
                title: 'Ebook',
                subtitle:
                    'Read the sermon material',
                color: primaryColor,
                onTap: () {
                  _showLinkMessage(
                    context,
                    'Ebook',
                    sermon.ebookUrl,
                  );
                },
              ),
            ],

            // ======================================================
            // NOTHING AVAILABLE
            // ======================================================

            if (sermon.videoUrl
                    .trim()
                    .isEmpty &&
                sermon.audioUrl
                    .trim()
                    .isEmpty &&
                sermon.ebookUrl
                    .trim()
                    .isEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF7F3F8,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: const Text(
                  'No resources are currently available for this sermon.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color:
                        Color(0xFF777777),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LINK MESSAGE
  // ============================================================

  void _showLinkMessage(
  BuildContext context,
  String type,
  String url,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape:
        const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(
        top: Radius.circular(28),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(25),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                type == 'Video'
                    ? Icons
                        .play_circle_outline
                    : type == 'Audio'
                        ? Icons
                            .headphones_outlined
                        : Icons
                            .menu_book_outlined,
                size: 55,
                color: primaryColor,
              ),

              const SizedBox(
                height: 15,
              ),

              Text(
                '$type Available',
                style:
                    const TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.w800,
                  color: darkPurple,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'Save this $type to your library for quick access.',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      Color(0xFF777777),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              SizedBox(
                width:
                    double.infinity,
                height: 50,
                child:
                    ElevatedButton(
                  onPressed: () async {
                    final user =
                        FirebaseAuth
                            .instance
                            .currentUser;

                    if (user == null) {
                      Navigator.pop(
                        sheetContext,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger
                          .of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please sign in to download sermons.',
                          ),
                          behavior:
                              SnackBarBehavior
                                  .floating,
                        ),
                      );

                      return;
                    }

                    final downloadType =
                        type.toLowerCase();

                    try {
                      await LibraryRepository
                          .instance
                          .saveDownload(
                        userId: user.uid,
                        sermon: sermon,
                        downloadType:
                            downloadType,
                      );

                      if (!sheetContext
                          .mounted) {
                        return;
                      }

                      Navigator.pop(
                        sheetContext,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger
                          .of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            '$type added to your downloads.',
                          ),
                          behavior:
                              SnackBarBehavior
                                  .floating,
                        ),
                      );
                    } catch (e) {
                      if (!sheetContext
                          .mounted) {
                        return;
                      }

                      ScaffoldMessenger
                          .of(sheetContext)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Unable to save $type: $e',
                          ),
                          behavior:
                              SnackBarBehavior
                                  .floating,
                        ),
                      );
                    }
                  },
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        primaryColor,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        25,
                      ),
                    ),
                  ),
                  child:
                      const Text(
                    'Add to My Library',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
 
  Widget _imagePlaceholder() {
    return Container(
      color:
          const Color(0xFFF3EAF5),
      child: const Center(
        child: Icon(
          Icons
              .video_library_outlined,
          size: 55,
          color:
              Color(0xFF6B1FA2),
        ),
      ),
    );
  }
}

// ================================================================
// RESOURCE OPTION
// ================================================================

class _ResourceOption
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ResourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          padding:
              const EdgeInsets.all(16),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color:
                  const Color(0xFFEDE3F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration:
                    BoxDecoration(
                  color: color.withValues(
                    alpha: .10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 27,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF3D004D),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons
                    .arrow_forward_ios_rounded,
                size: 16,
                color:
                    Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}