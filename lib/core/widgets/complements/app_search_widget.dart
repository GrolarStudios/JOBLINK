import 'package:flutter/material.dart';

class AppSearchWidget extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String hintText;

  const AppSearchWidget({
    super.key,
    required this.onChanged,
    required this.hintText,
  });

  @override
  AppSearchWidgetState createState() => AppSearchWidgetState();
}

class AppSearchWidgetState extends State<AppSearchWidget> {
  final TextEditingController _controller = TextEditingController();

  void _clearText() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 10.0,
            ),
          ),
        ),
        Positioned(
          right: 10,
          child: IconButton(
            icon: const Icon(Icons.clear, color: Colors.red),
            onPressed: _clearText,
          ),
        ),
      ],
    );
  }
}
