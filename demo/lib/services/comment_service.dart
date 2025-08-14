import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Comment {
  final String id;
  final String gameId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String comment;
  final DateTime timestamp;
  final int likes;
  final List<String> likedBy;

  Comment({
    required this.id,
    required this.gameId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.comment,
    required this.timestamp,
    required this.likes,
    required this.likedBy,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      gameId: data['gameId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userAvatar: data['userAvatar'] ?? '',
      comment: data['comment'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gameId': gameId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'comment': comment,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'likedBy': likedBy,
    };
  }

  Comment copyWith({
    String? id,
    String? gameId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? comment,
    DateTime? timestamp,
    int? likes,
    List<String>? likedBy,
  }) {
    return Comment(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      comment: comment ?? this.comment,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'comments';

  // Get comments for a specific game
  Stream<List<Comment>> getCommentsForGame(int gameId) {
    print('🔍 Getting comments for game ID: $gameId');
    return _firestore
        .collection(_collection)
        .where('gameId', isEqualTo: gameId.toString())
        .snapshots()
        .map((snapshot) {
      print('📊 Received ${snapshot.docs.length} comments from Firestore');
      final comments = snapshot.docs.map((doc) {
        print('📄 Comment doc: ${doc.id} - ${doc.data()}');
        return Comment.fromFirestore(doc);
      }).toList();
      
      // Sort by timestamp in Dart instead of Firestore to avoid index requirement
      comments.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      print('✅ Mapped and sorted ${comments.length} comments');
      return comments;
    });
  }

  // Add a new comment
  Future<void> addComment({
    required int gameId,
    required String comment,
  }) async {
    try {
      print('🔄 Starting to add comment...');
      
      final user = FirebaseAuth.instance.currentUser;
      print('👤 Current user: ${user?.uid} - ${user?.displayName}');
      
      if (user == null) {
        print('❌ User is not logged in');
        throw Exception('User must be logged in to comment');
      }

      final newComment = Comment(
        id: '', // Firestore will generate the ID
        gameId: gameId.toString(),
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous',
        userAvatar: user.photoURL ?? '',
        comment: comment,
        timestamp: DateTime.now(),
        likes: 0,
        likedBy: [],
      );

      print('📝 Comment data: ${newComment.toFirestore()}');
      print('🗃️ Adding to collection: $_collection');
      
      final docRef = await _firestore.collection(_collection).add(newComment.toFirestore());
      print('✅ Comment added successfully with ID: ${docRef.id}');
      
    } catch (e) {
      print('❌ Error adding comment: $e');
      rethrow;
    }
  }

  // Like/unlike a comment
  Future<void> toggleLike(String commentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to like comments');
    }

    final commentRef = _firestore.collection(_collection).doc(commentId);
    
    await _firestore.runTransaction((transaction) async {
      final commentDoc = await transaction.get(commentRef);
      
      if (!commentDoc.exists) {
        throw Exception('Comment does not exist');
      }

      final data = commentDoc.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final currentLikes = data['likes'] ?? 0;

      if (likedBy.contains(user.uid)) {
        // Unlike the comment
        likedBy.remove(user.uid);
        transaction.update(commentRef, {
          'likedBy': likedBy,
          'likes': currentLikes - 1,
        });
      } else {
        // Like the comment
        likedBy.add(user.uid);
        transaction.update(commentRef, {
          'likedBy': likedBy,
          'likes': currentLikes + 1,
        });
      }
    });
  }

  // Delete a comment (only by the author)
  Future<void> deleteComment(String commentId, String authorUserId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to delete comments');
    }

    if (user.uid != authorUserId) {
      throw Exception('Only the author can delete this comment');
    }

    await _firestore.collection(_collection).doc(commentId).delete();
  }

  // Update a comment (only by the author)
  Future<void> updateComment(String commentId, String authorUserId, String newComment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to update comments');
    }

    if (user.uid != authorUserId) {
      throw Exception('Only the author can update this comment');
    }

    await _firestore.collection(_collection).doc(commentId).update({
      'comment': newComment,
      'timestamp': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Get comment count for a game
  Future<int> getCommentCount(int gameId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('gameId', isEqualTo: gameId.toString())
        .get();
    
    return snapshot.docs.length;
  }

  // Get recent comments across all games (for admin or analytics)
  Stream<List<Comment>> getRecentComments({int limit = 10}) {
    return _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    });
  }
}
