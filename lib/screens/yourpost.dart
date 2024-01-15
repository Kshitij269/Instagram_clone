// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram_clone/models/user.dart' as model;
import 'package:instagram_clone/providers/user_provider.dart';
import 'package:instagram_clone/resources/firestore_methods.dart';
import 'package:instagram_clone/screens/comments_screen.dart';
import 'package:instagram_clone/screens/update_post_screen.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/utils/utils.dart';
import 'package:instagram_clone/widgets/comment_card.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class YourPostScreen extends StatefulWidget {
  final snap;
  const YourPostScreen({Key? key, required this.snap}) : super(key: key);

  @override
  State<YourPostScreen> createState() => _YourPostScreenState();
}

class _YourPostScreenState extends State<YourPostScreen> {
  int commentLen = 0;
  int displayedComments = 2;
  @override
  void initState() {
    super.initState();
    fetchCommentLen();
  }

  fetchCommentLen() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.snap['postId'])
          .collection('comments')
          .get();
      commentLen = snap.docs.length;
    } catch (err) {
      showSnackBar(
        context,
        err.toString(),
      );
    }
    setState(() {});
  }

  deletePost(String postId) async {
    try {
      if (mounted) {
        await FireStoreMethods().deletePost(postId);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (err) {
      // Handle the error
      if (mounted) {
        showSnackBar(
          context,
          err.toString(),
        );
      }
    }
  }

  Widget build(BuildContext context) {
    final model.User user = Provider.of<UserProvider>(context).getUser;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Post Details'),
        actions: [
          widget.snap['uid'].toString() == user.uid
              ? IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: ((context) {
                          return Dialog(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shrinkWrap: true,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UpdatePostScreen(
                                          currentDescription: widget
                                              .snap['description']
                                              .toString(),
                                          postImageUrl:
                                              widget.snap['postUrl'].toString(),
                                          postId:
                                              widget.snap['postId'].toString(),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    child: const Text("Update"),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    deletePost(
                                      widget.snap['postId'].toString(),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    child: const Text("Delete"),
                                  ),
                                )
                              ],
                            ),
                          );
                        }));
                  },
                )
              : Container(),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.snap['postId'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Post not found'),
            );
          }

          var post = snapshot.data!;
          if (post.data() != null && post.data()!['postUrl'] != null) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.network(
                      post['postUrl'],
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          DefaultTextStyle(
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(fontWeight: FontWeight.w800),
                            child: Text(
                              '${widget.snap['likes'].length} likes',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(
                              top: 4,
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: primaryColor),
                                children: [
                                  TextSpan(
                                    text: widget.snap['username'].toString(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' ${widget.snap['description']}',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: MediaQuery.of(context).size.height *
                                0.18, // Set a specific height or use another height constraint
                            child: StreamBuilder(
                              stream: FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(widget.snap['postId'])
                                  .collection('comments')
                                  .snapshots(),
                              builder: (context,
                                  AsyncSnapshot<
                                          QuerySnapshot<Map<String, dynamic>>>
                                      snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (snapshot.data!.docs.isEmpty) {
                                  return const Center(
                                      child: Text("No Comments"));
                                } else {
                                  return ListView.builder(
                                    itemCount: snapshot.data!.docs.length > 2
                                        ? 2
                                        : snapshot.data!.docs.length,
                                    itemBuilder: (ctx, index) => CommentCard(
                                      snap: snapshot.data!.docs[index],
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          InkWell(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Text(
                                'View all $commentLen comments',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: secondaryColor,
                                ),
                              ),
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CommentsScreen(
                                  postId: widget.snap['postId'].toString(),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              DateFormat.yMMMd().format(
                                  widget.snap['datePublished'].toDate()),
                              style: const TextStyle(
                                color: secondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Center(
              child: Text('Post data is incomplete or missing'),
            );
          }
        },
      ),
    );
  }
}
