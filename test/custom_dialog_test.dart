import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahifile/core/widgets/app_dialog.dart';

void main() {
  testWidgets('AppDialog displays error message and actionable suggestion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppDialog.showError(
                      context,
                      title: 'Target Size Too Small',
                      message: 'Could not compress image under 20 KB.',
                      suggestion: 'Try reducing width/height dimensions.',
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Tap button to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify custom dialog UI
    expect(find.text('Target Size Too Small'), findsOneWidget);
    expect(find.text('Could not compress image under 20 KB.'), findsOneWidget);
    expect(find.text('Try reducing width/height dimensions.'), findsOneWidget);
    expect(find.text('Understood'), findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.text('Understood'));
    await tester.pumpAndSettle();

    expect(find.text('Target Size Too Small'), findsNothing);
  });
}
