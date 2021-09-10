import "dart:io";
import 'package:path_provider/path_provider.dart';
import 'package:notality/models/text_note.dart';
import 'package:mutex/mutex.dart';

class NotesService {
  static final fileMutex = Mutex();

  List<Note>? _notes;
  Function? _callback;

  // setCallback sets the callback that is called whenever the managed notes are updated
  void setCallback(Function cb) {
    _callback = cb;
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

  /// Read all saved notes from the notes file.
  Future<List<Note>> readNotes([bool lock = true]) async {
    return _protectIfNecessary(() async {
      if (_notes == null) {
        try {
          var fp = await getNotesFilePath();
          var content = await File(fp).readAsString();

          _notes = notesFileContentFromJson(content).notes;
        } catch (e) {
          _notes = [];
        }
      }
      return _notes!;
    }, lock);
  }

  /// Write the given notes to the notes file, overwriting any old changes
  Future<void> writeNotes(List<Note> notes, [bool lock = true]) async {
    await _protectIfNecessary(() async {
      _notes = notes;

      var fp = await getNotesFilePath();

      var json = notesFileContentToJson(NotesFileContent(notes: notes));

      // Write data to a temporary file and *only then* rename
      var tmpFile = File(fp + ".tmp");
      await tmpFile.writeAsString(json, flush: true);

      await tmpFile.rename(fp);
    }, lock);

    _callback?.call();
  }

  /// deleteNote deletes the note with the given index
  Future<void> deleteNote(int index) async {
    await _protectIfNecessary(() async {
      var notes = await readNotes(false);

      notes.removeAt(index);

      await writeNotes(notes, false);
    }, true);
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
  }
}
