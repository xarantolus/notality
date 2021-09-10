import 'package:flutter/material.dart';
import 'package:notality/models/text_note.dart';
import 'package:notality/screens/note_edit.dart';
import 'package:notality/screens/note_list.dart';
import 'package:notality/services/notes_service.dart';

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notality',
      theme: ThemeData.from(
        colorScheme: const ColorScheme.light().copyWith(
          brightness: Brightness.light,
          primary: Colors.amber,
          secondary: Colors.amberAccent,
          surface: Colors.grey[300],
        ),
      ),
      darkTheme: ThemeData.from(
        colorScheme: const ColorScheme.dark().copyWith(
          brightness: Brightness.dark,
          primary: Colors.amber,
          secondary: Colors.amberAccent,
          surface: Colors.grey[900],
        ),
      ),
      home: NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  NotesPage({Key? key}) : super(key: key);

  List<Note>? notes;

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notality"),
      ),
      body: FutureBuilder<List<Note>>(
        future:
            Future.delayed(const Duration(seconds: 3), NotesService.readNotes),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            widget.notes = snapshot.data!;

            return NoteList(snapshot.data!);
          } else {
            // Just a loading scren
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var newNote = await Navigator.of(context).push(
              MaterialPageRoute<Note>(
                  builder: (context) => NoteEditPage(Note.empty())));

          // Don't save empty notes
          if (newNote!.text.isEmpty && newNote.title.isEmpty) {
            return;
          }

          widget.notes!.insert(0, newNote);

          await NotesService.writeNotes(widget.notes!);

          // Make sure the futureBuilder gets updated notes data; it does reload from disk though
          setState(() {});
        },
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
