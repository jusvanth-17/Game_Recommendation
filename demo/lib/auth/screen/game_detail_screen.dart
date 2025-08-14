import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import '../../api/rawg_api_service.dart';
import '../../services/comment_service.dart';

class GameDetailScreen extends StatefulWidget {
  final Game game;

  const GameDetailScreen({super.key, required this.game});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final RawgApiService _rawgApiService = RawgApiService();
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();
  Map<String, dynamic>? gameDetails;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchGameDetails();
    loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> fetchGameDetails() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final details = await _rawgApiService.fetchGameDetails(widget.game.id);
      
      setState(() {
        gameDetails = details;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load game details: ${e.toString()}';
        loading = false;
      });
    }
  }

  void loadComments() {
    // Comments are now loaded via StreamBuilder in the build method
  }

  Future<void> addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await _commentService.addComment(
        gameId: widget.game.id,
        comment: _commentController.text.trim(),
      );

      _commentController.clear();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> likeComment(String commentId) async {
    try {
      await _commentService.toggleLike(commentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like comment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchGameDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Game Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.game.thumbnail,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 250,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Game Title
                      Text(
                        widget.game.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Game Info Cards
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    const Icon(Icons.category, color: Colors.blue),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Genre',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.game.genre,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    const Icon(Icons.computer, color: Colors.green),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Platform',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.game.platform,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    const Icon(Icons.star, color: Colors.orange),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Rating',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      gameDetails?['rating']?.toString() ?? 'N/A',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Detailed Description Section
                      const Text(
                        'About This Game',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gameDetails?['description_raw'] ?? 
                                gameDetails?['description'] ?? 
                                widget.game.shortDescription,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                              if (gameDetails?['released'] != null) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Released: ${gameDetails!['released']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (gameDetails?['developers'] != null && 
                                  (gameDetails!['developers'] as List).isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.code, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Developer: ${gameDetails!['developers'][0]['name']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (gameDetails?['publishers'] != null && 
                                  (gameDetails!['publishers'] as List).isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.business, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Publisher: ${gameDetails!['publishers'][0]['name']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Device Compatibility Section
                      const Text(
                        'Device Compatibility',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Supported Platforms',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (gameDetails?['platforms'] != null) ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: (gameDetails!['platforms'] as List).map<Widget>((platform) {
                                    final platformName = platform['platform']['name'];
                                    final platformSlug = platform['platform']['slug'];
                                    
                                    IconData platformIcon;
                                    Color platformColor;
                                    
                                    // Assign icons and colors based on platform
                                    switch (platformSlug) {
                                      case 'pc':
                                        platformIcon = Icons.computer;
                                        platformColor = Colors.blue;
                                        break;
                                      case 'playstation4':
                                      case 'playstation5':
                                      case 'playstation3':
                                        platformIcon = Icons.sports_esports;
                                        platformColor = Colors.indigo;
                                        break;
                                      case 'xbox-one':
                                      case 'xbox-series-x':
                                      case 'xbox360':
                                        platformIcon = Icons.videogame_asset;
                                        platformColor = Colors.green;
                                        break;
                                      case 'nintendo-switch':
                                      case 'nintendo-3ds':
                                      case 'wii-u':
                                        platformIcon = Icons.gamepad;
                                        platformColor = Colors.red;
                                        break;
                                      case 'ios':
                                        platformIcon = Icons.phone_iphone;
                                        platformColor = Colors.grey;
                                        break;
                                      case 'android':
                                        platformIcon = Icons.phone_android;
                                        platformColor = Colors.lightGreen;
                                        break;
                                      case 'linux':
                                        platformIcon = Icons.laptop;
                                        platformColor = Colors.orange;
                                        break;
                                      case 'macos':
                                        platformIcon = Icons.laptop_mac;
                                        platformColor = Colors.blueGrey;
                                        break;
                                      default:
                                        platformIcon = Icons.device_unknown;
                                        platformColor = Colors.grey;
                                    }
                                    
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: platformColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: platformColor.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(platformIcon, size: 16, color: platformColor),
                                          const SizedBox(width: 6),
                                          Text(
                                            platformName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: platformColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.computer, size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.game.platform,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              
                              // System Requirements (if available)
                              if (gameDetails?['platforms'] != null) ...[
                                const Text(
                                  'System Requirements',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Compatibility Notes',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '• Check platform-specific requirements before purchasing\n'
                                        '• Some features may vary between platforms\n'
                                        '• Online features require stable internet connection\n'
                                        '• Controller support may vary by platform',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Comments Section with StreamBuilder
                      StreamBuilder<List<Comment>>(
                        stream: _commentService.getCommentsForGame(widget.game.id),
                        builder: (context, snapshot) {
                          final comments = snapshot.data ?? [];
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Comments Header
                              Row(
                                children: [
                                  const Text(
                                    'Comments',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${comments.length}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Add Comment Section
                              Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Add a comment',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _commentController,
                                        maxLines: 3,
                                        decoration: InputDecoration(
                                          hintText: 'Share your thoughts about this game...',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: addComment,
                                          icon: const Icon(Icons.send),
                                          label: const Text('Post Comment'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Comments Loading/Error State
                              if (snapshot.connectionState == ConnectionState.waiting)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (snapshot.hasError)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Failed to load comments',
                                          style: TextStyle(color: Colors.red[700]),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${snapshot.error}',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else if (comments.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Column(
                                      children: [
                                        Icon(Icons.comment_outlined, size: 48, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No comments yet',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Be the first to share your thoughts!',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                // Comments List
                                ...comments.map((comment) {
                                  final user = FirebaseAuth.instance.currentUser;
                                  final isLikedByUser = comment.likedBy.contains(user?.uid);
                                  
                                  return Card(
                                    elevation: 1,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundImage: comment.userAvatar.isNotEmpty
                                                    ? NetworkImage(comment.userAvatar)
                                                    : null,
                                                child: comment.userAvatar.isEmpty
                                                    ? const Icon(Icons.person)
                                                    : null,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      comment.userName,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Text(
                                                      formatTimestamp(comment.timestamp),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            comment.comment,
                                            style: const TextStyle(fontSize: 14, height: 1.4),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              InkWell(
                                                onTap: () => likeComment(comment.id),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      isLikedByUser 
                                                          ? Icons.thumb_up 
                                                          : Icons.thumb_up_outlined,
                                                      size: 16,
                                                      color: isLikedByUser 
                                                          ? Colors.blue[600] 
                                                          : Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${comment.likes}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isLikedByUser 
                                                            ? Colors.blue[600] 
                                                            : Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              InkWell(
                                                onTap: () {
                                                  // Reply functionality could be added here
                                                },
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.reply,
                                                      size: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Reply',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // Back Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Games'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
