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
          surface: Colors.grey[200],
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

  final NotesService service = NotesService();

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  @override
  void initState() {
    super.initState();

    // Let the notes service call setState whenever the notes are updated
    widget.service.setCallback(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notality"),
      ),
      body: FutureBuilder<List<Note>>(
        future: widget.service.readNotes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return NoteList();
          } else if (snapshot.hasError) {
            return ErrorWidget(snapshot.error!);
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
                  builder: (context) => NoteEditPage(Note.empty(), true)));

          if (newNote == null) {
            return;
          }

          widget.service.addNote(newNote);
        },
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ),
    );
  }
}
