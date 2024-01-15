import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('notifications')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          var notifications = snapshot.data?.docs;
          return ListView.builder(
            physics: BouncingScrollPhysics(),
            itemCount: notifications?.length ?? 0,
            itemBuilder: (context, index) {
              var notification =
                  notifications?[index].data() as Map<String, dynamic>;
              print(notification);

              DateTime inputDate = DateTime.fromMillisecondsSinceEpoch(
                  (notification['timestamp'] as Timestamp)
                      .millisecondsSinceEpoch);

              String formattedDate =
                  DateFormat("dd/MM/yy h:mm a").format(inputDate);

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 15,vertical:10),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${notification['username']} has ${notification['type']}d on your post ${notification['postName']}",
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            "$formattedDate",
                            textAlign: TextAlign.left,
                            style: TextStyle(color: Colors.grey),
                          )
                        ],
                      ),
                      Image.network(
                        notification!['postUrl'],
                        height: 80,
                      ),
                    ]),
              );
            },
          );
        },
      ),
    );
  }
}
