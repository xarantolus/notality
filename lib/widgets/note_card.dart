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
      padding: const EdgeInsets.all(2),
      child: Container(
        color: Theme.of(context).backgroundColor,
        child: Align(
          alignment: Alignment.topLeft,
          child: ListTile(
            title: Container(
              child: Text(
                widget.note.title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              padding: const EdgeInsets.all(4),
            ),
            subtitle: Container(
              child: Text(
                widget.note.text,
                style: const TextStyle(fontSize: 15),
              ),
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
            ),
          ),
        ),
      ),
    );
  }
}
