import "dart:io";
import 'package:path_provider/path_provider.dart';
import 'package:notality/models/text_note.dart';

class NotesService {
  static Future<String> getNotesFilePath() async {
    Directory dir = await getApplicationDocumentsDirectory();

    return "${dir.path}/notes.json";
  }

  static Future<List<Note>> readNotes() async {
    var fp = await getNotesFilePath();

    try {
      var content = await File(fp).readAsString();
      return notesFileContentFromJson(content).notes;
    } catch (e) {
      return [];
    }
  }
}
