import 'package:hive/hive.dart';
part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String username;
  @HiveField(1)
  String passwordHash;
  User({required this.username, required this.passwordHash});

  static User defaultUser() {
    return User(username: '', passwordHash: '');
  }
} 