import 'package:flutter_test/flutter_test.dart';
import 'package:notality/models/note_text.dart';

void main() {
  group('noteAsText', () {
    test('lays out title, a blank line, then the body', () {
      expect(noteAsText('Groceries', 'Milk\nEggs'), 'Groceries\n\nMilk\nEggs');
    });

    test('is just the body when the title is empty', () {
      expect(noteAsText('', 'Just the body'), 'Just the body');
    });

    test('is just the title when the body is empty', () {
      expect(noteAsText('Just the title', ''), 'Just the title');
    });

    test('trims whitespace-only fields down to empty', () {
      expect(noteAsText('   ', '   '), '');
      expect(noteAsText('   ', 'Body'), 'Body');
      expect(noteAsText('Title', '   '), 'Title');
    });
  });

  group('noteFileName', () {
    final date = DateTime(2024, 3, 7);

    test('derives the file name from the title', () {
      expect(noteFileName('Groceries', date), 'Groceries.txt');
    });

    test('strips characters invalid in filenames', () {
      expect(noteFileName('a/b\\c:d*e?f"g<h>i|j', date), 'abcdefghij.txt');
    });

    test('collapses runs of whitespace to a single space', () {
      expect(noteFileName('too   many    spaces', date), 'too many spaces.txt');
    });

    test('caps the base at 60 characters without a trailing space', () {
      final longTitle = 'word ' * 20; // 100 chars, space-separated
      final name = noteFileName(longTitle, date);

      final base = name.substring(0, name.length - '.txt'.length);
      expect(base.length, lessThanOrEqualTo(60));
      expect(base.endsWith(' '), isFalse);
    });

    test('falls back to the note date when the title is empty', () {
      expect(noteFileName('', date), 'note_2024-03-07.txt');
    });

    test(
      'falls back to the note date when the title is only invalid characters',
      () {
        expect(noteFileName('///:::***', date), 'note_2024-03-07.txt');
      },
    );

    test('falls back to the note date when the title is only whitespace', () {
      expect(noteFileName('   ', date), 'note_2024-03-07.txt');
    });

    test('pads single-digit month and day in the fallback name', () {
      expect(noteFileName('', DateTime(2024, 1, 2)), 'note_2024-01-02.txt');
    });
  });
}
