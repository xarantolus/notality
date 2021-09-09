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

  /// Read all saved notes from the notes file.
  static Future<List<Note>> readNotes() async {
    await fileMutex.acquire();

    List<Note> notes;

    try {
      var fp = await getNotesFilePath();
      var content = await File(fp).readAsString();

      notes = notesFileContentFromJson(content).notes;
    } catch (e) {
      notes = [];
    } finally {
      fileMutex.release();
    }

    return notes;
  }

  /// Write the given notes to the notes file, overwriting any old changes
  static Future<void> writeNotes(List<Note> notes) async {
    await fileMutex.acquire();

    try {
      var fp = await getNotesFilePath();

      var json = notesFileContentToJson(NotesFileContent(notes: notes));

      // Write data to a temporary file and *only then* rename
      var tmpFile = File(fp + ".tmp");
      await tmpFile.writeAsString(json, flush: true);

      await tmpFile.rename(fp);
    } catch (e) {
      fileMutex.release();
      rethrow;
    } finally {
      fileMutex.release();
    }
  }
}
