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
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.fromSwatch(
          accentColor: Colors.amber,
        ),
        primaryColor: Colors.red,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.amber,
        backgroundColor: Colors.black45,
        primaryColor: Colors.red,
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
        future: NotesService.readNotes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            widget.notes = snapshot.data!;

            return NoteList(snapshot.data!);
          } else {
            // Just a loading scren
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var newNote = await Navigator.of(context).push(
              MaterialPageRoute<Note>(
                  builder: (context) => NoteEditPage(Note.empty())));

          widget.notes!.add(newNote!);

          await NotesService.writeNotes(widget.notes!);

          // Make sure the futureBuilder gets updated notes data; it does reload from disk though
          setState(() {});
        },
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
