import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_model.dart';
import '../models/featured_event_model.dart';
import '../models/gallery_model.dart';

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
}