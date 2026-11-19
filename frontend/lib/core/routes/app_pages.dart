import 'package:get/get.dart';

import '../../features/admin/bindings/admin_binding.dart';
import '../../features/admin/views/admin_view.dart';
import '../../features/jobs/bindings/jobs_binding.dart';
import '../../features/jobs/views/jobs_view.dart';
import '../../features/shell/bindings/shell_binding.dart';
import '../../features/shell/views/shell_view.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.initial;

  static final routes = [
    GetPage(
      name: AppRoutes.initial,
      page: () => const ShellView(),
      binding: ShellBinding(),
    ),
    GetPage(
      name: AppRoutes.jobs,
      page: () => const JobsView(),
      binding: JobsBinding(),
    ),
    GetPage(
      name: AppRoutes.admin,
      page: () => const AdminView(),
      binding: AdminBinding(),
    ),
  ];
}
