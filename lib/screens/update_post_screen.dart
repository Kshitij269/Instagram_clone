import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instagram_clone/utils/utils.dart';

class UpdatePostScreen extends StatefulWidget {
  final String postId;
  final String currentDescription;
  final String postImageUrl;

  const UpdatePostScreen({
    Key? key,
    required this.postId,
    required this.currentDescription,
    required this.postImageUrl,
  }) : super(key: key);

  @override
  _UpdatePostScreenState createState() => _UpdatePostScreenState();
}

class _UpdatePostScreenState extends State<UpdatePostScreen> {
  TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize the controller with the current description
    _descriptionController.text = widget.currentDescription;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Update Post'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.network(
                widget.postImageUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'New Description'),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.postId)
                        .update({'description': _descriptionController.text});
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    setState(() {
                      showSnackBar(context, "Post Updated Successfully");
                    });
                  },
                  child: Text('Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
