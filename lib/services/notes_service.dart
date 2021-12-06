import "dart:io";

import 'package:flutter/foundation.dart';
import 'package:mutex/mutex.dart';
import 'package:notality/models/text_note.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as web;

class NotesService {
  // Singleton: the NotesService "constructor" always returns the same object
  static final instance = NotesService._internal();
  factory NotesService() {
    return instance;
  }

  // Actual, private constructor
  NotesService._internal();

  static final fileMutex = Mutex();

  List<Note>? _notes;

  final List<Function(int)> _insertCallbacks = [];
  final List<Function(int)> _removeCallbacks = [];

  void addInsertCallback(Function(int) cb) {
    _insertCallbacks.add(cb);
  }

  void addRemoveCallback(Function(int) cb) {
    _removeCallbacks.add(cb);
  }

  // protectIfNecessary runs criticalSection, locking with fileMutex if lock is true
  Future<T> _protectIfNecessary<T>(
      Future<T> Function() criticalSection, bool lock) async {
    if (lock) {
      return fileMutex.protect(() => criticalSection());
    } else {
      return await criticalSection();
    }
  }

  // getNotesFilePath returns the file path for the notes file
  Future<String> getNotesFilePath() async {
    Directory dir = await getApplicationDocumentsDirectory();
    return "${dir.path}/notes.json";
  }

  Future<String> _readNotesImplAndroid() async {
    var fp = await getNotesFilePath();
    return await File(fp).readAsString();
  }

  String _readNotesImplWeb() {
    return web.window.localStorage["notes"] ?? "[]";
  }

  /// Read all saved notes from the notes file.
  Future<List<Note>> readNotes([bool lock = true]) async {
    return _protectIfNecessary(() async {
      if (_notes == null) {
        try {
          var content =
              kIsWeb ? _readNotesImplWeb() : await _readNotesImplAndroid();
          _notes = notesFileContentFromJson(content).notes;
        } catch (e) {
          _notes = [];
        }
      }
      return _notes!;
    }, lock);
  }

  Future<void> _writeNotesImplAndroid(String json) async {
    var fp = await getNotesFilePath();
    var tmpFile = File(fp + ".tmp");
    await tmpFile.writeAsString(json, flush: true);

    await tmpFile.rename(fp);
  }

  void _writeNotesImplWeb(String json) {
    web.window.localStorage["notes"] = json;
  }

  /// Write the given notes to the notes file, overwriting any old changes
  Future<void> writeNotes(List<Note> notes, [bool lock = true]) async {
    await _protectIfNecessary(() async {
      _notes = notes;

      var json = notesFileContentToJson(NotesFileContent(notes: _notes!));

      if (kIsWeb) {
        _writeNotesImplWeb(json);
      } else {
        await _writeNotesImplAndroid(json);
      }

      // Write data to a temporary file and *only then* rename
    }, lock);
  }

  /// deleteNote deletes the note with the given index
  Future<void> deleteNote(int index) async {
    await _protectIfNecessary(() async {
      var notes = await readNotes(false);

      notes.removeAt(index);

      await writeNotes(notes, false);
    }, true);

    for (var f in _removeCallbacks) {
      f.call(index);
    }
  }

  /// addNote adds the given note at index
  Future<void> addNote(Note n, [int index = 0]) async {
    await _protectIfNecessary(() async {
      var notes = await readNotes(false);

      // Snackbar restoring is kind of racy, so sometimes we delete item 2 and 1, then
      // we click the restore button, which will want to insert at index 2 on a list with one element.
      // Since that doesn't work, we set the maximum index here and restore anyways, at the wrong position
      if (index > notes.length) {
        index = notes.length;
      }

      notes.insert(index, n);

      await writeNotes(notes, false);
    }, true);
    for (var f in _insertCallbacks) {
      f.call(index);
    }
  }

  /// replaceNote deletes the note at index and replaces it with the given note n.
  /// The new note is placed first in the list
  Future<void> replaceNote(Note n, int index) async {
    await _protectIfNecessary(() async {
      var notes = await readNotes(false);

      notes.removeAt(index);

      notes.insert(0, n);

      await writeNotes(notes, false);
    }, true);
  }

  Future<List<Note>> reorderNote(int from, int to) async {
    return await _protectIfNecessary(() async {
      var notes = await readNotes(false);

      // If we move an item lower than it was before, we need to subtract one;
      // else we put it one position further than we want
      if (to > from) {
        to--;
      }

      var note = notes.removeAt(from);
      notes.insert(to, note);

      await writeNotes(notes, false);

      _notes = notes;

      return _notes!;
    }, true);
  }
}
