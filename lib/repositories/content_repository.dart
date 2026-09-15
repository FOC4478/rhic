import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/community_post_model.dart';
import '../models/teaching_model.dart';
import '../models/event_model.dart';
import '../models/featured_event_model.dart';
import '../models/gallery_model.dart';
import '../models/community_group_model.dart';
import '../models/community_member_model.dart';
import '../models/community_comment_model.dart';

class ContentRepository {
  ContentRepository._();

  static final ContentRepository instance =
      ContentRepository._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // FEATURED EVENT
  // ============================================================

  Stream<FeaturedEvent?> featuredEventStream() {
    return _firestore
        .collection('featured_events')
        .doc('current')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      final event =
          FeaturedEvent.fromFirestore(snapshot);

      if (!event.isActive) {
        return null;
      }

      return event;
    });
  }

  // ============================================================
  // CURRENT EVENT
  // ============================================================

  Stream<EventModel?> eventStream() {
    return _firestore
        .collection('events')
        .doc('current')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return EventModel.fromFirestore(snapshot);
    });
  }

  // ============================================================
  // ADMIN CURRENT EVENT
  // ============================================================

  Stream<EventModel?> adminEventStream() {
    return _firestore
        .collection('events')
        .doc('current')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return EventModel.fromFirestore(snapshot);
    });
  }

  // ============================================================
  // SAVE CURRENT EVENT
  // ============================================================

  Future<void> saveEvent({
    required String imageObjectKey,
    required String createdBy,
  }) async {
    if (imageObjectKey.trim().isEmpty) {
      throw Exception(
        'Please upload an event flyer.',
      );
    }

    if (createdBy.trim().isEmpty) {
      throw Exception(
        'Admin account could not be identified.',
      );
    }

    final eventRef = _firestore
        .collection('events')
        .doc('current');

    final existing = await eventRef.get();

    await eventRef.set(
      {
        'imageObjectKey':
            imageObjectKey.trim(),

        'createdBy':
            createdBy.trim(),

        'isPublished': true,

        'isFeatured': false,

        'updatedAt':
            FieldValue.serverTimestamp(),

        if (!existing.exists)
          'createdAt':
              FieldValue.serverTimestamp(),

        // Keep eventDate because it remains
        // part of EventModel and is used
        // for other purposes.
        if (!existing.exists)
          'eventDate':
              Timestamp.fromDate(
            DateTime.now(),
          ),

        // Keep title for compatibility with
        // EventModel and older functionality.
        if (!existing.exists)
          'title': 'Current Event',
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // DELETE CURRENT EVENT
  // ============================================================

  Future<void> deleteCurrentEvent() async {
    final eventRef = _firestore
        .collection('events')
        .doc('current');

    final snapshot =
        await eventRef.get();

    if (!snapshot.exists) {
      return;
    }

    await eventRef.delete();
  }

  // ============================================================
  // MEMBER EVENTS
  // ============================================================

  Stream<List<EventModel>> eventsStream() {
    final now =
        Timestamp.fromDate(DateTime.now());

    return _firestore
        .collection('events')
        .where(
          'isPublished',
          isEqualTo: true,
        )
        .where(
          'eventDate',
          isGreaterThanOrEqualTo: now,
        )
        .orderBy('eventDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(EventModel.fromFirestore)
              .toList(),
        );
  }

  // ============================================================
  // ADMIN EVENTS
  // ============================================================

  Stream<List<EventModel>> adminEventsStream() {
    return _firestore
        .collection('events')
        .orderBy('eventDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(EventModel.fromFirestore)
              .toList(),
        );
  }

  // ============================================================
  // CREATE EVENT
  // ============================================================

  Future<String> createEvent({
    required String title,
    required DateTime eventDate,
    required String imageObjectKey,
    required bool isFeatured,
    required bool isPublished,
    required String createdBy,
  }) async {
    if (title.trim().isEmpty) {
      throw Exception(
        'Please enter the event name.',
      );
    }

    if (imageObjectKey.trim().isEmpty) {
      throw Exception(
        'Please upload an event flyer.',
      );
    }

    if (createdBy.trim().isEmpty) {
      throw Exception(
        'Admin account could not be identified.',
      );
    }

    if (isFeatured && !isPublished) {
      throw Exception(
        'Only a published event can be featured.',
      );
    }

    final events =
        _firestore.collection('events');

    final eventRef = events.doc();

    final batch = _firestore.batch();

    // ----------------------------------------------------------
    // ONLY ONE EVENT CAN BE FEATURED
    // ----------------------------------------------------------

    if (isFeatured) {
      final featuredSnapshot = await events
          .where(
            'isFeatured',
            isEqualTo: true,
          )
          .get();

      for (final doc
          in featuredSnapshot.docs) {
        batch.update(
          doc.reference,
          {
            'isFeatured': false,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      }
    }

    // ----------------------------------------------------------
    // CREATE EVENT
    // ----------------------------------------------------------

    batch.set(
      eventRef,
      {
        'title': title.trim(),
        'eventDate':
            Timestamp.fromDate(eventDate),
        'imageObjectKey':
            imageObjectKey.trim(),
        'isFeatured': isFeatured,
        'isPublished': isPublished,
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
        'createdBy': createdBy.trim(),
      },
    );

    await batch.commit();

    // ----------------------------------------------------------
    // SYNC FEATURED EVENT
    // ----------------------------------------------------------

    if (isFeatured && isPublished) {
      await _syncFeaturedEventFromData(
        eventId: eventRef.id,
        title: title.trim(),
        imageObjectKey:
            imageObjectKey.trim(),
        eventDate: eventDate,
      );
    }

    return eventRef.id;
  }

  // ============================================================
  // UPDATE EVENT
  // ============================================================

  Future<void> updateEvent({
    required String eventId,
    required String title,
    required DateTime eventDate,
    required String imageObjectKey,
    required bool isFeatured,
    required bool isPublished,
  }) async {
    if (eventId.trim().isEmpty) {
      throw Exception(
        'Event could not be identified.',
      );
    }

    if (title.trim().isEmpty) {
      throw Exception(
        'Please enter the event name.',
      );
    }

    if (imageObjectKey.trim().isEmpty) {
      throw Exception(
        'Please upload an event flyer.',
      );
    }

    if (isFeatured && !isPublished) {
      throw Exception(
        'Only a published event can be featured.',
      );
    }

    final events =
        _firestore.collection('events');

    final eventRef =
        events.doc(eventId);

    // ----------------------------------------------------------
    // CHECK THAT EVENT EXISTS
    // ----------------------------------------------------------

    final existingSnapshot =
        await eventRef.get();

    if (!existingSnapshot.exists) {
      throw Exception(
        'Event not found.',
      );
    }

    final existingData =
        existingSnapshot.data() ?? {};

    final wasFeatured =
        existingData['isFeatured'] == true;

    final batch =
        _firestore.batch();

    // ----------------------------------------------------------
    // ONLY ONE EVENT CAN BE FEATURED
    // ----------------------------------------------------------

    if (isFeatured) {
      final featuredSnapshot = await events
          .where(
            'isFeatured',
            isEqualTo: true,
          )
          .get();

      for (final doc
          in featuredSnapshot.docs) {
        if (doc.id != eventId) {
          batch.update(
            doc.reference,
            {
              'isFeatured': false,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        }
      }
    }

    // ----------------------------------------------------------
    // UPDATE EVENT
    // ----------------------------------------------------------

    batch.update(
      eventRef,
      {
        'title': title.trim(),
        'eventDate':
            Timestamp.fromDate(eventDate),
        'imageObjectKey':
            imageObjectKey.trim(),
        'isFeatured': isFeatured,
        'isPublished': isPublished,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();

    // ----------------------------------------------------------
    // SYNC FEATURED EVENT
    // ----------------------------------------------------------

    if (isFeatured && isPublished) {
      await _syncFeaturedEventFromData(
        eventId: eventId,
        title: title.trim(),
        imageObjectKey:
            imageObjectKey.trim(),
        eventDate: eventDate,
      );
    } else if (wasFeatured) {
      await _deactivateFeaturedEvent(
        eventId,
      );
    }
  }

  // ============================================================
  // DELETE EVENT
  // ============================================================

  Future<void> deleteEvent(
    String eventId,
  ) async {
    if (eventId.trim().isEmpty) {
      throw Exception(
        'Event could not be identified.',
      );
    }

    final eventRef = _firestore
        .collection('events')
        .doc(eventId);

    final snapshot =
        await eventRef.get();

    if (!snapshot.exists) {
      return;
    }

    final data =
        snapshot.data() ?? {};

    final wasFeatured =
        data['isFeatured'] == true;

    await eventRef.delete();

    // ----------------------------------------------------------
    // REMOVE FROM HOME FEATURED EVENT
    // ----------------------------------------------------------

    if (wasFeatured) {
      await _deactivateFeaturedEvent(
        eventId,
      );
    }
  }

  // ============================================================
  // SET EVENT PUBLISHED
  // ============================================================

  Future<void> setEventPublished({
    required String eventId,
    required bool isPublished,
  }) async {
    if (eventId.trim().isEmpty) {
      throw Exception(
        'Event could not be identified.',
      );
    }

    final eventRef = _firestore
        .collection('events')
        .doc(eventId);

    final snapshot =
        await eventRef.get();

    if (!snapshot.exists) {
      throw Exception(
        'Event not found.',
      );
    }

    final data =
        snapshot.data() ?? {};

    final isFeatured =
        data['isFeatured'] == true;

    // ----------------------------------------------------------
    // UNPUBLISH
    // ----------------------------------------------------------

    if (!isPublished) {
      await eventRef.update({
        'isPublished': false,
        'isFeatured': false,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (isFeatured) {
        await _deactivateFeaturedEvent(
          eventId,
        );
      }

      return;
    }

    // ----------------------------------------------------------
    // PUBLISH
    // ----------------------------------------------------------

    await eventRef.update({
      'isPublished': true,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    if (isFeatured) {
      final eventDate =
          _timestampToDateTime(
        data['eventDate'],
      );

      if (eventDate != null) {
        await _syncFeaturedEventFromData(
          eventId: eventId,
          title:
              data['title']?.toString() ?? '',
          imageObjectKey:
              data['imageObjectKey']
                      ?.toString() ??
                  '',
          eventDate: eventDate,
        );
      }
    }
  }

  // ============================================================
  // SET EVENT FEATURED
  // ============================================================

  Future<void> setEventFeatured({
    required String eventId,
    required bool isFeatured,
  }) async {
    if (eventId.trim().isEmpty) {
      throw Exception(
        'Event could not be identified.',
      );
    }

    final events =
        _firestore.collection('events');

    final eventRef =
        events.doc(eventId);

    final eventSnapshot =
        await eventRef.get();

    if (!eventSnapshot.exists) {
      throw Exception(
        'Event not found.',
      );
    }

    final eventData =
        eventSnapshot.data() ?? {};

    // ----------------------------------------------------------
    // FEATURE EVENT
    // ----------------------------------------------------------

    if (isFeatured) {
      if (eventData['isPublished'] != true) {
        throw Exception(
          'Only a published event can be featured.',
        );
      }

      final featuredSnapshot = await events
          .where(
            'isFeatured',
            isEqualTo: true,
          )
          .get();

      final batch =
          _firestore.batch();

      for (final doc
          in featuredSnapshot.docs) {
        if (doc.id != eventId) {
          batch.update(
            doc.reference,
            {
              'isFeatured': false,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        }
      }

      batch.update(
        eventRef,
        {
          'isFeatured': true,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      final eventDate =
          _timestampToDateTime(
        eventData['eventDate'],
      );

      if (eventDate != null) {
        await _syncFeaturedEventFromData(
          eventId: eventId,
          title:
              eventData['title']?.toString() ??
                  '',
          imageObjectKey:
              eventData['imageObjectKey']
                      ?.toString() ??
                  '',
          eventDate: eventDate,
        );
      }

      return;
    }

    // ----------------------------------------------------------
    // UNFEATURE EVENT
    // ----------------------------------------------------------

    await eventRef.update({
      'isFeatured': false,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    await _deactivateFeaturedEvent(
      eventId,
    );
  }

  // ============================================================
  // SYNC FEATURED EVENT TO HOME
  // ============================================================
  //
  // The Home screen can resolve imageObjectKey through B2.
  //
  // Compatibility fields imageUrl/date/time are retained so
  // existing FeaturedEvent documents/models do not immediately
  // break.
  //
  // ============================================================

  Future<void> _syncFeaturedEventFromData({
    required String eventId,
    required String title,
    required String imageObjectKey,
    required DateTime eventDate,
  }) async {
    await _firestore
        .collection('featured_events')
        .doc('current')
        .set(
      {
        'eventId': eventId,
        'title': title,

        // Actual B2 flyer object key.
        'imageObjectKey': imageObjectKey,

        // Compatibility with older model/code.
        'imageUrl': '',
        'date': _formatEventDate(eventDate),
        'time': '',

        'actionRoute': '/events',
        'isActive': true,

        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // DEACTIVATE FEATURED EVENT
  // ============================================================

  Future<void> _deactivateFeaturedEvent(
    String eventId,
  ) async {
    final featuredRef = _firestore
        .collection('featured_events')
        .doc('current');

    final snapshot =
        await featuredRef.get();

    if (!snapshot.exists) {
      return;
    }

    final data =
        snapshot.data() ?? {};

    final featuredEventId =
        data['eventId']?.toString() ?? '';

    // Only deactivate the Home featured document if it
    // belongs to this event.
    if (featuredEventId == eventId ||
        featuredEventId.isEmpty) {
      await featuredRef.set(
        {
          'isActive': false,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }

  // ============================================================
  // FORMAT EVENT DATE
  // ============================================================

  String _formatEventDate(
    DateTime date,
  ) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} '
        '${date.day}, '
        '${date.year}';
  }

  // ============================================================
  // SAFE TIMESTAMP → DATETIME
  // ============================================================

  DateTime? _timestampToDateTime(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // ============================================================
  // TEACHINGS
  // ============================================================

  Stream<List<TeachingModel>> teachingsStream() {
    return _firestore
        .collection('teachings')
        .where(
          'isPublished',
          isEqualTo: true,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(TeachingModel.fromFirestore)
              .toList(),
        );
  }

  // ============================================================
  // GALLERY
  // ============================================================

  Stream<List<GalleryItem>> galleryStream() {
    return _firestore
        .collection('gallery')
        .where(
          'isPublished',
          isEqualTo: true,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(GalleryItem.fromFirestore)
              .toList(),
        );
  }

  // ============================================================
  // USER PROFILE
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      userProfileStream(
    String uid,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots();
  }

  // ============================================================
  // RHIC COMMUNITY
  // ============================================================

  Stream<List<CommunityGroupModel>>
      communityGroupsStream() {
    return _firestore
        .collection('community_groups')
        .where(
          'isPublished',
          isEqualTo: true,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                CommunityGroupModel.fromFirestore,
              )
              .toList(),
        );
  }

  // ============================================================
  // GET SINGLE COMMUNITY GROUP
  // ============================================================

  Stream<CommunityGroupModel?>
      communityGroupStream(
    String groupId,
  ) {
    return _firestore
        .collection('community_groups')
        .doc(groupId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return CommunityGroupModel.fromFirestore(
        snapshot,
      );
    });
  }

  // ============================================================
  // JOIN COMMUNITY GROUP
  // ============================================================

  Future<void> joinCommunityGroup({
    required String groupId,
    required String uid,
  }) async {
    final groupRef = _firestore
        .collection('community_groups')
        .doc(groupId);

    final memberRef = groupRef
        .collection('members')
        .doc(uid);

    final userRef =
        _firestore.collection('users').doc(uid);

    await _firestore.runTransaction(
      (transaction) async {
        final memberSnapshot =
            await transaction.get(
          memberRef,
        );

        if (memberSnapshot.exists) {
          return;
        }

        final userSnapshot =
            await transaction.get(
          userRef,
        );

        final userData =
            userSnapshot.data() ?? {};

        final name =
            userData['displayName']
                    ?.toString() ??
                userData['name']
                    ?.toString() ??
                'RHIC Member';

        final photoUrl =
            userData['photoUrl']
                    ?.toString() ??
                userData['photoURL']
                    ?.toString() ??
                '';

        transaction.set(
          memberRef,
          {
            'uid': uid,
            'name': name,
            'photoUrl': photoUrl,
            'joinedAt':
                FieldValue.serverTimestamp(),
          },
        );

        transaction.update(
          groupRef,
          {
            'memberCount':
                FieldValue.increment(1),
          },
        );
      },
    );
  }

  // ============================================================
  // LEAVE COMMUNITY GROUP
  // ============================================================

  Future<void> leaveCommunityGroup({
    required String groupId,
    required String uid,
  }) async {
    final groupRef = _firestore
        .collection('community_groups')
        .doc(groupId);

    final memberRef = groupRef
        .collection('members')
        .doc(uid);

    await _firestore.runTransaction(
      (transaction) async {
        final memberSnapshot =
            await transaction.get(
          memberRef,
        );

        if (!memberSnapshot.exists) {
          return;
        }

        transaction.delete(memberRef);

        transaction.update(
          groupRef,
          {
            'memberCount':
                FieldValue.increment(-1),
          },
        );
      },
    );
  }

  // ============================================================
  // CHECK IF USER IS A MEMBER
  // ============================================================

  Stream<bool> isCommunityGroupMember({
    required String groupId,
    required String uid,
  }) {
    return _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('members')
        .doc(uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.exists,
        );
  }

  // ============================================================
  // GET GROUP MEMBERS
  // ============================================================

  Stream<List<CommunityMemberModel>>
      communityGroupMembersStream(
    String groupId,
  ) {
    return _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('members')
        .orderBy(
          'joinedAt',
          descending: false,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                CommunityMemberModel.fromFirestore,
              )
              .toList(),
        );
  }

  // ============================================================
  // STREAM GROUP POSTS
  // ============================================================

  Stream<List<CommunityPostModel>>
      communityPostsStream(
    String groupId,
  ) {
    return _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('posts')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                CommunityPostModel.fromFirestore,
              )
              .toList(),
        );
  }

  // ============================================================
  // CREATE COMMUNITY POST
  // ============================================================

  Future<String> createCommunityPost({
    required CommunityPostModel post,
  }) async {
    final postsRef = _firestore
        .collection('community_groups')
        .doc(post.groupId)
        .collection('posts');

    final postRef = postsRef.doc();

    final data =
        post.toFirestore();

    data['createdAt'] =
        FieldValue.serverTimestamp();

    data['updatedAt'] =
        FieldValue.serverTimestamp();

    await postRef.set(data);

    return postRef.id;
  }

  // ============================================================
  // UPDATE COMMUNITY POST
  // ============================================================

  Future<void> updateCommunityPost({
    required String groupId,
    required String postId,
    required String content,
    required List<String> imageUrls,
  }) async {
    await _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('posts')
        .doc(postId)
        .update({
      'content': content,
      'imageUrls': imageUrls,
      'isEdited': true,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // DELETE COMMUNITY POST
  // ============================================================

  Future<void> deleteCommunityPost({
    required String groupId,
    required String postId,
  }) async {
    await _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('posts')
        .doc(postId)
        .delete();
  }

  // ============================================================
  // STREAM POST COMMENTS
  // ============================================================

  Stream<List<CommunityCommentModel>>
      communityCommentsStream({
    required String groupId,
    required String postId,
  }) {
    return _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy(
          'createdAt',
          descending: false,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                CommunityCommentModel.fromFirestore,
              )
              .toList(),
        );
  }

  // ============================================================
  // ADD COMMENT
  // ============================================================

  Future<String> addCommunityComment({
    required String groupId,
    required CommunityCommentModel comment,
  }) async {
    final commentsRef = _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('posts')
        .doc(comment.postId)
        .collection('comments');

    final commentRef =
        commentsRef.doc();

    final data =
        comment.toFirestore();

    data['createdAt'] =
        FieldValue.serverTimestamp();

    await commentRef.set(data);

    await _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('posts')
        .doc(comment.postId)
        .update({
      'commentCount':
          FieldValue.increment(1),
    });

    return commentRef.id;
  }

  // ============================================================
  // DELETE COMMENT
  // ============================================================

  Future<void> deleteCommunityComment({
    required String groupId,
    required String postId,
    required String commentId,
  }) async {
    final commentRef = _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    final commentSnapshot =
        await commentRef.get();

    if (!commentSnapshot.exists) {
      return;
    }

    await commentRef.delete();

    await _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('posts')
        .doc(postId)
        .update({
      'commentCount':
          FieldValue.increment(-1),
    });
  }

  // ============================================================
  // CHECK IF USER LIKED POST
  // ============================================================

  Stream<bool> isPostLiked({
    required String groupId,
    required String postId,
    required String uid,
  }) {
    return _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.exists,
        );
  }

  // ============================================================
  // TOGGLE POST LIKE
  // ============================================================

  Future<void> togglePostLike({
    required String groupId,
    required String postId,
    required String uid,
  }) async {
    final postRef = _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('posts')
        .doc(postId);

    final likeRef = postRef
        .collection('likes')
        .doc(uid);

    await _firestore.runTransaction(
      (transaction) async {
        final likeSnapshot =
            await transaction.get(
          likeRef,
        );

        if (likeSnapshot.exists) {
          transaction.delete(likeRef);

          transaction.update(
            postRef,
            {
              'likeCount':
                  FieldValue.increment(-1),
            },
          );
        } else {
          transaction.set(
            likeRef,
            {
              'uid': uid,
              'createdAt':
                  FieldValue.serverTimestamp(),
            },
          );

          transaction.update(
            postRef,
            {
              'likeCount':
                  FieldValue.increment(1),
            },
          );
        }
      },
    );
  }

  // ============================================================
  // CHECK IF USER IS GROUP ADMIN / HOD
  // ============================================================

  Stream<bool> isCommunityGroupAdmin({
    required String groupId,
    required String uid,
  }) {
    return _firestore
        .collection('community_groups')
        .doc(groupId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return false;
      }

      final data =
          snapshot.data();

      return data?['adminId']?.toString() ==
          uid;
    });
  }

  // ============================================================
  // GET GROUP ADMIN ID
  // ============================================================

  Future<String?> getCommunityGroupAdminId(
    String groupId,
  ) async {
    final snapshot = await _firestore
        .collection('community_groups')
        .doc(groupId)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot
        .data()?['adminId']
        ?.toString();
  }

  // ============================================================
  // UPDATE GROUP INFORMATION
  // ============================================================

  Future<void> updateCommunityGroup({
    required String groupId,
    required String name,
    required String description,
    required String department,
    required String coverImageUrl,
  }) async {
    await _firestore
        .collection('community_groups')
        .doc(groupId)
        .update({
      'name': name,
      'description': description,
      'department': department,
      'coverImageUrl': coverImageUrl,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // REMOVE MEMBER
  // ============================================================

  Future<void> removeCommunityGroupMember({
    required String groupId,
    required String uid,
  }) async {
    final groupRef = _firestore
        .collection('community_groups')
        .doc(groupId);

    final memberRef = groupRef
        .collection('members')
        .doc(uid);

    await _firestore.runTransaction(
      (transaction) async {
        final memberSnapshot =
            await transaction.get(
          memberRef,
        );

        if (!memberSnapshot.exists) {
          return;
        }

        transaction.delete(memberRef);

        transaction.update(
          groupRef,
          {
            'memberCount':
                FieldValue.increment(-1),
          },
        );
      },
    );
  }

  // ============================================================
  // MAKE MEMBER ADMIN
  // ============================================================

  Future<void> changeCommunityGroupAdmin({
    required String groupId,
    required String newAdminId,
    required String newAdminName,
  }) async {
    await _firestore
        .collection('community_groups')
        .doc(groupId)
        .update({
      'adminId': newAdminId,
      'adminName': newAdminName,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // PIN / UNPIN COMMUNITY POST
  // ============================================================

  Future<void> toggleCommunityPostPin({
    required String groupId,
    required String postId,
    required bool isPinned,
  }) async {
    await _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('posts')
        .doc(postId)
        .update({
      'isPinned': isPinned,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // PUBLISH / UNPUBLISH COMMUNITY GROUP
  // ============================================================

  Future<void> setCommunityGroupPublished({
    required String groupId,
    required bool isPublished,
  }) async {
    await _firestore
        .collection('community_groups')
        .doc(groupId)
        .update({
      'isPublished': isPublished,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }
}