import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/utils/auth_guard.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/model/app_user.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:sint/sint.dart';

class _FakeUserService extends Fake implements UserService {
  @override
  final AppUser user;

  _FakeUserService(this.user);
}

void main() {
  setUp(() {
    Sint.reset();
    AppConfig.instance.isGuestMode = true;
  });

  tearDown(() {
    Sint.reset();
    AppConfig.instance.isGuestMode = true;
  });

  test('guest session is not authenticated', () {
    expect(AuthGuard.isAuthenticated, isFalse);
  });

  test('leaving guest mode plus a stale user id is not authentication', () {
    AppConfig.instance.isGuestMode = false;
    Sint.put<UserService>(_FakeUserService(AppUser(id: 'stale-user')));

    expect(AuthGuard.isAuthenticated, isFalse);
  });
}
