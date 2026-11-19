import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App loads and renders Job.io title and Jobs tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const JobIoApp());
    await tester.pumpAndSettle();

    expect(find.text('Job'), findsOneWidget);
    expect(find.text('.io'), findsOneWidget);
    expect(find.text('Jobs'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Made by upcoming Event Beeps Engineer'), findsOneWidget);
  });
}
