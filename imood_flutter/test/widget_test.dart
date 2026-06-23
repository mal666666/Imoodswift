import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imood_flutter/main.dart';
import 'package:imood_flutter/models/music_catalog.dart';
import 'package:imood_flutter/screens/composer_screen.dart';

void main() {
  testWidgets('Imood app loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ImoodApp());
    expect(find.text('Imood'), findsOneWidget);
  });

  testWidgets('Composer screen shows bottom action buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ComposerScreen(style: MusicStyle.pop)),
    );

    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.byIcon(Icons.file_download_rounded), findsOneWidget);
  });
}
