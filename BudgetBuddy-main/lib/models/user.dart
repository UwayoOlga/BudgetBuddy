import 'package:hive/hive.dart';
part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String username;
  @HiveField(1)
  String passwordHash;
  @HiveField(2)
  String email;
  @HiveField(3)
  String schoolName;

  User({
    required this.username,
    required this.passwordHash,
    this.email = '',
    this.schoolName = '',
  });
} 