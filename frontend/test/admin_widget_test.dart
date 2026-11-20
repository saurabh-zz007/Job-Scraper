import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:frontend/core/config/env_config.dart';
import 'package:frontend/data/repositories/admin_repository.dart';
import 'package:frontend/features/admin/viewmodels/admin_viewmodel.dart';
import 'package:frontend/features/admin/views/admin_view.dart';
import 'package:frontend/features/jobs/widgets/formatted_job_description.dart';
import 'admin_viewmodel_test.dart';

void main() {
  setUp(() {
    EnvConfig.setMockValues({'ADMIN_USERNAME': 'admin', 'ADMIN_PASSWORD': 'admin'});
  });

  testWidgets('AdminView shows login gateway when unauthenticated and signs in', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Get.reset();
    final mockRepo = MockAdminRepository();
    Get.put<AdminRepository>(mockRepo);
    final viewModel = AdminViewModel(repository: mockRepo);
    Get.put<AdminViewModel>(viewModel);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: AdminView(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Login Screen appears
    expect(find.text('Admin Authentication'), findsOneWidget);
    expect(find.text('Sign In to Admin Console'), findsOneWidget);

    // Enter wrong credentials
    await tester.enterText(find.byType(TextField).at(0), 'admin');
    await tester.enterText(find.byType(TextField).at(1), 'wrongpass');
    await tester.tap(find.text('Sign In to Admin Console'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid administrator credentials.'), findsOneWidget);
    expect(viewModel.isAuthenticated.value, isFalse);

    // Enter correct credentials
    await tester.enterText(find.byType(TextField).at(1), 'admin');
    await tester.tap(find.text('Sign In to Admin Console'));
    await tester.pumpAndSettle();

    // Verify Admin Dashboard is now rendered
    expect(viewModel.isAuthenticated.value, isTrue);
    expect(find.text('Admin Operations Console'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });

  testWidgets('AdminView renders all dashboard sections, KPI cards, and jobs table when authenticated', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Get.reset();
    final mockRepo = MockAdminRepository();
    Get.put<AdminRepository>(mockRepo);
    final viewModel = AdminViewModel(repository: mockRepo);
    viewModel.isAuthenticated.value = true;
    await viewModel.refreshAll();
    Get.put<AdminViewModel>(viewModel);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: AdminView(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Admin Operations Console'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);

    // Verify Control Bar Refresh Controls
    expect(find.text('Live Telemetry & Controls'), findsOneWidget);
    expect(find.text('Auto (15s)'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
    expect(find.text('Pipeline Idle'), findsNothing);
    expect(find.text('Run Full Pipeline'), findsNothing);

    // Verify KPI Cards
    expect(find.text('PIPELINE FUNNEL'), findsOneWidget);
    expect(find.text('LLM ECONOMICS'), findsOneWidget);
    expect(find.text('TOKEN CONSUMPTION'), findsOneWidget);
    expect(find.text('EXTRACTION QUALITY'), findsOneWidget);

    // Verify Diagnostic Panels
    expect(find.text('Breakdown by Source ATS'), findsOneWidget);
    expect(find.text('Model & Prompt Performance'), findsOneWidget);
    expect(find.text('Top Ingestion Errors'), findsOneWidget);

    // Verify Table Columns and Records
    expect(find.text('COMPANY & TITLE'), findsOneWidget);
    expect(find.text('Senior Backend Engineer'), findsOneWidget);
    expect(find.text('Stripe'), findsOneWidget);
    expect(find.text('Frontend Engineer'), findsOneWidget);
    expect(find.text('Figma'), findsOneWidget);

    // Verify Danger Zone
    expect(find.text('Maintenance & Danger Zone'), findsOneWidget);
    expect(find.text('Purge All Failed Jobs'), findsOneWidget);
    expect(find.text('Purge Stale Jobs (> 14 Days)'), findsOneWidget);
    expect(find.text('Reclassify Low Conf (<80%)'), findsOneWidget);
  });

  testWidgets('FormattedJobDescription cleanly groups headers, bullets, and paragraphs', (tester) async {
    const rawText = '''
About the Role:
We are looking for a Senior Engineer &amp; Tech Lead.

Responsibilities:
• Architect scalable microservices with FastAPI & PostgreSQL
• Mentor junior developers
• Lead sprint planning

Qualifications:
- 5+ years of Python experience
- Strong distributed systems knowledge

Benefits:
* Competitive salary & equity
* Health &amp; Dental insurance
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FormattedJobDescription(description: rawText),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Section headers detected and rendered
    expect(find.text('About the Role'), findsOneWidget);
    expect(find.text('Responsibilities'), findsOneWidget);
    expect(find.text('Qualifications'), findsOneWidget);
    expect(find.text('Benefits'), findsOneWidget);

    // HTML entities cleaned up
    expect(find.text('We are looking for a Senior Engineer & Tech Lead.'), findsOneWidget);
    expect(find.text('Health & Dental insurance'), findsOneWidget);

    // Bullets parsed into individual selectable text
    expect(find.text('Architect scalable microservices with FastAPI & PostgreSQL'), findsOneWidget);
    expect(find.text('5+ years of Python experience'), findsOneWidget);
    expect(find.text('Competitive salary & equity'), findsOneWidget);
  });
}
