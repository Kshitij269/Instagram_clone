import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:instagram_clone/widgets/search_screen_postcard.dart';

class FavouriteScreen extends StatefulWidget {
  final String uid;
  const FavouriteScreen({super.key, required this.uid});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Favourites"),
          centerTitle: true,
        ),
        body: FutureBuilder(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .collection('favorites')
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // Fetch details for each favorite post
            var favoritePosts = (snapshot.data! as QuerySnapshot).docs;

            // Create a list of futures for fetching post details
            var postDetailFutures = favoritePosts.map((favoritePost) async {
              var postId = favoritePost['postId'];

              var postDetails = await FirebaseFirestore.instance
                  .collection(
                      'posts') // Assuming your posts collection name is 'posts'
                  .doc(postId)
                  .get();
              return postDetails;
            }).toList();

            return FutureBuilder(
              // Wait for all post details futures to complete
              future: Future.wait(postDetailFutures),
              builder: (context, postDetailsSnapshot) {
                if (!postDetailsSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Material(
                    child: MasonryGridView.count(
                      crossAxisCount: 3,
                      itemCount: postDetailsSnapshot.data!.length,
                      itemBuilder: (context, index) {
                        var postDetail = postDetailsSnapshot.data![index];
                        return Material(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                return Scaffold(
                                  appBar: AppBar(
                                    centerTitle: true,
                                    title: const Text('Post Details'),
                                  ),
                                  body: SearchCard(
                                    snap: postDetail,
                                  ),
                                );
                              }),
                            ),
                            child: Image.network(
                              postDetail['postUrl'],
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ));
  }
}
