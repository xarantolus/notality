/// Title, a blank line, then the body; a missing half leaves no blank lines.
String noteAsText(String title, String body) {
  final trimmedTitle = title.trim();
  final trimmedBody = body.trim();

  if (trimmedTitle.isEmpty) {
    return trimmedBody;
  }
  if (trimmedBody.isEmpty) {
    return trimmedTitle;
  }

  return '$trimmedTitle\n\n$trimmedBody';
}

final _invalidFileNameChars = RegExp(r'[/\\:*?"<>|\x00-\x1F\x7F]');
final _whitespaceRuns = RegExp(r'\s+');
const _maxFileNameBaseLength = 60;

/// Builds a `.txt` file name from a note's title, falling back to the note's
/// date when the title has nothing usable in it.
String noteFileName(String title, DateTime date) {
  final base = _sanitizedFileNameBase(title);

  if (base.isEmpty) {
    return 'note_${_isoDate(date)}.txt';
  }

  return '$base.txt';
}

String _sanitizedFileNameBase(String title) {
  final withoutInvalidChars = title.replaceAll(_invalidFileNameChars, '');
  final collapsed = withoutInvalidChars.replaceAll(_whitespaceRuns, ' ').trim();

  if (collapsed.length <= _maxFileNameBaseLength) {
    return collapsed;
  }

  // Cutting mid-run can leave a trailing space, so trim again.
  return collapsed.substring(0, _maxFileNameBaseLength).trim();
}

String _isoDate(DateTime date) {
  String pad2(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${pad2(date.month)}-${pad2(date.day)}';
}
