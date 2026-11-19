import 'package:get/get.dart';

import '../../../data/repositories/admin_repository.dart';
import '../viewmodels/admin_viewmodel.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AdminRepository>()) {
      Get.lazyPut<AdminRepository>(() => ApiAdminRepository());
    }
    Get.lazyPut<AdminViewModel>(() => AdminViewModel());
  }
}

