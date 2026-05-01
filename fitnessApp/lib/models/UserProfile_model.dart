class UserProfile {
  final String uid;
  final String name;
  // final DateTime dob;
  final String age;
  final double height;
  final double weight;
  final String gender;

  UserProfile({
    required this.uid,
    required this.name,
    // required this.dob,
    required this.age,
    required this.height,
    required this.weight,
    required this.gender,
  });

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      // 'dob': dob.toIso8601String(), // or Timestamp
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
    };
  }

  /// Create from Firestore JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    print("INSIDE JSON");
    return UserProfile(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      // dob: DateTime.parse(json['dob']),
      age: json['age'] ?? '',
      height: (json['height'] ?? 0).toDouble(),
      weight: (json['weight'] ?? 0).toDouble(),
      gender: json['gender'] ?? '',
    );
  }

  /// Optional: calculate age dynamically
  // int get age {
  //   final today = DateTime.now();
  //   int age = today.year - dob.year;

  //   if (today.month < dob.month ||
  //       (today.month == dob.month && today.day < dob.day)) {
  //     age--;
  //   }
  //   return age;
  // }
}
