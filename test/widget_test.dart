// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notality/main.dart';
import 'package:notality/screens/note_edit.dart';

void main() {
  testWidgets('Floating action button brings up the edit screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());

    await tester.tap(find.byType(FloatingActionButton));

    await tester.pumpAndSettle();

    // The note edit page should be brought up
    expect(find.byType(NoteEditPage), findsOneWidget);
  });
}
