import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:notality/models/text_note.dart';
import 'package:notality/screens/note_edit.dart';
import 'package:notality/screens/note_list.dart';
import 'package:notality/services/notes_service.dart';
import 'package:notality/widgets/app_bar.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:universal_html/html.dart' as web;

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

  static const _themeColorDark = Color.fromRGBO(0x03, 0x7F, 0x35, 1.0);
  static const _secondaryColorDark = Color.fromRGBO(0x03, 0x84, 0x37, 1.0);

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
          primary: _themeColorDark,
          secondary: _secondaryColorDark,
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
    try {
      var newNote = await Navigator.of(context).push(MaterialPageRoute<Note>(
        builder: (context) => NoteEditPage(Note.empty(), true),
      ));

      if (newNote == null) {
        return;
      }

      await widget.service.addNote(newNote);
    } catch (e) {
      await _showErrorMessage(context, e);
    }
  }

  void _sortNotesByDate() async {
    try {
      var _notes = await widget.service.readNotes();

      _notes.sort((a, b) {
        return b.lastEditDate.compareTo(a.lastEditDate);
      });

      await widget.service.writeNotes(_notes);
    } catch (e) {
      await _showErrorMessage(context, e);
    }

    setState(() {});
  }

  Future<void> _showErrorMessage(BuildContext context, dynamic e) async {
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
      var _notes = await widget.service.readNotes();

      var json = notesFileContentToJson(NotesFileContent(notes: _notes));

      var now = DateTime.now();

      final exportFn = "notality_${now.year}-${now.month}-${now.day}.json";
      if (kIsWeb) {
        web.AnchorElement()
          ..href =
              '${Uri.dataFromString(json, mimeType: 'application/json', encoding: utf8)}'
          ..download = exportFn
          ..style.display = 'none'
          ..click();
      } else {
        await FlutterFileDialog.saveFile(
          params: SaveFileDialogParams(
            fileName: exportFn,
            data: Uint8List.fromList(utf8.encode(json)),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.exportSuccessful),
      ));
    } catch (e) {
      await _showErrorMessage(context, e);
    }
  }

  void _importFromFile() async {
    try {
      String content;
      if (kIsWeb) {
        FilePickerResult? result = await FilePicker.platform.pickFiles();
        if (result == null) {
          return;
        }
        content = utf8.decode(result.files.first.bytes ?? []);
      } else {
        var fp = await FlutterFileDialog.pickFile(
          params: const OpenFileDialogParams(
            copyFileToCacheDir: true,
          ),
        );
        if (fp == null) {
          return;
        }

        content = await File(fp).readAsString();
      }

      var _notes = notesFileContentFromJson(content).notes;
      if (_notes.isEmpty) {
        throw Exception(AppLocalizations.of(context)!.emptyFileImport);
      }

      var ok = await showDialog<bool?>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.import),
          content: Text(
            _notes.length == 1
                ? AppLocalizations.of(context)!.importSingle
                : AppLocalizations.of(context)!.importMultiple(_notes.length),
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

      await widget.service.writeNotes(_notes);

      // let the UI reload the notes
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.importSuccessful),
      ));
    } catch (e) {
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
                )
              ];
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.publish),
                      Text(AppLocalizations.of(context)!.exportToFile),
                    ],
                  ),
                  onTap: _exportToFile,
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.download),
                      Text(AppLocalizations.of(context)!.importFromFile),
                    ],
                  ),
                  onTap: _importFromFile,
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
