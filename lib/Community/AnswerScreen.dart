import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AnswersScreen extends StatefulWidget {
  final String question;
  final String questionId;
  final String? scrollToAnswerId;
  final bool expandReplies;
  const AnswersScreen({
    super.key,
    required this.question,
    required this.questionId,
    this.scrollToAnswerId,
    this.expandReplies = false,
  });

  @override
  State<AnswersScreen> createState() => _AnswersScreenState();
}

class _AnswersScreenState extends State<AnswersScreen> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController _answerController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  List<DocumentSnapshot> _answers = [];
  bool _isLoading = true;
  bool _showOnlyMyAnswers = false;
  String? _currentUserId;
  Map<String, bool> _expandedReplies = {};
  Map<String, TextEditingController> _replyControllers = {};
  Map<String, bool> _isReplying = {};
  Map<String, bool> _isUpvoting = {};
  File? _imageFile;
  File? _videoFile;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isUploading = false;
  String userName = '';
  String userInitials = '';
  String userPhotoUrl = '';
  bool isDoctor = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    _fetchUserData();
    _loadAnswers().then((_) {
      if (widget.scrollToAnswerId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToAnswer(widget.scrollToAnswerId!);
        });
      }
    });
  }

  Future<String?> _uploadMediaToCloudinary() async {
    if (_imageFile == null && _videoFile == null) return null;

    try {
      setState(() {
        _isUploading = true;
      });

      final url = Uri.parse('https://api.cloudinary.com/v1_1/dghmibjc3/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'CareCub';

      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _imageFile!.path,
        ));
      } else if (_videoFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _videoFile!.path,
        ));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'] ?? jsonMap['url'];
      } else {
        throw Exception('Failed to upload media to Cloudinary');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading media: $e')),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doctorDoc = await FirebaseFirestore.instance
            .collection('Doctors')
            .doc(user.uid)
            .get();

        if (doctorDoc.exists) {
          setState(() {
            userName = doctorDoc['title'] + " "+ doctorDoc['name']?? 'Dr.' ;
            userPhotoUrl = doctorDoc['photoUrl'] ?? '';
            isDoctor = true;
          });
        } else {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            setState(() {
              userName = userDoc['name'] ?? '';
              userPhotoUrl = userDoc['photoUrl'] ?? '';
              isDoctor = false;
            });
          }
        }

        if (userName.isNotEmpty) {
          final initials = userName
              .split(' ')
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0])
              .join()
              .toUpperCase();
          setState(() {
            userInitials = initials;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _scrollToAnswer(String answerId) {
    final index = _answers.indexWhere((a) => a.id == answerId);
    if (index != -1) {
      scrollController.animateTo(
        index * 300.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      if (widget.expandReplies) {
        setState(() {
          _expandedReplies[answerId] = true;
        });
      }
    }
  }

  Future<void> _loadAnswers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      Query query = _firestore
          .collection('questions')
          .doc(widget.questionId)
          .collection('answers')
          .orderBy('timestamp', descending: true);

      final querySnapshot = await query.get();

      for (var answer in querySnapshot.docs) {
        _replyControllers[answer.id] = TextEditingController();
        _expandedReplies[answer.id] = false;
        _isReplying[answer.id] = false;
        _isUpvoting[answer.id] = false;
      }

      setState(() {
        _answers = querySnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading answers: $e')),
      );
    }
  }

  Future<void> _showMediaSelectionDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Media Type"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const Text('Image'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage();
                  },
                ),
                const Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: const Text('Video'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickVideo();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _videoFile = null;
          if (_videoController != null) {
            _videoController!.dispose();
            _videoController = null;
          }
          if (_chewieController != null) {
            _chewieController!.dispose();
            _chewieController = null;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _videoFile = File(pickedFile.path);
          _imageFile = null;
          _initializeVideoPlayer(_videoFile!.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video: $e')),
      );
    }
  }

  void _initializeVideoPlayer(String videoPath) async {
    if (_videoController != null) {
      await _videoController?.dispose();
    }
    if (_chewieController != null) {
     // await _chewieController?.dispose();
    }

    _videoController = VideoPlayerController.file(File(videoPath));
    await _videoController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      aspectRatio: _videoController!.value.aspectRatio,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.red,
        handleColor: Colors.red,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.grey.shade400,
      ),
    );

    setState(() {});
  }

  void _clearMedia() {
    if (_videoController != null) {
      _videoController!.dispose();
      _videoController = null;
    }
    if (_chewieController != null) {
      _chewieController!.dispose();
      _chewieController = null;
    }
    setState(() {
      _imageFile = null;
      _videoFile = null;
    });
  }

  Future<void> _postAnswer() async {
    if (_answerController.text.trim().isEmpty && _imageFile == null && _videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write an answer or add media')),
      );
      return;
    }

    try {
      setState(() {
        _isUploading = true;
      });

      final user = _auth.currentUser;
      if (user == null) return;

      String? mediaUrl;
      String? mediaType;

      if (_imageFile != null || _videoFile != null) {
        mediaUrl = await _uploadMediaToCloudinary();
        mediaType = _imageFile != null ? 'image' : 'video';
      }

      final questionDoc = await _firestore.collection('questions').doc(widget.questionId).get();
      final questionAuthorId = questionDoc.data()?['authorId'] as String?;
      final questionAuthorName = questionDoc.data()?['authorName'] as String?;

      Map<String, dynamic> answerData = {
        'text': _answerController.text,
        'questionId': widget.questionId,
        'authorId': user.uid,
        'authorName': userName,
        'authorPhotoUrl': userPhotoUrl,
        'authorIsDoctor': isDoctor,
        'timestamp': FieldValue.serverTimestamp(),
        'upvotes': 0,
        'upvotedBy': [],
        'replyCount': 0,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
      };

      final answerRef = await _firestore
          .collection('questions')
          .doc(widget.questionId)
          .collection('answers')
          .add(answerData);

      await _firestore.collection('questions').doc(widget.questionId).update({
        'answers': FieldValue.increment(1),
      });

      if (questionAuthorId != null && questionAuthorId != user.uid) {
        await _firestore.collection('notifications').add({
          'userId': questionAuthorId,
          'type': 'answer',
          'questionId': widget.questionId,
          'senderId': user.uid,
          'senderName': userName,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'message': '$userName answered your question: "${widget.question}"',
          'mediaUrl': mediaUrl,
          'mediaType': mediaType,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer posted successfully!')),
      );
      _answerController.clear();
      _clearMedia();
      await _loadAnswers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting answer: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _postReply(String answerId) async {
    final controller = _replyControllers[answerId];
    if (controller == null || controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a reply')),
      );
      return;
    }

    try {
      setState(() {
        _isReplying[answerId] = true;
      });

      final user = _auth.currentUser;
      if (user == null) return;

      final answerDoc = await _firestore
          .collection('questions')
          .doc(widget.questionId)
          .collection('answers')
          .doc(answerId)
          .get();
      final answerAuthorId = answerDoc.data()?['authorId'] as String?;
      final answerAuthorName = answerDoc.data()?['authorName'] as String?;

      await _firestore
          .collection('questions')
          .doc(widget.questionId)
          .collection('answers')
          .doc(answerId)
          .collection('replies')
          .add({
        'text': controller.text.trim(),
        'answerId': answerId,
        'authorId': user.uid,
        'authorName': userName,
        'authorPhotoUrl': userPhotoUrl,
        'authorIsDoctor': isDoctor,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore
          .collection('questions')
          .doc(widget.questionId)
          .collection('answers')
          .doc(answerId)
          .update({
        'replyCount': FieldValue.increment(1),
      });

      if (answerAuthorId != null && answerAuthorId != user.uid) {
        final questionDoc = await _firestore.collection('questions').doc(widget.questionId).get();
        final questionText = questionDoc.data()?['text'] as String? ?? 'a question';

        await _firestore.collection('notifications').add({
          'userId': answerAuthorId,
          'type': 'reply',
          'questionId': widget.questionId,
          'questionText': questionText,
          'answerId': answerId,
          'senderId': user.uid,
          'senderName': userName,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'message': '$userName replied to your answer on "$questionText"',
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply posted successfully!')),
      );

      controller.clear();
      setState(() {
        _isReplying[answerId] = false;
      });
    } catch (e) {
      setState(() {
        _isReplying[answerId] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting reply: $e')),
      );
    }
  }

  Future<void> _toggleUpvote(String answerId, List<dynamic> upvotedBy) async {
    try {
      if (_currentUserId == null) return;

      setState(() {
        _isUpvoting[answerId] = true;
      });

      final isUpvoted = upvotedBy.contains(_currentUserId);
      final answerIndex = _answers.indexWhere((a) => a.id == answerId);

      if (answerIndex == -1) return;

      final updatedAnswer = Map<String, dynamic>.from(_answers[answerIndex].data() as Map<String, dynamic>);
      final updatedUpvotedBy = List.from(upvotedBy);
      final currentUpvotes = updatedAnswer['upvotes'] ?? 0;

      if (isUpvoted) {
        updatedUpvotedBy.remove(_currentUserId);
        updatedAnswer['upvotes'] = currentUpvotes - 1;
      } else {
        updatedUpvotedBy.add(_currentUserId);
        updatedAnswer['upvotes'] = currentUpvotes + 1;
      }

      updatedAnswer['upvotedBy'] = updatedUpvotedBy;

      setState(() {
        _answers[answerIndex] = _answers[answerIndex].reference.update(updatedAnswer) as DocumentSnapshot<Object?>;
      });

      await _firestore
          .collection('questions')
          .doc(widget.questionId)
          .collection('answers')
          .doc(answerId)
          .update({
        'upvotes': isUpvoted ? FieldValue.increment(-1) : FieldValue.increment(1),
        'upvotedBy': isUpvoted
            ? FieldValue.arrayRemove([_currentUserId])
            : FieldValue.arrayUnion([_currentUserId]),
      });

    } catch (e) {
      _loadAnswers();
    } finally {
      setState(() {
        _isUpvoting[answerId] = false;
      });
    }
  }

  void _toggleReplies(String answerId) {
    setState(() {
      _expandedReplies[answerId] = !(_expandedReplies[answerId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      appBar: isDesktop ? null : AppBar(
        title: const Text("Answers", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrange.shade600,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white)
        ),
        elevation: 1,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: SizedBox(
        width: 1000,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Text(
                widget.question,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Text(
                "Responses on this question",
                style: TextStyle(color: Colors.red[400], fontSize: 16),
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Answers list (2/3 width)
                Expanded(
                flex: 2,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _answers.isEmpty
                    ? const Center(
                  child: Text('No answers yet. Be the first to answer!'),
                )
                    : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: _answers.length,
                  itemBuilder: (context, index) {
                    final answer = _answers[index];
                    final data = answer.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] as Timestamp?;
                    final timeAgo = timestamp != null
                        ? DateFormat('MMM d, y').format(timestamp.toDate())
                        : 'Some time ago';
                    final upvotedBy = data['upvotedBy'] as List<dynamic>? ?? [];
                    final isUpvoted = _currentUserId != null &&
                        upvotedBy.contains(_currentUserId);
                    final replyCount = data['replyCount'] ?? 0;
                    final isUpvoting = _isUpvoting[answer.id] ?? false;
                    final hasMedia = data['mediaType'] != null;
                    final mediaType = data['mediaType'] as String?;

                    return Column(
                      children: [
                        Card(
                          margin: const EdgeInsets.all(12),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundImage:
                                    data['authorPhotoUrl'] != null
                                        ? NetworkImage(data['authorPhotoUrl'])
                                        : null,
                                    child: data['authorPhotoUrl'] == null
                                        ? Text(data['authorName']
                                        ?.toString()
                                        .substring(0, 1) ??
                                        '?')
                                        : null,
                                  ),
                                  title: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: data['authorName'] ?? 'Anonymous',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        if (data['authorIsDoctor'] == true)
                                          const TextSpan(
                                            text: ' ✔️',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  subtitle: Text(timeAgo),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    data['text'] ?? '',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                if (hasMedia && mediaType == 'image' && data['mediaUrl'] != null)
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        data['mediaUrl'],
                                        width: double.infinity,
                                        height: 300,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            height: 300,
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
                                            height: 300,
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child: Icon(Icons.broken_image),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                if (hasMedia && mediaType == 'video' && data['mediaUrl'] != null)
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: _VideoPlayerWidget(
                                        videoUrl: data['mediaUrl'],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            isUpvoted ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                                            color: isUpvoted ? Colors.blue : null,
                                            size: 24,
                                          ),
                                          onPressed: isUpvoting ? null : () => _toggleUpvote(answer.id, upvotedBy),
                                        ),
                                        if (isUpvoting)
                                          const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                          ),
                                      ],
                                    ),
                                    Text('${data['upvotes'] ?? 0}', style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 20),
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.comment, size: 24),
                                          onPressed: () => _toggleReplies(answer.id),
                                        ),
                                      ],
                                    ),
                                    Text('$replyCount', style: const TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_expandedReplies[answer.id] ?? false)
                          _buildRepliesSection(answer.id),
                      ],
                    );
                  },
                ),
              ),
              // Answer input section (1/3 width)
              Container(
                width: 350,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(left: BorderSide(color: Colors.grey.shade300))),
                  child: Column(
                    children: [
                      const Text(
                        "Post Your Answer",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_imageFile != null)
                        Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Image.file(
                                _imageFile!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: _clearMedia,
                              ),
                            ),
                          ],
                        ),
                      if (_videoFile != null)
                        Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: _chewieController != null
                                    ? Chewie(controller: _chewieController!)
                                    : Container(
                                  color: Colors.black,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: _clearMedia,
                              ),
                            ),
                          ],
                        ),
                      Expanded(
                        child: TextField(
                          controller: _answerController,
                          decoration: InputDecoration(
                            hintText: "Write your answer...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          maxLines: null,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file, size: 28),
                            onPressed: _showMediaSelectionDialog,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUploading ? null : _postAnswer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange.shade600,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _isUploading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : const Text(
                                "Post Answer",
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
    Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Text(widget.question, style: const TextStyle(fontSize: 17)),
    ),
    Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
    child: Text(
    "Responses on this question",
    style: TextStyle(color: Colors.red[400], fontSize: 15),
    ),
    ),
    Expanded(
    child: _isLoading
    ? const Center(child: CircularProgressIndicator())
        : _answers.isEmpty
    ? const Center(
    child: Text('No answers yet. Be the first to answer!'),
    )
        : ListView.builder(
    controller: scrollController,
    padding: const EdgeInsets.only(bottom: 80),
    itemCount: _answers.length,
    itemBuilder: (context, index) {
    final answer = _answers[index];
    final data = answer.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp?;
    final timeAgo = timestamp != null
    ? DateFormat('MMM d, y').format(timestamp.toDate())
        : 'Some time ago';
    final upvotedBy = data['upvotedBy'] as List<dynamic>? ?? [];
    final isUpvoted = _currentUserId != null &&
    upvotedBy.contains(_currentUserId);
    final replyCount = data['replyCount'] ?? 0;
    final isUpvoting = _isUpvoting[answer.id] ?? false;
    final hasMedia = data['mediaType'] != null;
    final mediaType = data['mediaType'] as String?;

    return Column(
    children: [
    Card(
    margin: const EdgeInsets.all(8),
    child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    ListTile(
    leading: CircleAvatar(
    backgroundImage:
    data['authorPhotoUrl'] != null
    ? NetworkImage(data['authorPhotoUrl'])
        : null,
    child: data['authorPhotoUrl'] == null
    ? Text(data['authorName']
        ?.toString()
        .substring(0, 1) ??
    '?')
        : null,
    ),
    title: Text.rich(
    TextSpan(
    children: [
    TextSpan(
    text: data['authorName'] ?? 'Anonymous',
    style: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    ),
    ),
    if (data['authorIsDoctor'] == true)
    const TextSpan(
    text: ' ✔️',
    style: TextStyle(
    color: Colors.blue,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    ),
    ),
    ],
    ),
    ),
    subtitle: Text(timeAgo),
    ),
    Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(data['text'] ?? ''),
    ),
    if (hasMedia && mediaType == 'image' && data['mediaUrl'] != null)
    Padding(
    padding: const EdgeInsets.all(8.0),
    child: ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
    data['mediaUrl'],
    width: double.infinity,
    fit: BoxFit.cover,
    loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Container(
    height: 200,
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
    height: 200,
    color: Colors.grey[300],
    child: const Center(
    child: Icon(Icons.broken_image),
    ),
    );
    },
    ),
    ),
    ),
    if (hasMedia && mediaType == 'video' && data['mediaUrl'] != null)
    Padding(
    padding: const EdgeInsets.all(8.0),
    child: AspectRatio(
    aspectRatio: 16 / 9,
    child: _VideoPlayerWidget(
    videoUrl: data['mediaUrl'],
    ),
    ),
    ),
    const SizedBox(height: 8),
    Row(
    children: [
    Stack(
    alignment: Alignment.center,
    children: [
    IconButton(
    icon: Icon(
    isUpvoted ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
    color: isUpvoted ? Colors.blue : null,
    ),
    onPressed: isUpvoting ? null : () => _toggleUpvote(answer.id, upvotedBy),
    ),
    if (isUpvoting)
    const CircularProgressIndicator(
    strokeWidth: 2,
    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
    ),
    ],
    ),
    Text('${data['upvotes'] ?? 0}'),
    const SizedBox(width: 16),
    Stack(
    alignment: Alignment.center,
    children: [
    IconButton(
    icon: const Icon(Icons.comment),
    onPressed: () => _toggleReplies(answer.id),
    ),
    ],
    ),
    Text('$replyCount'),
    ],
    ),
    ],
    ),
    ),
    ),
    if (_expandedReplies[answer.id] ?? false)
    _buildRepliesSection(answer.id),
    ],
    );
    },
    ),
    ),
    // Mobile answer input section
    Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
    color: Colors.white,
    border: Border(top: BorderSide(color: Colors.grey.shade300))),
    child: Column(
    children: [
    if (_imageFile != null)
    Stack(
    children: [
    Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Image.file(
    _imageFile!,
    width: double.infinity,
    height: 150,
    fit: BoxFit.cover,
    ),
    ),
    Positioned(
    top: 4,
    right: 4,
    child: IconButton(
    icon: const Icon(Icons.close, color: Colors.red),
    onPressed: _clearMedia,
    ),
    ),
    ],
    ),
    if (_videoFile != null)
    Stack(
    children: [
    Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: AspectRatio(
    aspectRatio: 16 / 9,
    child: _chewieController != null
    ? Chewie(controller: _chewieController!)
        : Container(
    color: Colors.black,
    child: const Center(
    child: CircularProgressIndicator(),
    ),
    ),
    ),
    ),
    Positioned(
    top: 4,
    right: 4,
    child: IconButton(
    icon: const Icon(Icons.close, color: Colors.red),
    onPressed: _clearMedia,
    ),
    ),
    ],
    ),
    Container(
    decoration: BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(25),
    ),
    child: Row(
    children: [
    IconButton(
    icon: const Icon(Icons.attach_file),
    onPressed: _showMediaSelectionDialog,
    ),
    Expanded(
    child: TextField(
    controller: _answerController,
    decoration: const InputDecoration(
    hintText: "Write your answer...",
    border: InputBorder.none,
    contentPadding: EdgeInsets.symmetric(horizontal: 12),
    ),
    maxLines: null,
    ),
    ),
    _isUploading
    ? const Padding(
    padding: EdgeInsets.all(8.0),
    child: SizedBox(
    width: 24,
    height: 24,
    child: CircularProgressIndicator(strokeWidth: 2),
    ),
    )
        : Padding(
    padding: const EdgeInsets.only(right: 8),
    child: IconButton(
    icon: const Icon(Icons.send, color: Colors.deepOrange),
    onPressed: _postAnswer,
    ),
    ),
    ],
    ),
    ),
    const SizedBox(height: 10),
    ],
    ),
    )
        ],
    );
    }

  Widget _buildRepliesSection(String answerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('questions')
          .doc(widget.questionId)
          .collection('answers')
          .doc(answerId)
          .collection('replies')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading replies'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final replies = snapshot.data?.docs ?? [];
        final isReplying = _isReplying[answerId] ?? false;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 8, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyControllers[answerId] ??= TextEditingController(),
                      decoration: const InputDecoration(
                        hintText: "Write a reply...",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: null,
                      enabled: !isReplying,
                    ),
                  ),
                  isReplying
                      ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                      : IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _postReply(answerId),
                  ),
                ],
              ),
            ),
            ...replies.map((reply) {
              final replyData = reply.data() as Map<String, dynamic>;
              final timestamp = replyData['timestamp'] as Timestamp?;
              final timeAgo = timestamp != null
                  ? DateFormat('MMM d, y').format(timestamp.toDate())
                  : 'Some time ago';

              return Padding(
                padding: const EdgeInsets.only(left: 40, right: 8, top: 4),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundImage:
                            replyData['authorPhotoUrl'] != null
                                ? NetworkImage(replyData['authorPhotoUrl'])
                                : null,
                            child: replyData['authorPhotoUrl'] == null
                                ? Text(replyData['authorName']
                                ?.toString()
                                .substring(0, 1) ??
                                '?')
                                : null,
                          ),
                          title: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: replyData['authorName'] ?? 'Anonymous',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                if (replyData['authorIsDoctor'] == true)
                                  const TextSpan(
                                    text: ' ✔️',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          subtitle: Text(
                            timeAgo,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(replyData['text'] ?? ''),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    for (var controller in _replyControllers.values) {
      controller.dispose();
    }
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerWidget({required this.videoUrl});

  @override
  __VideoPlayerWidgetState createState() => __VideoPlayerWidgetState();
}

class __VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.network(widget.videoUrl);
    await _controller.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _controller,
      autoPlay: false,
      looping: false,
      allowFullScreen: true,
      aspectRatio: _controller.value.aspectRatio,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.red,
        handleColor: Colors.red,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.grey.shade400,
      ),
    );
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Chewie(controller: _chewieController!);
  }
}