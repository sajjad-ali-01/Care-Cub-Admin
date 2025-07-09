import 'dart:async';
import 'dart:io';
import 'dart:math';


import 'package:carecubadmin/Community/questions.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../Dashboard/Dashboard.dart';
import 'AnswerScreen.dart';
import 'comments.dart';
import 'notifications.dart';
import 'userProfile.dart';
import 'Post_and_Ask_question.dart';
class CommunityScreen extends StatefulWidget {
  final String? scrollToPostId;

  const CommunityScreen({Key? key, this.scrollToPostId}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}
class _CommunityScreenState extends State<CommunityScreen> {


    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: CommunityHomePage(scrollToPostId: widget.scrollToPostId),
        theme: ThemeData(
          primarySwatch: Colors.red,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
      );
    }
}
enum PostMenu { delete, report, share }

class CommunityHomePage extends StatefulWidget {
  final String? scrollToPostId;

  const CommunityHomePage({super.key, this.scrollToPostId});

  @override
  State<CommunityHomePage> createState() => _CommunityHomePageState();
}

class _CommunityHomePageState extends State<CommunityHomePage> {
  bool _hasScrolledToPost = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Random _random = Random();
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> _feedItems = [];
  List<DocumentSnapshot> _questions = [];
  bool _isLoading = true;
  bool _isLoadingQuestions = true;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _perPage = 10;
  final Map<String, bool> _userRepostedStatus = {};
  final Map<String, StreamSubscription> _postSubscriptions = {};
  final Map<String, StreamSubscription> _questionSubscriptions = {};
  StreamSubscription? _feedSubscription;
  VideoPlayerController? _currentVideoController;
  ChewieController? _currentChewieController;
  String? _currentPlayingVideoId;
  int _unreadCount = 0;
  StreamSubscription? _unreadSubscription;


  @override
  void dispose() {
    _currentVideoController?.dispose();
    _currentChewieController?.dispose();
    _scrollController.dispose();
    _feedSubscription?.cancel();
    _postSubscriptions.values.forEach((sub) => sub.cancel());
    _questionSubscriptions.values.forEach((sub) => sub.cancel());
    _unreadSubscription?.cancel();
    super.dispose();
  }
  void _scrollToPostIfNeeded() {
    if (widget.scrollToPostId != null && !_hasScrolledToPost) {
      final index = _feedItems.indexWhere((item) => item.id == widget.scrollToPostId);
      if (index != -1) {
        _hasScrolledToPost = true;
        _scrollController.animateTo(
          index * 300.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }
  void _setupUnreadCountListener() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _unreadSubscription = _firestore.collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _unreadCount = snapshot.docs.length;
        });
      }
    });
  }

  Future<void> _markAllNotificationsAsRead() async {
    if (_unreadCount > 0) {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final unreadNotifications = await _firestore.collection('notifications')
            .where('userId', isEqualTo: userId)
            .where('read', isEqualTo: false)
            .get();

        final batch = _firestore.batch();
        for (final doc in unreadNotifications.docs) {
          batch.update(doc.reference, {'read': true});
        }
        await batch.commit();
      }
    }
  }


  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_scrollListener);
    _setupUnreadCountListener();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreFeedItems();
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadQuestions(),
      _loadInitialFeedItems(),
    ]);
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() => _isLoadingQuestions = true);

      final querySnapshot = await _firestore.collection('questions')
          .orderBy('timestamp', descending: true)
          .limit(5) // Load 5 questions initially
          .get();

      setState(() {
        _questions = querySnapshot.docs;
        _isLoadingQuestions = false;
      });

      // Setup listeners for these questions
      for (final question in querySnapshot.docs) {
        _listenForQuestionUpdates(question.id);
      }
    } catch (e) {
      setState(() => _isLoadingQuestions = false);
      debugPrint('Error loading questions: $e');
    }
  }

  Future<void> _loadInitialFeedItems() async {
    try {
      setState(() => _isLoading = true);

      Query query = _firestore.collection('posts')
          .orderBy('timestamp', descending: true);

      // If we're looking for a specific post, include it in the initial load
      if (widget.scrollToPostId != null) {
        final postDoc = await _firestore.collection('posts').doc(widget.scrollToPostId).get();
        if (postDoc.exists) {
          _feedItems = [postDoc];
          _lastDocument = postDoc;
          _isLoading = false;

          // Load additional posts around it
          _loadMoreFeedItems();

          return;
        }
      }

      // Otherwise, load normally
      final querySnapshot = await query.limit(_perPage).get();

      setState(() {
        _feedItems = querySnapshot.docs;
        _isLoading = false;
        _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
      });

      // Setup listeners for all posts
      for (final doc in querySnapshot.docs) {
        _listenForRepostStatus(doc.id);
      }

      // Now try to scroll to the post if needed
      _scrollToPostIfNeeded();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading initial feed: $e');
    }
  }

  Future<void> _loadMoreFeedItems() async {
    if (!_hasMore || _isLoading) return;

    try {
      setState(() => _isLoading = true);

      final querySnapshot = await _firestore.collection('posts')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_perPage)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _feedItems.addAll(querySnapshot.docs);
        _lastDocument = querySnapshot.docs.last;
        _isLoading = false;
        _hasMore = querySnapshot.docs.length == _perPage;
      });

      // Setup listeners for new posts
      for (final doc in querySnapshot.docs) {
        _listenForRepostStatus(doc.id);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading more posts: $e');
    }
  }

  void _listenForRepostStatus(String postId) {
    if (_postSubscriptions.containsKey(postId)) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _postSubscriptions[postId] = _firestore.collection('posts')
        .where('originalPostId', isEqualTo: postId)
        .where('authorId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _userRepostedStatus[postId] = snapshot.docs.isNotEmpty;
        });
      }
    });
  }

  void _listenForQuestionUpdates(String questionId) {
    if (_questionSubscriptions.containsKey(questionId)) return;

    _questionSubscriptions[questionId] = _firestore.collection('questions')
        .doc(questionId)
        .snapshots()
        .listen((snapshot) {
      if (mounted && snapshot.exists) {
        setState(() {
          final index = _questions.indexWhere((q) => q.id == questionId);
          if (index != -1) {
            _questions[index] = snapshot;
          }
        });
      }
    });
  }

  Future<void> _handleLike(String postId, bool isLiked) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final postRef = _firestore.collection('posts').doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) return;

      final postAuthorId = postDoc.data()?['authorId'] as String?;
      final postAuthorName = postDoc.data()?['authorName'] as String?;
      final currentUser = _auth.currentUser;
      final currentUserDoc = await _firestore.collection('users').doc(userId).get();
      final currentUserName = currentUserDoc.data()?['name'] as String? ?? 'Someone';

      await _firestore.runTransaction((transaction) async {
        final updatedPost = await transaction.get(postRef);
        if (!updatedPost.exists) return;

        final likes = updatedPost.data()?['likes'] as int ?? 0;
        final likedBy = updatedPost.data()?['likedBy'] as List<dynamic>? ?? [];

        if (isLiked) {
          transaction.update(postRef, {
            'likes': likes - 1,
            'likedBy': FieldValue.arrayRemove([userId])
          });
        } else {
          transaction.update(postRef, {
            'likes': likes + 1,
            'likedBy': FieldValue.arrayUnion([userId])
          });

          // Create notification only if it's not the post author liking their own post
          if (postAuthorId != null && postAuthorId != userId) {
            await _firestore.collection('notifications').add({
              'userId': postAuthorId,
              'type': 'like',
              'postId': postId,
              'senderId': userId,
              'senderName': currentUserName,
              'timestamp': FieldValue.serverTimestamp(),
              'read': false,
              'message': '$currentUserName liked your post',
            });
          }
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating like: $e')),
      );
    }
  }

  Future<void> _handleRepost(String postId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final repostQuery = await _firestore.collection('posts')
          .where('originalPostId', isEqualTo: postId)
          .where('authorId', isEqualTo: userId)
          .limit(1)
          .get();

      if (repostQuery.docs.isNotEmpty) {
        await _firestore.collection('posts').doc(repostQuery.docs.first.id).delete();
        await _firestore.collection('posts').doc(postId).update({
          'reposts': FieldValue.increment(-1),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Repost removed!')),
          );
        }
        return;
      }

      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) return;

      final originalPost = postDoc.data()!;
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;

      await _firestore.collection('posts').add({
        'type': 'repost',
        'authorId': userId,
        'authorName': userData?['name'] ?? 'Anonymous',
        'authorPhotoUrl': userData?['photoUrl'],
        'timestamp': FieldValue.serverTimestamp(),
        'originalPostId': postId,
        'originalAuthorId': originalPost['authorId'],
        'originalAuthorName': originalPost['authorName'],
        'likes': 0,
        'comments.dart': 0,
        'reposts': 0,
      });

      await _firestore.collection('posts').doc(postId).update({
        'reposts': FieldValue.increment(1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reposted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reposting: $e')),
        );
      }
    }
  }
  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('posts').doc(postId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
        // Refresh the feed
        _refreshData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: $e')),
        );
      }
    }
  }
  Future<void> _deleteQuestion(String questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // First delete the question document
        await _firestore.collection('questions').doc(questionId).delete();

        // Then delete all answers to this question
        final answers = await _firestore.collection('questions')
            .doc(questionId)
            .collection('answers')
            .get();

        final batch = _firestore.batch();
        for (final doc in answers.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question and all its answers deleted successfully')),
          );
          // Refresh the feed
          _refreshData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting question: $e')),
          );
        }
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _hasMore = true;
      _lastDocument = null;
      _feedItems.clear();
      _questions.clear();
    });
    await _loadInitialData();
  }

  // Function to get mixed feed items (posts and questions)
  List<Widget> _getMixedFeedItems() {
    List<Widget> mixedFeed = [];
    int postIndex = 0;
    int questionIndex = 0;

    // We'll show 3-5 posts, then 2 questions, and repeat
    while (postIndex < _feedItems.length || questionIndex < _questions.length) {
      // Add 3-5 posts
      int postsToAdd = min(3 + _random.nextInt(3), _feedItems.length - postIndex);
      for (int i = 0; i < postsToAdd && postIndex < _feedItems.length; i++) {
        final item = _feedItems[postIndex];
        final data = item.data() as Map<String, dynamic>;
        mixedFeed.add(_buildPostCard(data, item.id));
        postIndex++;
      }

      // Add 2 questions
      int questionsToAdd = min(2, _questions.length - questionIndex);
      for (int i = 0; i < questionsToAdd && questionIndex < _questions.length; i++) {
        final question = _questions[questionIndex];
        final data = question.data() as Map<String, dynamic>;
        mixedFeed.add(_buildQuestionCard(data, question.id));
        questionIndex++;
      }
    }

    return mixedFeed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange.shade600,
        title: const Text(
          'Care Cub Community',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24, // Increased font size
          ),
        ),
        leading: IconButton(
          onPressed: () async {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => AdminDashboard()),
                  (Route<dynamic> route) => false,
            );
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28), // Larger icon
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 28), // Larger icon
                if (_unreadCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              await _markAllNotificationsAsRead();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          const SizedBox(width: 20), // More spacing
        ],
        elevation: 0,
        toolbarHeight: 70, // Taller app bar
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Search and Action Buttons Section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), // More padding
                child: Column(
                  children: [
                    // Search Field - wider for desktop
                    SizedBox(
                      width: 600, // Fixed width for better desktop layout
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search questions or posts...',
                          prefixIcon: const Icon(Icons.search, size: 28), // Larger icon
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30), // More rounded
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(vertical: 16), // Taller
                        ),
                        onTap: () {
                          showSearch(
                            context: context,
                            delegate: CommunitySearchDelegate(),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20), // More spacing

                    // Action Buttons - larger and more prominent
                    SizedBox(
                      width: 800, // Fixed width for desktop
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.help_outline,
                            label: 'Ask Question',
                            onPressed: () => _navigateToAskQuestionScreen(context),
                          ),
                          _buildActionButton(
                            icon: Icons.edit,
                            label: 'Answer Questions',
                            onPressed: () => _navigateToAnswerScreen(context),
                          ),
                          _buildActionButton(
                            icon: Icons.post_add,
                            label: 'Create Post',
                            onPressed: () => _navigateToCreatePostScreen(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 30, thickness: 1), // Thicker divider
                  ],
                ),
              ),
            ),

            // Mixed Feed Section - adjusted for desktop
            if (_isLoading || _isLoadingQuestions)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30.0), // More padding
                    child: CircularProgressIndicator(
                      color: Colors.red[800],
                      strokeWidth: 4, // Thicker progress indicator
                    ),
                  ),
                ),
              )
            else if (_feedItems.isEmpty && _questions.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30.0), // More padding
                    child: Text(
                      'No content yet. Be the first to post or ask a question!',
                      style: TextStyle(fontSize: 18), // Larger text
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 100), // Wider content area
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final mixedItems = _getMixedFeedItems();
                      if (index >= mixedItems.length) {
                        return _hasMore
                            ? Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.red[800],
                              strokeWidth: 4,
                            ),
                          ),
                        )
                            : const SizedBox();
                      }
                      return mixedItems[index];
                    },
                    childCount: _getMixedFeedItems().length + (_hasMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28), // Larger icon
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18), // Larger text
        ),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepOrange.shade600,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // More rounded
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20), // More padding
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> data, String id) {
    final timestamp = data['timestamp'] as Timestamp?;
    final timeAgo = timestamp != null
        ? DateFormat('MMM d, y').format(timestamp.toDate())
        : 'Some time ago';

    return Container(
      width: 700,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToAnswersScreen(
              context,
              question: data['text'] ?? '',
              questionId: id
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: data['authorPhotoUrl'] != null
                          ? NetworkImage(data['authorPhotoUrl'])
                          : null,
                      child: data['authorPhotoUrl'] == null
                          ? Text(
                          data['authorName']?.toString().substring(0, 1) ?? '?',
                          style: const TextStyle(fontSize: 18))
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: data['authorName']?.replaceAll('✔️', '') ?? 'Anonymous',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                if (data['authorName']?.contains('✔️') ?? false)
                                  const TextSpan(
                                    text: ' ✔️',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600]
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Admin delete option only
                    PopupMenuButton<PostMenu>(
                      icon: const Icon(Icons.more_horiz, size: 28),
                      onSelected: (PostMenu result) async {
                        if (result == PostMenu.delete) {
                          await _deleteQuestion(id);
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return <PopupMenuEntry<PostMenu>>[
                          const PopupMenuItem<PostMenu>(
                            value: PostMenu.delete,
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red, size: 28),
                              title: Text('Delete Question', style: TextStyle(color: Colors.red, fontSize: 18)),
                            ),
                          ),
                        ];
                      },
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "${data['text'] ?? ''}?",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToAnswersScreen(
                            context,
                            question: data['text'] ?? '',
                            questionId: id
                        ),
                        icon: const Icon(Icons.edit, size: 20),
                        label: const Text('View Answers', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.orangeAccent[700],
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.black),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _navigateToAnswersScreen(
                                context,
                                question: data['text'] ?? '',
                                questionId: id);
                          },
                          icon: Icon(Icons.message, size: 20),
                          label: Text(
                            "${data['answers'] ?? 0} answers",
                            style: TextStyle(color: Colors.red[800], fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.black),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        )
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildPostCard(Map<String, dynamic> data, String id) {
    final isReportedPost = widget.scrollToPostId == id;
    _listenForRepostStatus(id);

    DateTime? postDate;
    if (data['timestamp'] != null) {
      if (data['timestamp'] is Timestamp) {
        postDate = (data['timestamp'] as Timestamp).toDate();
      }
    }

    final timeAgo = postDate != null
        ? DateFormat('MMM d, y').format(postDate)
        : 'Some time ago';

    final isLiked = (data['likedBy'] as List<dynamic>? ?? []).contains(_auth.currentUser?.uid);
    final isRepost = data['originalPostId'] != null;
    final isMyRepost = isRepost && data['authorId'] == _auth.currentUser?.uid;
    final hasReposted = _userRepostedStatus[id] ?? false;
    final commentCount = isRepost ? (data['comments'] ?? 0) : (data['comments'] ?? 0);

    return StreamBuilder<DocumentSnapshot>(
      stream: isRepost ? _firestore.collection('posts').doc(data['originalPostId']).snapshots() : null,
      builder: (context, snapshot) {
        final displayData = isRepost && snapshot.hasData
            ? snapshot.data!.data() as Map<String, dynamic>
            : data;

        return Container(
          width: 500,
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 70),
          child: Card(
            elevation: 8,
            color: isReportedPost ? Colors.red.shade50 : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isReportedPost
                  ? BorderSide(color: Colors.red, width: 3)
                  : BorderSide.none,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRepost)
                  Padding(
                    padding: const EdgeInsets.only(left: 30, right: 30, top: 16),
                    child: Row(
                      children: [
                        Icon(Icons.repeat, size: 20, color: isMyRepost ? Colors.deepOrange.shade600 : Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '${data['authorName']} reposted',
                          style: TextStyle(
                              color: isMyRepost ? Colors.deepOrange.shade600 : Colors.grey,
                              fontSize: 16
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 50,
                    right: 50,
                    top: isRepost ? 8 : 16,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileScreen(
                              userId: displayData['authorId'],
                              userName: displayData['authorName'] ?? 'Anonymous',
                              userPhotoUrl: displayData['authorPhotoUrl'] ?? '',
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: displayData['authorPhotoUrl'] != null
                            ? NetworkImage(displayData['authorPhotoUrl'] as String)
                            : null,
                        child: displayData['authorPhotoUrl'] == null
                            ? Text(
                            displayData['authorName']?.toString().substring(0, 1) ?? '?',
                            style: const TextStyle(fontSize: 18))
                            : null,
                      ),
                    ),
                    title: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileScreen(
                              userId: displayData['authorId'],
                              userName: displayData['authorName'] ?? 'Anonymous',
                              userPhotoUrl: displayData['authorPhotoUrl'] ?? '',
                            ),
                          ),
                        );
                      },
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: data['authorName']?.replaceAll('✔️', '') ?? 'Anonymous',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            if (data['authorName']?.contains('✔️') ?? false)
                              const TextSpan(
                                text: ' ✔️',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    subtitle: Text(
                      timeAgo,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    trailing: PopupMenuButton<PostMenu>(
                      icon: const Icon(Icons.more_horiz, size: 28),
                      onSelected: (PostMenu result) async {
                        if (result == PostMenu.delete) {
                          await _deletePost(id);
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return <PopupMenuEntry<PostMenu>>[
                          // Only show delete option for admin
                          const PopupMenuItem<PostMenu>(
                            value: PostMenu.delete,
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red, size: 28),
                              title: Text('Delete Post', style: TextStyle(color: Colors.red, fontSize: 18)),
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                ),
                if (displayData['text'] != null && displayData['text'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text(
                      displayData['text'].toString(),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                if (displayData['mediaUrl'] != null && displayData['mediaUrl'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: displayData['mediaType'] == 'image'
                            ? Image.network(
                          displayData['mediaUrl'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 400,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 400,
                              color: Colors.grey[300],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 400,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.error, size: 50),
                              ),
                            );
                          },
                        )
                            : displayData['mediaType'] == 'video'
                            ? SizedBox(
                          height: 500,
                          child: buildVideoPlayer(displayData['mediaUrl'], id),
                        )
                            : buildDocumentPreview(displayData['mediaUrl']),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPostActionButton(
                        icon: isLiked ? Icons.thumb_up_alt_sharp : Icons.thumb_up_alt_outlined,
                        label: "${displayData['likes'] ?? 0}",
                        onPressed: () => _handleLike(id, isLiked),
                        color: isLiked ? Colors.orangeAccent.shade700 : null,
                      ),
                      _buildPostActionButton(
                        icon: Icons.comment,
                        label: "$commentCount",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommentsScreen(
                                postId: id,
                              ),
                            ),
                          );
                        },
                      ),
                      // Remove repost button for admin
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget buildVideoPlayer(String videoUrl, String postId) {
    return VideoThumbnailPlayer(
      videoUrl: videoUrl,
      postId: postId,
    );
  }

  Widget buildDocumentPreview(String filePath) {
    final fileName = filePath.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();

    IconData icon;
    switch (extension) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        break;
      case 'txt':
        icon = Icons.text_snippet;
        break;
      default:
        icon = Icons.insert_drive_file;
    }

    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Tap to open document',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28, color: color), // Larger icon
        label: Text(
          label,
          style: TextStyle(color: color, fontSize: 18), // Larger text
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.blueGrey[700],
          padding: const EdgeInsets.symmetric(vertical: 16), // Taller buttons
        ),
      ),
    );
  }


  void _navigateToAskQuestionScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AskQuestionScreen()),
    );
  }

  void _navigateToAnswerScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuoraFeedScreen()),
    );
  }

  void _navigateToCreatePostScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AskQuestionScreen(initialTabIndex: 1)),
    );
  }

  void _navigateToAnswersScreen(BuildContext context, {required String question, required String questionId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnswersScreen(
          question: question,
          questionId: questionId,
        ),
      ),
    );
  }
}

class CommunitySearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Text('Search results for: $query'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Center(
      child: Text('Search suggestions for: $query'),
    );
  }
}
class VideoThumbnailPlayer extends StatefulWidget {
  final String videoUrl;
  final String postId;

  const VideoThumbnailPlayer({
    required this.videoUrl,
    required this.postId,
    Key? key,
  }) : super(key: key);

  @override
  _VideoThumbnailPlayerState createState() => _VideoThumbnailPlayerState();
}

class _VideoThumbnailPlayerState extends State<VideoThumbnailPlayer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isPlaying = false;
  bool _isInitialized = false;
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.network(widget.videoUrl);

    try {
      await _videoController.initialize();
      // Calculate aspect ratio from video dimensions
      _aspectRatio = _videoController.value.aspectRatio;
      // Show first frame as thumbnail
      await _videoController.pause();
      await _videoController.seekTo(Duration.zero);

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint("Error initializing video: $e");
      // Fallback to 16:9 if we can't determine aspect ratio
      _aspectRatio = 16 / 9;
      setState(() {
        _isInitialized = false;
      });
    }
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _videoController.pause();
      setState(() => _isPlaying = false);
    } else {
      if (_chewieController == null) {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          aspectRatio: _aspectRatio ?? 16 / 9,
          showControls: true,
        );
      }
      _videoController.play();
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayback,
      child: AspectRatio(
        aspectRatio: _aspectRatio ?? 16 / 9, // Use actual aspect ratio or fallback
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video frame as thumbnail (always visible)
            if (_isInitialized)
              VideoPlayer(_videoController)
            else
              Container(
                color: Colors.grey[300],
                child: Center(child: CircularProgressIndicator()),
              ),

            // Play button overlay (hidden when playing)
            if (!_isPlaying)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.play_arrow,
                  size: 36,
                  color: Colors.white,
                ),
              ),

            // Chewie controls when playing
            if (_isPlaying && _chewieController != null)
              Positioned.fill(
                child: Chewie(controller: _chewieController!),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}