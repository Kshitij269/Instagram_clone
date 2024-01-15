import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:instagram_clone/models/post.dart';
import 'package:instagram_clone/resources/storage_methods.dart';
import 'package:instagram_clone/utils/utils.dart';
import 'package:uuid/uuid.dart';

class FireStoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadPost(String description, Uint8List file, String uid,
      String username, String profImage) async {
    String res = "Some error occurred";
    try {
      String photoUrl =
          await StorageMethods().uploadImageToStorage('posts', file, true);
      String postId = const Uuid().v1(); // creates unique id based on time
      Post post = Post(
        description: description,
        uid: uid,
        username: username,
        likes: [],
        postId: postId,
        datePublished: DateTime.now(),
        postUrl: photoUrl,
        profImage: profImage,
      );
      _firestore.collection('posts').doc(postId).set(post.toJson());
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<bool> isPostInFavorites(
    String userId,
    String postId,
    BuildContext context,
  ) async {
    try {
      DocumentSnapshot favoriteDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(postId)
          .get();

      return favoriteDoc.exists;
    } catch (error) {
      showSnackBar(context, "Error checking favorites: $error");
      return false;
    }
  }

  Future<void> removeFromFavorites(
    String userId,
    String postId,
    BuildContext context,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(postId)
          .delete();
      showSnackBar(context, "Item is Removed From Favourite");
    } catch (error) {
      showSnackBar(context, "Error removing from favorites: $error");
    }
  }

  Future<String> likePost(String postId, String uid, List likes) async {
    String res = "Some error occurred";
    try {
      DocumentSnapshot postSnapshot =
          await _firestore.collection('posts').doc(postId).get();

      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(uid).get();

      String postOwnerUid = postSnapshot['uid'];

      if (likes.contains(uid)) {
        _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid])
        });
        if (uid != postOwnerUid) {
          _firestore
              .collection('users')
              .doc(postOwnerUid)
              .collection('notifications')
              .add({
            'type': 'like',
            'postUrl': postSnapshot['postUrl'],
            'username': userSnapshot['username'],
            'postName': postSnapshot['description'],
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });
        }
      }
      res = 'success';
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<String> postComment(String postId, String text, String uid,
      String name, String profilePic) async {
    String res = "Some error occurred";
    try {
      if (text.isNotEmpty) {
        String commentId = const Uuid().v1();

        DocumentSnapshot postSnapshot =
            await _firestore.collection('posts').doc(postId).get();

        DocumentSnapshot userSnapshot =
            await _firestore.collection('users').doc(uid).get();

        String postOwnerUid = postSnapshot['uid'];

        _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .set({
          'profilePic': profilePic,
          'name': name,
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'datePublished': DateTime.now(),
        });

        if (uid != postOwnerUid) {
          _firestore
              .collection('users')
              .doc(postOwnerUid)
              .collection('notifications')
              .add({
            'type': 'commente',
            'postUrl': postSnapshot['postUrl'],
            'username': userSnapshot['username'],
            'postName': postSnapshot['description'],
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });
        }

        res = 'success';
      } else {
        res = "Please enter text";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<void> addToFavourite(
      String uid, String postId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(postId)
          .set({'postId': postId});

      showSnackBar(context, "Item Added To Favourite");
    } catch (err) {
      showSnackBar(context, "Some Error Occured");
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get()
          .then(
        (querySnapshot) {
          querySnapshot.docs.forEach((doc) {
            doc.reference.delete();
          });
        },
      );
    } catch (err) {
      throw err;
    }
  }

  Future<void> followUser(String uid, String followId) async {
    try {
      DocumentSnapshot snap =
          await _firestore.collection('users').doc(uid).get();
      List following = (snap.data()! as dynamic)['following'];

      if (following.contains(followId)) {
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid])
        });

        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayRemove([followId])
        });
      } else {
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayUnion([uid])
        });

        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayUnion([followId])
        });
      }
    } catch (e) {
      if (kDebugMode) print(e.toString());
    }
  }

  Future<void> removefromfollowing(String uid, String followId) async {
    try {
      DocumentSnapshot snap =
          await _firestore.collection('users').doc(followId).get();
      List followers = (snap.data()! as dynamic)['followers'];

      if (followers.contains(uid)) {
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid])
        });

        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayRemove([followId])
        });
      }
    } catch (e) {
      if (kDebugMode) print(e.toString());
    }
  }

  Future<void> removefromfollowers(String uid, String followId) async {
    try {
      DocumentSnapshot snap =
          await _firestore.collection('users').doc(uid).get();
      List following = (snap.data()! as dynamic)['following'];

      if (following.contains(followId)) {
        await _firestore.collection('users').doc(followId).update({
          'followers': FieldValue.arrayRemove([uid])
        });

        await _firestore.collection('users').doc(uid).update({
          'following': FieldValue.arrayRemove([followId])
        });
      }
    } catch (e) {
      if (kDebugMode) print(e.toString());
    }
  }
}
