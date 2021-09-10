import "dart:io";
import 'package:path_provider/path_provider.dart';
import 'package:notality/models/text_note.dart';
import 'package:mutex/mutex.dart';

class NotesService {
  static final fileMutex = Mutex();

  static Future<String> getNotesFilePath() async {
    Directory dir = await getApplicationDocumentsDirectory();

    return "${dir.path}/notes.json";
  }

  List<Note>? _notes;
  Function? _callback;

  void setCallback(Function cb) {
    _callback = cb;
  }

  /// Read all saved notes from the notes file.
  Future<List<Note>> readNotes() async {
    return fileMutex.protect(() async {
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
    });
  }

  /// Write the given notes to the notes file, overwriting any old changes
  Future<void> writeNotes(List<Note> notes) async {
    await fileMutex.protect(() async {
      var fp = await getNotesFilePath();

      var json = notesFileContentToJson(NotesFileContent(notes: notes));

      // Write data to a temporary file and *only then* rename
      var tmpFile = File(fp + ".tmp");
      await tmpFile.writeAsString(json, flush: true);

      await tmpFile.rename(fp);
    });

    _callback?.call();
  }

  Future<void> deleteNote(int index) async {
    // TODO: Also lock this section in the mutex without dead-locking ourselves
    var notes = await readNotes();
    notes.removeAt(index);
    await writeNotes(notes);
  }

  Future<void> addNote(Note n, [int index = 0]) async {
    // TODO: Also lock this section in the mutex without dead-locking ourselves
    var notes = await readNotes();

    notes.insert(index, n);

    await writeNotes(notes);
  }
}
