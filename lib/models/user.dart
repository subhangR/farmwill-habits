// class User {
//   String? id;
//   String? name;
//   String? email;
//   String? phone;
//   String? token;
//   String? createdAt;
//   String? updatedAt;
//
//   User({
//     this.id,
//     this.name,
//     this.email,
//     this.phone,
//     this.token,
//     this.createdAt,
//     this.updatedAt,
//   });
//
//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       id: json['id'],
//       name: json['name'],
//       email: json['email'],
//       phone: json['phone'],
//
//       token: json['token'],
//       createdAt: json['created_at'],
//       updatedAt: json['updated_at'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'email': email,
//       'phone': phone,
//       'token': token,
//       'created_at': createdAt,
//       'updated_at': updatedAt,
//     };
//   }
// }


class FreeUser {
  String uid;
  String email;
  String? phone;
  String? photoURL;
  String? displayName;
  String? firstName;
  String? lastName;
  bool isVerified;
  String? hunter;
  String? bio;

  FreeUser({
    required this.uid,
    required this.email,
    this.phone,
    this.photoURL,
    this.displayName,
    this.firstName,
    this.hunter,
    this.lastName,
    this.isVerified = false,
    this.bio,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'phone': phone,
      'photoURL': photoURL,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'hunter': hunter,
      'bio': bio,
    };
  }

  factory FreeUser.fromJson(String uid, Map<String, dynamic> data) {
    return FreeUser(
      uid: uid,
      email: data['email'],
      phone: data['phone'],
      photoURL: data['photoURL'],
      displayName: data['displayName'],
      firstName: data['firstName'],
      lastName: data['lastName'],
      bio: data['bio'],
      hunter: data['hunter'],
    );
  }

  bool isProfileComplete() {
    return firstName != null && lastName != null && hunter != null;
  }

}