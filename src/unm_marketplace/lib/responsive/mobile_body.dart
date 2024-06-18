import 'package:flutter/material.dart';

class MyMobileBody extends StatelessWidget {
  const MyMobileBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[200],
      body: Column(
        children: [
          // Advertisement container
          Container(
            width: 400, // Set the width to 400 pixels
            height: 200, // Set the height as desired
            color: Colors.orange, // Set the color of the container
            child: Center(
              child: Text(
                'Advertisement', // Placeholder for advertisement content
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // youtube video
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.deepPurple[500],
            ),
          ),

          // comment section & recommended videos
        ],
      ),
    );
  }
}
