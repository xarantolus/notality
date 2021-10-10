import 'dart:async';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:notality/models/text_note.dart';
import 'package:intl/intl.dart';

class NoteEditPage extends StatefulWidget {
  const NoteEditPage(this.note, this.autofocus, {Key? key}) : super(key: key);

  final Note note;
  final bool autofocus;

  @override
  _NoteEditPageState createState() => _NoteEditPageState();
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

    titleController = TextEditingController.fromValue(TextEditingValue(
      text: widget.note.title,
    ));
    titleController!.addListener(() {
      setState(() {});
    });

    bodyController = TextEditingController.fromValue(TextEditingValue(
      text: widget.note.text,
    ));
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

    final DateFormat formatter =
        DateFormat(localization.dateTimeFormat, localization.localeName);

    return formatter.format(d);
  }

  bool get _hasChanged =>
      editedDate != null ||
      _initialText != bodyController!.text.trim() ||
      titleController!.text.trim() != _initialTitle;

  Future<bool> _onLeave() async {
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
      Navigator.pop(
        context,
        newNote,
      );
    }
    return false;
  }

  Future<void> _pickDateAndTime(BuildContext context) async {
    var now = _noteDate;

    var date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );

    var tod = TimeOfDay(hour: now.hour, minute: now.minute);
    var time = await showTimePicker(
      context: context,
      initialTime: tod,
    );

    // If we clicked behind/cancelled all dialogs
    if (date == null && time == null) {
      return;
    }

    // Construct the date + time from both selected values
    var resultDayAndTime = date ?? DateTime(now.year, now.month, now.day);
    if (time != null) {
      resultDayAndTime = resultDayAndTime
          .add(Duration(hours: time.hour, minutes: time.minute));
    }

    setState(() {
      editedDate = resultDayAndTime;
    });
  }

  DateTime get _noteDate =>
      _hasChanged ? (editedDate ?? DateTime.now()) : widget.note.lastEditDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editPageTitle),
      ),
      body: WillPopScope(
        onWillPop: _onLeave,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                autofocus: widget.autofocus,
                style: const TextStyle(
                  fontSize: 24,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.titleHint,
                  border: InputBorder.none,
                ),
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              GestureDetector(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: Text(
                    // Show the last edit date
                    formatDate(_noteDate),
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                  alignment: Alignment.centerRight,
                ),
                onTap: () => _pickDateAndTime(context),
              ),
              Divider(
                color: Theme.of(context).colorScheme.secondary,
              ),
              Expanded(
                child: TextField(
                  controller: bodyController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.noteHint,
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.multiline,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
