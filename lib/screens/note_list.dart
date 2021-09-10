import 'package:flutter/material.dart';
import 'package:notality/models/text_note.dart';
import 'package:notality/screens/note_edit.dart';
import 'package:notality/services/notes_service.dart';
import 'package:notality/widgets/note_card.dart';

class NoteList extends StatefulWidget {
  NoteList(this.service);

  NotesService service;

  @override
  _NoteListState createState() => _NoteListState();
}

class _NoteListState extends State<NoteList> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<List<Note>>(
        future: widget.service.readNotes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return const Center(child: Text("Nothing to see here..."));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data![index];

                  return GestureDetector(
                    onTap: () async {
                      var editedNote = await Navigator.of(context).push(
                          MaterialPageRoute<Note>(
                              builder: (context) => NoteEditPage(item, false)));
                      if (editedNote == null) {
                        return;
                      }

                      await widget.service.replaceNote(editedNote, index);
                    },
                    child: Dismissible(
                      key: UniqueKey(),

                      child: NoteCard(note: item),

                      // Allow swiping left or right
                      direction: DismissDirection.horizontal,

                      background: Container(
                        color: Colors.red,
                        child: const Icon(Icons.delete_forever),
                      ),

                      onDismissed: (direction) async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Deleted note'),
                            action: SnackBarAction(
                              label: "Restore",
                              onPressed: () {
                                widget.service.addNote(item, index);
                              },
                            ),
                          ),
                        );

                        widget.service.deleteNote(index);
                      },
                    ),
                  );
                },
              );
            }
          } else if (snapshot.hasError) {
            return ErrorWidget(snapshot.error!);
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
