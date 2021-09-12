import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notality/models/text_note.dart';
import 'package:timeago/timeago.dart' as timeago;

class NoteCard extends StatefulWidget {
  const NoteCard({Key? key, required this.note}) : super(key: key);

  final Note note;

  @override
  _NoteCardState createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Update time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer!.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 6),
      child: Container(
        decoration: ShapeDecoration(
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: ListTile(
            title: widget.note.title.isEmpty
                ? null
                : Container(
                    child: Text(
                      widget.note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    padding: const EdgeInsets.all(4),
                  ),
            subtitle: widget.note.text.isEmpty
                ? null
                : Container(
                    child: Text(
                      widget.note.text,
                      maxLines: 12,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15),
                    ),
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                  ),
            trailing: Text(
              timeago.format(widget.note.lastEditDate),
            ),
          ),
        ),
      ),
    );
  }
}
