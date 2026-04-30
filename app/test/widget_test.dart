import 'package:flutter_test/flutter_test.dart';
import 'package:the_harvest/app.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const TheHarvestApp());
    expect(find.text('The Harvest'), findsOneWidget);
  });
}
