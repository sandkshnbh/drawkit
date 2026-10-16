import 'package:drawkit_gallery/main.dart' show DrawkitGalleryApp;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('gallery boots into the surface page', (tester) async {
    await tester.pumpWidget(const DrawkitGalleryApp());
    expect(find.text('drawkit'), findsOneWidget);
    expect(find.text('Surface'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 200));
  });
}
