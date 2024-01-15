// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/models/user.dart' as model;
import 'package:instagram_clone/providers/user_provider.dart';
import 'package:instagram_clone/resources/firestore_methods.dart';
import 'package:instagram_clone/screens/comments_screen.dart';
import 'package:instagram_clone/screens/update_post_screen.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/utils/global_variable.dart';
import 'package:instagram_clone/utils/utils.dart';
import 'package:instagram_clone/widgets/like_animation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SearchCard extends StatefulWidget {
  final snap;

  const SearchCard({
    Key? key,
    required this.snap,
  }) : super(key: key);

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  int commentLen = 0;

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
      setState(() {});
    } catch (err) {
      showSnackBar(
        context,
        err.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final model.User user = Provider.of<UserProvider>(context).getUser;
    final width = MediaQuery.of(context).size.width;
    int commentLen = 0;

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('posts').snapshots(),
      builder: (context,
          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.data == null) {
          return const CircularProgressIndicator();
        }

        QueryDocumentSnapshot<Map<String, dynamic>>? commonSnap;
        for (QueryDocumentSnapshot<Map<String, dynamic>> document
            in snapshot.data!.docs) {
          if (document.id == widget.snap['postId'].toString()) {
            commonSnap = document;
            break;
          }
        }

        if (commonSnap == null || !mounted) {
          return const Text('No matching snapshot found');
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: width > webScreenSize
                  ? secondaryColor
                  : mobileBackgroundColor,
            ),
            color: mobileBackgroundColor,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 10,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 16,
                ).copyWith(right: 0),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(
                        widget.snap['profImage'].toString(),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.snap['username'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    widget.snap['uid'].toString() == user.uid
                        ? IconButton(
                            onPressed: () {
                              showDialog(
                                useRootNavigator: false,
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    child: ListView(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shrinkWrap: true,
                                      children: [
                                        InkWell(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 16),
                                            child: const Text('Update'),
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    UpdatePostScreen(
                                                  currentDescription: widget
                                                      .snap['description']
                                                      .toString(),
                                                  postImageUrl: widget
                                                      .snap['postUrl']
                                                      .toString(),
                                                  postId: widget.snap['postId']
                                                      .toString(),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        InkWell(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 16),
                                            child: const Text('Delete'),
                                          ),
                                          onTap: () {
                                            deletePost(widget.snap['postId']
                                                .toString());
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.more_vert),
                          )
                        : Container(),
                  ],
                ),
              ),
              // IMAGE SECTION OF THE POST
              GestureDetector(
                onDoubleTap: () {
                  FireStoreMethods().likePost(
                    widget.snap['postId'].toString(),
                    user.uid,
                    widget.snap['likes'],
                  );
                  setState(() {
                    // Handle double-tap animation if needed
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.35,
                      width: double.infinity,
                      child: Image.network(
                        widget.snap['postUrl'].toString(),
                        fit: BoxFit.cover,
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity:
                          // ignore: dead_code
                          false ? 1 : 0, // Adjust animation condition if needed
                      child: LikeAnimation(
                        isAnimating:
                            false, // Adjust animation condition if needed
                        duration: const Duration(
                          milliseconds: 400,
                        ),
                        onEnd: () {
                          setState(() {
                            // Handle animation end if needed
                          });
                        },
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 100,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // LIKE, COMMENT SECTION OF THE POST
              Row(
                children: <Widget>[
                  LikeAnimation(
                    isAnimating: commonSnap['likes'].contains(user.uid),
                    smallLike: true,
                    child: IconButton(
                      icon: commonSnap['likes'].contains(user.uid)
                          ? const Icon(
                              Icons.favorite,
                              color: Colors.red,
                            )
                          : const Icon(
                              Icons.favorite_border,
                            ),
                      onPressed: () =>
                          likePost(commonSnap!), // Pass commonSnap to likePost
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.comment_outlined,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CommentsScreen(
                          postId: widget.snap['postId'].toString(),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: FutureBuilder<bool>(
                        future: FireStoreMethods().isPostInFavorites(
                          user.uid,
                          widget.snap['postId'].toString(),
                          context,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            bool isFavorite = snapshot.data ?? false;

                            return IconButton(
                              icon: isFavorite
                                  ? const Icon(Icons.bookmark)
                                  : const Icon(Icons.bookmark_border),
                              onPressed: () async {
                                bool isCurrentlyFavorite =
                                    await FireStoreMethods().isPostInFavorites(
                                  user.uid,
                                  widget.snap['postId'].toString(),
                                  context,
                                );

                                if (isCurrentlyFavorite) {
                                  await FireStoreMethods().removeFromFavorites(
                                    user.uid,
                                    widget.snap['postId'].toString(),
                                    context,
                                  );
                                } else {
                                  await FireStoreMethods().addToFavourite(
                                    user.uid,
                                    widget.snap['postId'].toString(),
                                    context,
                                  );
                                }

                                setState(() {
                                  isFavorite = !isCurrentlyFavorite;
                                });
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              //DESCRIPTION AND NUMBER OF COMMENTS
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
                        '${commonSnap['likes'].length} likes',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        top: 8,
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: primaryColor),
                          children: [
                            TextSpan(
                              text: commonSnap['username'].toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' ${commonSnap['description']}'),
                          ],
                        ),
                      ),
                    ),
                    FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(widget.snap['postId'])
                          .collection('comments')
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          commentLen = 0;

                          return Text(
                            'View all $commentLen comments',
                            style: const TextStyle(
                              fontSize: 16,
                              color: secondaryColor,
                            ),
                          );
                        } else {
                          commentLen = snapshot.data!.docs.length;

                          return InkWell(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
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
                                  postId: commonSnap!['postId'].toString(),
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        DateFormat.yMMMd()
                            .format(commonSnap['datePublished'].toDate()),
                        style: const TextStyle(
                          color: secondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  likePost(QueryDocumentSnapshot<Map<String, dynamic>> snap) async {
    if (!mounted) {
      return;
    }

    User user = _auth.currentUser!;
    FireStoreMethods().likePost(
      snap.id,
      user.uid,
      snap['likes'],
    );
    if (mounted) {
      setState(() {});
    }
  }

  deletePost(String postId) async {
    try {
      await FireStoreMethods().deletePost(postId);
    } catch (err) {
      showSnackBar(
        context,
        err.toString(),
      );
    }
  }
}
