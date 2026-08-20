import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_post_model.dart';
import '../models/teaching_model.dart';
import '../models/event_model.dart';
import '../models/featured_event_model.dart';
import '../models/gallery_model.dart';
import '../models/community_group_model.dart';

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

      final event = FeaturedEvent.fromFirestore(snapshot);

      if (!event.isActive) {
        return null;
      }

      return event;
    });
  }

  // ============================================================
  // EVENTS
  // ============================================================

  Stream<List<EventModel>> eventsStream() {
    return _firestore
        .collection('events')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(EventModel.fromFirestore)
              .toList(),
        );
  }

  // ============================================================
  // TEACHINGS
  // ============================================================

  Stream<List<TeachingModel>> teachingsStream() {
    return _firestore
        .collection('teachings')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
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
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
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

  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfileStream(
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

  // ------------------------------------------------------------
  // GET ALL PUBLISHED COMMUNITY GROUPS
  // ------------------------------------------------------------

  Stream<List<CommunityGroupModel>> communityGroupsStream() {
    return _firestore
        .collection('community_groups')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(CommunityGroupModel.fromFirestore)
              .toList(),
        );
  }

  // ------------------------------------------------------------
  // GET SINGLE COMMUNITY GROUP
  // ------------------------------------------------------------

  Stream<CommunityGroupModel?> communityGroupStream(
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

      return CommunityGroupModel.fromFirestore(snapshot);
    });
  }
  // ------------------------------------------------------------
  // JOIN COMMUNITY GROUP
  // ------------------------------------------------------------

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
          await transaction.get(memberRef);

      if (memberSnapshot.exists) {
        return;
      }

      final userSnapshot =
          await transaction.get(userRef);

      final userData =
          userSnapshot.data() ?? {};

      final name =
          userData['displayName']?.toString() ??
          userData['name']?.toString() ??
          'RHIC Member';

      final photoUrl =
          userData['photoUrl']?.toString() ??
          userData['photoURL']?.toString() ??
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

  // ------------------------------------------------------------
  // LEAVE COMMUNITY GROUP
  // ------------------------------------------------------------

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
            await transaction.get(memberRef);

        // User isn't a member.
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

  // ------------------------------------------------------------
  // CHECK IF USER IS A MEMBER
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // GET GROUP MEMBERS
  // ------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>>
      communityGroupMembersStream(
    String groupId,
  ) {
    return _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('members')
        .orderBy('joinedAt', descending: false)
        .snapshots();
  }




  // ------------------------------------------------------------
  // STREAM GROUP POSTS
  // ------------------------------------------------------------

  Stream<List<CommunityPostModel>> communityPostsStream(
    String groupId,
  ) {
    return _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                CommunityPostModel.fromFirestore,
              )
              .toList(),
        );
  }

  // ------------------------------------------------------------
  // CREATE COMMUNITY POST
  // ------------------------------------------------------------

  Future<String> createCommunityPost({
    required CommunityPostModel post,
  }) async {
    final postsRef = _firestore
        .collection('community_groups')
        .doc(post.groupId)
        .collection('posts');

    final postRef = postsRef.doc();

    final data = post.toFirestore();

    data['createdAt'] =
        FieldValue.serverTimestamp();

    data['updatedAt'] =
        FieldValue.serverTimestamp();

    await postRef.set(data);

    return postRef.id;
  }

  // ------------------------------------------------------------
  // UPDATE COMMUNITY POST
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // DELETE COMMUNITY POST
  // ------------------------------------------------------------

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


  // ------------------------------------------------------------
  // STREAM POST COMMENTS
  // ------------------------------------------------------------

  Stream<List<CommunityCommentModel>> communityCommentsStream({
    required String groupId,
    required String postId,
  }) {
    return _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                CommunityCommentModel.fromFirestore,
              )
              .toList(),
        );
  }

  // ------------------------------------------------------------
  // ADD COMMENT
  // ------------------------------------------------------------

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

    final commentRef = commentsRef.doc();

    final data = comment.toFirestore();

    data['createdAt'] =
        FieldValue.serverTimestamp();

    await commentRef.set(data);

    // Update the post's comment count.
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

  // ------------------------------------------------------------
  // DELETE COMMENT
  // ------------------------------------------------------------

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



  // ------------------------------------------------------------
  // CHECK IF USER LIKED POST
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // TOGGLE POST LIKE
  // ------------------------------------------------------------

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
            await transaction.get(likeRef);

        if (likeSnapshot.exists) {
          // -----------------------------------------------
          // REMOVE LIKE
          // -----------------------------------------------

          transaction.delete(likeRef);

          transaction.update(
            postRef,
            {
              'likeCount':
                  FieldValue.increment(-1),
            },
          );
        } else {
          // -----------------------------------------------
          // ADD LIKE
          // -----------------------------------------------

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


// ------------------------------------------------------------
// CHECK IF USER IS THE GROUP ADMIN / HOD
// ------------------------------------------------------------

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

    final data = snapshot.data();

    return data?['adminId']?.toString() == uid;
  });
}

// ------------------------------------------------------------
// GET GROUP ADMIN ID
// ------------------------------------------------------------

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

  return snapshot.data()?['adminId']?.toString();
}

// ------------------------------------------------------------
// UPDATE GROUP INFORMATION
// ------------------------------------------------------------

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
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

// ------------------------------------------------------------
// REMOVE MEMBER
// ------------------------------------------------------------

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
          await transaction.get(memberRef);

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

// ------------------------------------------------------------
// MAKE MEMBER ADMIN
// ------------------------------------------------------------

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
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

// ------------------------------------------------------------
// PIN / UNPIN COMMUNITY POST
// ------------------------------------------------------------

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
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

Future<void> setCommunityGroupPublished({
  required String groupId,
  required bool isPublished,
}) async {
  await _firestore
      .collection('community_groups')
      .doc(groupId)
      .update({
    'isPublished': isPublished,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}







}