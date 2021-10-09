import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:notality/models/text_note.dart';
import 'package:notality/screens/note_edit.dart';
import 'package:notality/services/notes_service.dart';
import 'package:notality/widgets/note_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

    // We want to notify the AnimatedList when an item was added or removed
    widget.service.addInsertCallback((index) {
      if (widget._listKey.currentState == null) {
        // The list is not yet displayed, e.g. because there are 0 items
        setState(() {});
      } else {
        widget._listKey.currentState!.insertItem(index);
      }
    });

    widget.service.addRemoveCallback(
      (index) => widget._listKey.currentState?.removeItem(index,
          (BuildContext context, Animation<double> animation) {
        return Container();
      }),
    );
  }

  // _editNote pops up the node editing screen and saves/replaces the note
  void _editNote(int index, Note item) async {
    var editedNote = await Navigator.of(context).push(MaterialPageRoute<Note>(
        builder: (context) => NoteEditPage(item, false)));
    if (editedNote == null) {
      return;
    }

    await widget.service.replaceNote(editedNote, index);
  }

  void _deleteNote(int index, BuildContext context, Note item) {
    widget.service.deleteNote(index);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.deletedNote),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.deletedNoteRestore,
          onPressed: () {
            widget.service.addNote(item, index);
          },
        ),
      ),
    );
  }

  // _animatedList creates the animated list with its transitions
  Widget _itemList(List<Note> items) {
    return Theme(
      // This theme data change makes sure that the edges around the cards
      // are not dragged around with, else we also move the padded background,
      // which is really ugly
      data: Theme.of(context).copyWith(
        canvasColor: Colors.transparent,
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        dialogBackgroundColor: Colors.transparent,
      ),
      child: ReorderableListView.builder(
        key: widget._listKey,
        itemCount: items.length,
        onReorder: (int from, int to) async {
          await widget.service.reorderNote(from, to);
        },
        itemBuilder: (context, index) {
          final item = items[index];

          return _listCard(index, item, context);
        },
      ),
    );
  }

  // _listCard returns the list card with editing and swiping capability
  GestureDetector _listCard(int index, Note item, BuildContext context) {
    return GestureDetector(
      key: ValueKey(index),
      onTap: () => _editNote(index, item),
      child: Container(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 6),
        child: _dismissibleListCard(item, context, index),
      ),
    );
  }

  // _dismissibleListCard returns a list card that can be swiped away
  Dismissible _dismissibleListCard(Note item, BuildContext context, int index) {
    return Dismissible(
      key: ValueKey(index),

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

      // The background behind the list item is a trash can
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
        _deleteNote(index, context, item);
      },
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
              return Center(
                  child: Text(AppLocalizations.of(context)!.emptyListHint));
            } else {
              return _itemList(snapshot.data!);
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
