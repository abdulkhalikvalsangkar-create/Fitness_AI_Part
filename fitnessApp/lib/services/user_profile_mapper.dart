import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:FitnessApp/services/csv_health_service.dart';
import 'package:FitnessApp/services/csv_login_service.dart';

class UserProfileMapper {
  UserProfileMapper._();
  static Future<String?> getCsvUserId() async {
    return await CsvLoginService.getLoggedInUser();
  }
  /// Returns the CSV user mapped to the currently logged in Firebase user.
  ///
  /// Example:
  /// USER_00001
  // static Future<String> getCsvUserId() async {
  //   // First check CSV Login
  //   final csvLoggedUser = await CsvLoginService.getLoggedInUser();
  //
  //   if (csvLoggedUser != null && csvLoggedUser.isNotEmpty) {
  //     return csvLoggedUser;
  //   }
  //
  //   // Otherwise continue with Firebase
  //   final user = FirebaseAuth.instance.currentUser;
  //
  //   if (user == null) {
  //     return "USER_00001";
  //   }
  //   final profile =
  //   await FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(user.uid)
  //       .collection('userprofile')
  //       .doc('profile')
  //       .get();
  //
  //   if (!profile.exists) {
  //     return "USER_00001";
  //   }
  //
  //   final data = profile.data();
  //
  //   final csvUserId = data?['csvUserId'];
  //
  //   if (csvUserId is String && csvUserId.isNotEmpty) {
  //     return csvUserId;
  //   }
  //
  //   return "USER_00001";
  // }

//   static Future<void> assignCsvUserIfNeeded() async {
//     final user = FirebaseAuth.instance.currentUser;
//
//     if (user == null) return;
//
//     final profileRef = FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .collection('userprofile')
//         .doc('profile');
//
//     final profile = await profileRef.get();
//
//     if (!profile.exists) return;
//
//     final data = profile.data();
//
// // Read all valid users from the dataset.
//     final csvUsers = await CsvHealthService().getAvailableUserIds();
//
//     if (csvUsers.isEmpty) {
//       return;
//     }
//
//     final existing = data?['csvUserId'];
//
//     print("Existing csvUserId : $existing");
//
// // Keep the existing mapping only if it is valid.
//     if (existing is String && csvUsers.contains(existing)) {
//       print("Existing mapping is valid.");
//       return;
//     }
//
// // Generate a valid mapping.
//     final index = user.uid.hashCode.abs() % csvUsers.length;
//
//     final csvUserId = csvUsers[index];
//
//     print("Assigning new csvUserId : $csvUserId");
//
//     await profileRef.update({
//       "csvUserId": csvUserId,
//     });
//   }
}
