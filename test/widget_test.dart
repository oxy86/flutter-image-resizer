import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_image_resizer/main.dart';

void main() {
  testWidgets('shows default image resizer controls', (tester) async {
    await tester.pumpWidget(const ImageResizerApp());

    expect(find.text('Image Resizer'), findsOneWidget);
    expect(find.text('Load Image'), findsOneWidget);
    expect(find.text('1200x scale'), findsOneWidget);
    expect(find.text('WEBP'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
  });

  test('sanitizes output filenames with underscores and max length', () {
    final filename = sanitizeBaseFilename(
      'My Vacation Photo (Final Export) 2026',
      maxLength: 32,
    );

    expect(filename, 'my_vacation_photo_final_export_2');
    expect(filename.length, lessThanOrEqualTo(32));
  });

  test('falls back to image when sanitized filename is empty', () {
    expect(sanitizeBaseFilename('---', maxLength: 32), 'image');
  });

  test('finds first existing image path argument', () async {
    final file = File(
      '${Directory.systemTemp.path}/image_resizer_arg_test.png',
    );
    await file.writeAsBytes([0]);
    addTearDown(() {
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    expect(firstImagePathArgument(['--flag', file.path]), file.path);
    expect(firstImagePathArgument(['file://${file.path}']), file.path);
  });
}
