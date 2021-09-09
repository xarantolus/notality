import 'package:flutter/material.dart';
import 'package:notality/models/text_note.dart';
import 'package:notality/widgets/note_card.dart';

class NoteList extends StatefulWidget {
  NoteList(this.notes);

  List<Note> notes;

  @override
  _NoteListState createState() => _NoteListState();
}

class _NoteListState extends State<NoteList> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView.builder(
        itemCount: widget.notes.length,
        itemBuilder: (context, index) {
          return Center(child: NoteCard(note: widget.notes[index]));
        },
      ),
    );
  }
}
