import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';

void main() {
  testWidgets(
    'gUSo mobile app builds without crashing',
    (tester) async {
      await tester.pumpWidget(
        const GusoMobileApp(),
      );

      expect(
        find.text('gUSo Mobile'),
        findsOneWidget,
      );
    },
  );
}