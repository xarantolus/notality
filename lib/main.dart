import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:notality/l10n/app_localizations.dart';
import 'package:notality/models/text_note.dart';
import 'package:notality/screens/note_edit.dart';
import 'package:notality/screens/note_list.dart';
import 'package:notality/services/notes_service.dart';
import 'package:notality/widgets/app_bar.dart';
import 'package:timeago/timeago.dart' as timeago;

// timeTranslations contains the mapping of locales to timeago translations
final timeTranslations = <String, timeago.LookupMessages>{
  'en': timeago.EnMessages(),
  'de': timeago.DeMessages(),
};

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Opt in to edge-to-edge explicitly so every supported Android version
  // lays out the same way, rather than only 15+ (which forces it anyway).
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));

  runApp(NotesApp());
}

class NotesApp extends StatelessWidget {
  NotesApp({super.key}) {
    // Load all translation locales
    timeTranslations.forEach((locale, messages) {
      timeago.setLocaleMessages(locale, messages);
    });
  }

  static const _seed = Color.fromRGBO(0x04, 0x9E, 0x42, 1.0);

  /// The app bar states its green rather than taking a role from the scheme.
  /// M3 derives a tonal palette from the seed, and every tone it offers is
  /// either desaturated or, in a dark scheme, pale enough to sit as a bright
  /// block above a dark page.
  static const _barColor = _seed;
  static const _barColorDark = Color.fromRGBO(0x03, 0x7F, 0x35, 1.0);

  static ThemeData _themeFor(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final dark = brightness == Brightness.dark;

    return ThemeData(
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? _barColorDark : _barColor,
        // White clears 3:1 on both greens, which is the bar for the large
        // title and the icons; nothing small is drawn on the bar.
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notality',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _themeFor(Brightness.light),
      darkTheme: _themeFor(Brightness.dark),
      home: NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  NotesPage({super.key});

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
    try {
      var newNote = await Navigator.of(context).push(
        MaterialPageRoute<Note>(
          builder: (context) => NoteEditPage(Note.empty(), true),
        ),
      );

      if (newNote == null) {
        return;
      }

      await widget.service.addNote(newNote);
    } catch (e) {
      if (!mounted) return;
      await _showErrorMessage(context, e);
    }
  }

  void _sortNotesByDate() async {
    try {
      var notes = await widget.service.readNotes();

      notes.sort((a, b) {
        return b.lastEditDate.compareTo(a.lastEditDate);
      });

      await widget.service.writeNotes(notes);
    } catch (e) {
      if (!mounted) return;
      await _showErrorMessage(context, e);
    }

    setState(() {});
  }

  Future<void> _showErrorMessage(BuildContext context, Object e) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.errorTitle),
          content: Text(e.toString()),
        );
      },
    );
  }

  void _exportToFile() async {
    try {
      var notes = await widget.service.readNotes();

      var json = notesFileContentToJson(NotesFileContent(notes: notes));

      var now = DateTime.now();

      await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          fileName: "notality_${now.year}-${now.month}-${now.day}.json",
          data: Uint8List.fromList(utf8.encode(json)),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.exportSuccessful)),
      );
    } catch (e) {
      if (!mounted) return;
      await _showErrorMessage(context, e);
    }
  }

  void _importFromFile() async {
    var fp = await FlutterFileDialog.pickFile(
      params: const OpenFileDialogParams(copyFileToCacheDir: true),
    );
    if (fp == null) {
      return;
    }

    try {
      var content = await File(fp).readAsString();

      if (!mounted) return;

      var notes = notesFileContentFromJson(content).notes;
      if (notes.isEmpty) {
        throw Exception(AppLocalizations.of(context)!.emptyFileImport);
      }

      var ok = await showDialog<bool?>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.import),
          content: Text(
            notes.length == 1
                ? AppLocalizations.of(context)!.importSingle
                : AppLocalizations.of(context)!.importMultiple(notes.length),
          ),
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancelText),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.continueText),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        ),
      );
      if (ok != true) {
        return;
      }

      await widget.service.writeNotes(notes);

      if (!mounted) return;

      // let the UI reload the notes
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.importSuccessful)),
      );
    } catch (e) {
      if (!mounted) return;
      await _showErrorMessage(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = Theme.of(context).brightness == Brightness.light;
    final appIcon = ImageIcon(
      lightTheme
          ? const AssetImage("assets/icon/Icon-Outline-Dark.png")
          : const AssetImage("assets/icon/Icon-Outline-Light.png"),
    );

    return Scaffold(
      appBar: CustomAppBar.create(
        context,
        title: "Notality",
        titleStyle: const TextStyle(fontWeight: FontWeight.w900),
        icon: appIcon,
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
                ),
              ];
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  onTap: _exportToFile,
                  child: Row(
                    children: [
                      const Icon(Icons.publish),
                      Text(AppLocalizations.of(context)!.exportToFile),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: _importFromFile,
                  child: Row(
                    children: [
                      const Icon(Icons.download),
                      Text(AppLocalizations.of(context)!.importFromFile),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: NoteList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewNote,
        tooltip: AppLocalizations.of(context)!.addNoteToolTip,
        child: const Icon(Icons.add),
      ),
    );
  }
}
