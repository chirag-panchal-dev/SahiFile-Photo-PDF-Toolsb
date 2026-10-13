import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sahifile/app/app.dart';
import 'package:sahifile/app/providers.dart';

void main() {
  testWidgets('SahiFileApp launches and renders successfully', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const SahiFileApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify SahiFile title or branding is present
    expect(find.text('SahiFile'), findsWidgets);
  });
}
