import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'package:notality/l10n/app_localizations.dart';
import 'package:notality/models/note_text.dart';
import 'package:notality/models/text_note.dart';
import 'package:notality/widgets/app_bar.dart';

class NoteEditPage extends StatefulWidget {
  const NoteEditPage(this.note, this.autofocus, {super.key});

  final Note note;
  final bool autofocus;

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  TextEditingController? titleController;
  TextEditingController? bodyController;

  String? _initialTitle;
  String? _initialText;
  Timer? _timer;

  DateTime? editedDate;

  @override
  void initState() {
    super.initState();

    if (!widget.note.isEmpty()) {
      _initialTitle = widget.note.title;
      _initialText = widget.note.text;
    }

    titleController = TextEditingController.fromValue(
      TextEditingValue(text: widget.note.title),
    );
    titleController!.addListener(() {
      setState(() {});
    });

    bodyController = TextEditingController.fromValue(
      TextEditingValue(text: widget.note.text),
    );
    bodyController!.addListener(() {
      setState(() {});
    });

    // Make sure the displayed edit time syncs with the system clock
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer!.cancel();

    titleController!.dispose();
    bodyController!.dispose();

    super.dispose();
  }

  String formatDate(DateTime d) {
    final localization = AppLocalizations.of(context)!;

    final DateFormat formatter = DateFormat(
      MediaQuery.of(context).alwaysUse24HourFormat
          ? localization.dateTimeFormat24h
          : localization.dateTimeFormat,
      localization.localeName,
    );

    return formatter.format(d);
  }

  bool get _hasChanged =>
      editedDate != null ||
      _initialText != bodyController!.text.trim() ||
      titleController!.text.trim() != _initialTitle;

  void _onLeave() {
    var newNote = Note(
      type: "text",
      lastEditDate: _noteDate,
      title: titleController!.text.trim(),
      text: bodyController!.text.trim(),
    );

    // If we didn't edit anything, we return null; else we return our note
    if (newNote.text.isEmpty && newNote.title.isEmpty || !_hasChanged) {
      Navigator.pop(context, null);
    } else {
      Navigator.pop(context, newNote);
    }
  }

  Future<void> _pickDateAndTime(BuildContext context) async {
    var now = _noteDate;

    var date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );

    if (!context.mounted) return;

    var tod = TimeOfDay(hour: now.hour, minute: now.minute);
    var time = await showTimePicker(context: context, initialTime: tod);

    // If we clicked behind/cancelled all dialogs
    if (date == null && time == null) {
      return;
    }

    // Construct the date + time from both selected values
    var resultDayAndTime = date ?? DateTime(now.year, now.month, now.day);
    if (time != null) {
      resultDayAndTime = resultDayAndTime.add(
        Duration(hours: time.hour, minutes: time.minute),
      );
    }

    setState(() {
      editedDate = resultDayAndTime;
    });
  }

  DateTime get _noteDate =>
      _hasChanged ? (editedDate ?? DateTime.now()) : widget.note.lastEditDate;

  bool get _hasContentToSave =>
      titleController!.text.trim().isNotEmpty ||
      bodyController!.text.trim().isNotEmpty;

  Future<void> _saveAsTextFile() async {
    final title = titleController!.text.trim();
    final body = bodyController!.text.trim();

    try {
      final path = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          fileName: noteFileName(title, _noteDate),
          data: Uint8List.fromList(utf8.encode(noteAsText(title, body))),
          mimeTypesFilter: ['text/plain'],
        ),
      );

      if (!mounted) return;

      if (path == null) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noteSavedAsFile)),
      );
    } catch (e) {
      if (!mounted) return;
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.create(
        context,
        title: AppLocalizations.of(context)!.editPageTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: AppLocalizations.of(context)!.saveAsTextFile,
            onPressed: _hasContentToSave ? _saveAsTextFile : null,
          ),
        ],
      ),
      body: PopScope<Note>(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Note? result) {
          if (didPop) return;
          _onLeave();
        },
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            4 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                autofocus: widget.autofocus,
                style: const TextStyle(fontSize: 24),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.titleHint,
                  border: InputBorder.none,
                ),
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              GestureDetector(
                onTap: () => _pickDateAndTime(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  alignment: Alignment.centerRight,
                  child: Text(
                    // Show the last edit date
                    formatDate(_noteDate),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              Divider(color: Theme.of(context).colorScheme.secondary),
              Expanded(
                child: TextField(
                  controller: bodyController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.noteHint,
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
