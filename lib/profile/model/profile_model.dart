// profile_model.dart (UPDATED)
class ProfileModel {
  final String uid;
  final String displayName;
  // REMOVED: final String email;
  final String mobileNumber;
  final bool emailVerified;
  final String? photoURL;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  ProfileModel({
    required this.uid,
    required this.displayName,
    // REMOVED: required this.email,
    required this.mobileNumber,
    this.emailVerified = false,
    this.photoURL,
    this.createdAt,
    this.lastLogin,
  });

  // Convert from Firestore document
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] ?? '',
      // REMOVED: email: json['email'] ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? '',
      emailVerified: json['emailVerified'] ?? false,
      photoURL: json['photoURL'],
      createdAt: json['createdAt']?.toDate(),
      lastLogin: json['lastLogin']?.toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      // REMOVED: 'email': email,
      'mobileNumber': mobileNumber,
      'emailVerified': emailVerified,
      'photoURL': photoURL,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
    };
  }

  // Create a copy with updated fields
  ProfileModel copyWith({
    String? uid,
    String? displayName,
    // REMOVED: String? email,
    String? mobileNumber,
    bool? emailVerified,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return ProfileModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      // REMOVED: email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      emailVerified: emailVerified ?? this.emailVerified,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}