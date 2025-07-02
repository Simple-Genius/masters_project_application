import 'package:flutter/material.dart';

Widget buildTypingIndicator() {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.smart_toy, color: Colors.white),
        ),
        const SizedBox(width: 8.0),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14.0),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(18.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                'Typing...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
