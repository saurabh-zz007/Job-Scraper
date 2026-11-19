import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:frontend/data/repositories/admin_repository.dart';
import 'package:frontend/features/admin/viewmodels/admin_viewmodel.dart';
import 'package:frontend/features/admin/views/admin_view.dart';
import 'admin_viewmodel_test.dart';

void main() {
  testWidgets('AdminView renders all dashboard sections, KPI cards, and jobs table', (tester) async {
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

    // Verify Title & Subtitle
    expect(find.text('Admin Operations Console'), findsOneWidget);

    // Verify Control Bar Badges & Buttons
    expect(find.text('Pipeline Idle'), findsOneWidget);
    expect(find.text('LLM Queue: 3'), findsOneWidget);
    expect(find.text('Run Full Pipeline'), findsOneWidget);
    expect(find.text('Retry All Failed'), findsOneWidget);

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
}

