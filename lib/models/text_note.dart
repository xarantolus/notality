// To parse this JSON data, do
//
//     final notesFileContent = notesFileContentFromJson(jsonString);

import 'dart:convert';

NotesFileContent notesFileContentFromJson(String str) =>
    NotesFileContent.fromJson(json.decode(str));

String notesFileContentToJson(NotesFileContent data) =>
    json.encode(data.toJson());

class NotesFileContent {
  NotesFileContent({
    required this.notes,
  });

  List<Note> notes;

  factory NotesFileContent.fromJson(Map<String, dynamic> json) =>
      NotesFileContent(
        notes: List<Note>.from(json["notes"].map((x) => Note.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "notes": List<dynamic>.from(notes.map((x) => x.toJson())),
      };
}

class Note {
  Note({
    required this.type,
    required this.title,
    required this.lastEditDate,
    required this.text,
  });

  Note.empty()
      : type = "text",
        text = "",
        title = "",
        lastEditDate = DateTime.now();

  String type;
  String title;
  DateTime lastEditDate;
  String text;

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        type: json["type"],
        title: json["title"],
        lastEditDate: DateTime.parse(json["lastEditDate"]),
        text: json["text"],
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "title": title,
        "lastEditDate": lastEditDate.toIso8601String(),
        "text": text,
      };
}
