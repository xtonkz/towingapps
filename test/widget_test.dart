import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:driver_towing/app.dart';

void main() {
  testWidgets('shows splash copy on launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const DriverTowingApp());

    expect(find.text('Driver Towing'), findsOneWidget);
    expect(
      find.text(
        'Pantau jadwal pengiriman dan kirim report unit dari satu aplikasi.',
      ),
      findsOneWidget,
    );
  });
}
