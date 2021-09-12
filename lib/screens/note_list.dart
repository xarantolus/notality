import 'package:flutter/material.dart';
import 'package:notality/models/text_note.dart';
import 'package:notality/screens/note_edit.dart';
import 'package:notality/services/notes_service.dart';
import 'package:notality/widgets/note_card.dart';

class NoteList extends StatefulWidget {
  NoteList({Key? key}) : super(key: key);

  final service = NotesService();

  final _listKey = GlobalKey<AnimatedListState>();

  @override
  _NoteListState createState() => _NoteListState();
}

class _NoteListState extends State<NoteList> {
  @override
  void initState() {
    super.initState();

    widget.service.addInsertCallback(
        (index) => widget._listKey.currentState!.insertItem(index));

    widget.service.addRemoveCallback(
      (index) => widget._listKey.currentState!.removeItem(index,
          (BuildContext context, Animation<double> animation) {
        return Container();
      }),
    );
  }

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
              return AnimatedList(
                key: widget._listKey,
                initialItemCount: snapshot.data!.length,
                itemBuilder: (context, index, anim) {
                  final item = snapshot.data![index];

                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1, 0),
                      end: Offset(0, 0),
                    ).animate(anim),
                    child: GestureDetector(
                      onTap: () async {
                        var editedNote = await Navigator.of(context).push(
                            MaterialPageRoute<Note>(
                                builder: (context) =>
                                    NoteEditPage(item, false)));
                        if (editedNote == null) {
                          return;
                        }

                        await widget.service.replaceNote(editedNote, index);
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.only(left: 8, right: 8, top: 6),
                        child: Dismissible(
                          key: UniqueKey(),

                          child: Container(
                            child: NoteCard(note: item),
                            decoration: ShapeDecoration(
                              color: Theme.of(context).cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                          // Allow swiping left or right
                          direction: DismissDirection.horizontal,

                          background: Container(
                            child: const Icon(Icons.delete_forever),
                            padding: const EdgeInsets.only(
                              left: 8,
                              right: 8,
                              top: 6,
                            ),
                            decoration: ShapeDecoration(
                              color: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),

                          onDismissed: (direction) async {
                            widget.service.deleteNote(index);

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
                          },
                        ),
                      ),
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
