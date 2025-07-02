import 'package:ulid/ulid.dart';

class IdGenerator {
  static String generate() {
    return Ulid().toString();
  }
}
