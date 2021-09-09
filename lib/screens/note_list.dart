import 'package:flutter/material.dart';
import 'package:notality/models/text_note.dart';

class NoteList extends StatefulWidget {
  NoteList(this.notes);

  List<Note> notes;

  @override
  _NoteListState createState() => _NoteListState();
}

class _NoteListState extends State<NoteList> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: null,
    );
  }
}
