import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:echonep/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows role selection on first launch', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: TranslatorApp()));
    await tester.pumpAndSettle();

    expect(find.text('ECHONEP'), findsWidgets);
    expect(find.text('I am a Tourist'), findsOneWidget);
    expect(find.text('म व्यापारी हुँ'), findsOneWidget);
  });
}
