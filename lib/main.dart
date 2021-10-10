import 'package:flutter/material.dart';
import 'package:notality/models/text_note.dart';
import 'package:notality/screens/note_edit.dart';
import 'package:notality/screens/note_list.dart';
import 'package:notality/services/notes_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

// timeTranslations contains the mapping of locales to timeago translations
final timeTranslations = <String, timeago.LookupMessages>{
  'en': timeago.EnMessages(),
  'de': timeago.DeMessages(),
};

void main() {
  runApp(NotesApp());
}

class NotesApp extends StatelessWidget {
  NotesApp({Key? key}) : super(key: key) {
    // Load all translation locales
    timeTranslations.forEach((locale, messages) {
      timeago.setLocaleMessages(locale, messages);
    });
  }

  static const _themeColor = Color.fromRGBO(0x04, 0x9E, 0x42, 1.0);
  static const _secondaryColor = Color.fromRGBO(0x05, 0xC6, 0x53, 1.0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notality',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.from(
        colorScheme: const ColorScheme.light().copyWith(
          brightness: Brightness.light,
          primary: _themeColor,
          secondary: _secondaryColor,
          surface: Colors.grey[200],
        ),
        textTheme: Typography.blackHelsinki.copyWith(
          bodyText2: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
      darkTheme: ThemeData.from(
        colorScheme: const ColorScheme.dark().copyWith(
          brightness: Brightness.dark,
          primary: _themeColor,
          secondary: _secondaryColor,
          surface: Colors.grey[900],
        ),
        textTheme: Typography.whiteHelsinki.copyWith(
          bodyText2: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
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

    widget.service.addInsertCallback((index) => setState(() {}));
    widget.service.addRemoveCallback((index) => setState(() {}));
  }

  void _createNewNote() async {
    var newNote = await Navigator.of(context).push(MaterialPageRoute<Note>(
      builder: (context) => NoteEditPage(Note.empty(), true),
    ));

    if (newNote == null) {
      return;
    }

    widget.service.addNote(newNote);
  }

  void _sortNotesByDate() async {
    var _notes = await widget.service.readNotes();

    _notes.sort((a, b) {
      return b.lastEditDate.compareTo(a.lastEditDate);
    });

    await widget.service.writeNotes(_notes);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notality"),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.sort),
            tooltip: AppLocalizations.of(context)!.sortNotesToolTip,
            padding: EdgeInsets.zero,
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    // This button must be full width of the popupmenuitem, else it looks weird when pressing long
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _sortNotesByDate,
                      icon: const Icon(Icons.schedule),
                      label: Text(AppLocalizations.of(context)!.sortByDate),
                    ),
                  ),
                  onTap: () {},
                )
              ];
            },
          ),
        ],
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
        onPressed: _createNewNote,
        tooltip: AppLocalizations.of(context)!.addNoteToolTip,
        child: const Icon(Icons.add),
      ),
    );
  }
}
