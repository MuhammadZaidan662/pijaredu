import 'package:flutter_test/flutter_test.dart';
import 'package:pijaredu/main.dart';

void main() {
  testWidgets('PijarEdu app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PijarEduApp());

    expect(find.text('PijarEdu'), findsOneWidget);
    expect(find.text('Supabase connected!'), findsOneWidget);
  });
}