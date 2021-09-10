import 'package:flutter/material.dart';
import 'package:notality/models/text_note.dart';
import 'package:notality/services/notes_service.dart';
import 'package:notality/widgets/note_card.dart';

class NoteList extends StatefulWidget {
  NoteList(this.service, this.notes);

  NotesService service;

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
          final item = widget.notes[index];

          return Dismissible(
            key: UniqueKey(),
            child: NoteCard(note: item),

            // Allow swiping left or right
            direction: DismissDirection.horizontal,

            background: Container(
              color: Colors.red,
              child: const Icon(Icons.delete_forever),
            ),

            onDismissed: (direction) async {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$index dismissed'),
                action: SnackBarAction(
                  label: "Undo",
                  onPressed: () {
                    setState(() {
                      widget.service.addNote(item, index);
                    });
                  },
                ),
              ));

              setState(() {
                widget.service.deleteNote(index);
              });
            },
          );
        },
      ),
    );
  }
}
