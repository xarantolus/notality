import 'package:flutter/material.dart';
import 'package:notality/models/text_note.dart';

class NoteCard extends StatefulWidget {
  NoteCard({Key? key, required this.note}) : super(key: key);

  final Note note;

  @override
  _NoteCardState createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(widget.note.title),
      ),
    );
  }
}
