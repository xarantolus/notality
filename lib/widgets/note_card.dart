import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notality/l10n/app_localizations.dart';
import 'package:notality/models/text_note.dart';
import 'package:timeago/timeago.dart' as timeago;

class NoteCard extends StatefulWidget {
  const NoteCard({super.key, required this.note});

  final Note note;

  @override
  State<NoteCard> createState() => _NoteCardState();
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

  Widget titleContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Text(
        widget.note.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  Widget subtitleContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
      child: Text(
        widget.note.text,
        maxLines: 12,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: widget.note.title.isEmpty ? null : titleContainer(context),
        subtitle: widget.note.text.isEmpty ? null : subtitleContainer(context),
        trailing: Text(
          timeago.format(
            widget.note.lastEditDate,
            locale: AppLocalizations.of(context)!.localeName,
            allowFromNow: true,
          ),
        ),
      ),
    );
  }
}
