import 'package:flutter/material.dart';
import 'package:notality/models/text_note.dart';
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
        primarySwatch: Colors.amber,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: const NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({Key? key}) : super(key: key);

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
              return NoteList(snapshot.data!);
            } else {
              // Just a loading scren
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: Colors.green,
                  ),
                ),
              );
            }
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {},
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
