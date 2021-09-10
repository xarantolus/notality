import 'package:flutter/material.dart';
import 'package:notality/models/text_note.dart';
import 'package:intl/intl.dart';

class NoteEditPage extends StatefulWidget {
  NoteEditPage(this.note, this.autofocus, {Key? key}) : super(key: key);

  Note note;
  bool autofocus;

  @override
  _NoteEditPageState createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  TextEditingController? titleController;
  TextEditingController? bodyController;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController.fromValue(TextEditingValue(
      text: widget.note.title,
    ));
    titleController!.addListener(changed);

    bodyController = TextEditingController.fromValue(TextEditingValue(
      text: widget.note.text,
    ));
    bodyController!.addListener(changed);
  }

  @override
  void dispose() {
    titleController!.dispose();
    bodyController!.dispose();

    super.dispose();
  }

  String formatDate(DateTime d) {
    final DateFormat formatter = DateFormat.Hm().add_yMMMMd();

    return formatter.format(d);
  }

  bool _didChange = false;

  void changed() {
    setState(() {
      _didChange = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: WillPopScope(
        onWillPop: () async {
          var newNote = Note(
            type: "text",
            lastEditDate: DateTime.now(),
            title: titleController!.text.trim(),
            text: bodyController!.text.trim(),
          );

          // If we didn't edit anything, we return null; else we return our node
          if (newNote.text.isEmpty && newNote.title.isEmpty || !_didChange) {
            Navigator.pop(context, null);
          } else {
            Navigator.pop(
              context,
              newNote,
            );
          }
          return false;
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                autofocus: widget.autofocus,
                style: const TextStyle(
                  fontSize: 24,
                ),
                decoration: const InputDecoration(
                  hintText: "Title",
                ),
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  // Show the current date while editing, else use the last edit date
                  formatDate(
                      _didChange ? DateTime.now() : widget.note.lastEditDate),
                ),
                alignment: Alignment.centerRight,
              ),
              Expanded(
                child: TextField(
                  controller: bodyController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                      hintText: "Note", border: InputBorder.none),
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
