import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/utils/admineom_sso_launcher.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/user_role.dart';

void main() {
  tearDown(() {
    AppConfig.instance.isGuestMode = true;
    AppConfig.instance.isAdminConsoleHost = false;
  });

  group('AdmineomSsoLauncher', () {
    test('maps every brand AppInUse to its canonical admin subdomain', () {
      expect(AdmineomSsoLauncher.adminDomainFor(AppInUse.e), 'admin.emxi.org');
      expect(AdmineomSsoLauncher.adminDomainFor(AppInUse.g), 'admin.gigmeout.com');
      expect(AdmineomSsoLauncher.adminDomainFor(AppInUse.c), 'admin.cyberneom.xyz');
      expect(AdmineomSsoLauncher.adminDomainFor(AppInUse.i), 'admin.itzli.mx');
      expect(AdmineomSsoLauncher.adminDomainFor(AppInUse.b), 'admin.blup.mx');
      expect(AdmineomSsoLauncher.adminDomainFor(AppInUse.v), 'admin.vrlizate.com');
      expect(AdmineomSsoLauncher.adminDomainFor(AppInUse.l), 'admin.letrograf.com');
      expect(AdmineomSsoLauncher.adminDomainFor(AppInUse.a), 'admin.openneom.dev');
    });

    test('enforces staff role floor and per-route minimum role', () {
      expect(AdmineomSsoLauncher.hasRequiredRole(UserRole.subscriber), isFalse);
      expect(AdmineomSsoLauncher.hasRequiredRole(UserRole.editor), isFalse);
      expect(AdmineomSsoLauncher.hasRequiredRole(UserRole.support), isTrue);
      expect(
        AdmineomSsoLauncher.hasRequiredRole(
          UserRole.support,
          minimumRole: UserRole.erp,
        ),
        isFalse,
      );
      expect(
        AdmineomSsoLauncher.hasRequiredRole(
          UserRole.erp,
          minimumRole: UserRole.erp,
        ),
        isTrue,
      );
      expect(
        AdmineomSsoLauncher.hasRequiredRole(
          UserRole.pos,
          minimumRole: UserRole.pos,
        ),
        isTrue,
      );
      expect(
        AdmineomSsoLauncher.hasRequiredRole(
          UserRole.admin,
          minimumRole: UserRole.admin,
        ),
        isTrue,
      );
      // Even if a caller passes subscriber as minimumRole, floor is UserRole.support.
      expect(
        AdmineomSsoLauncher.hasRequiredRole(
          UserRole.subscriber,
          minimumRole: UserRole.subscriber,
        ),
        isFalse,
      );
    });

    test('sanitizes targetPath and rejects traversal / external schemes', () {
      expect(AdmineomSsoLauncher.sanitizeTargetPath(''), '');
      expect(AdmineomSsoLauncher.sanitizeTargetPath('/'), '');
      expect(
        AdmineomSsoLauncher.sanitizeTargetPath('/founding/admin'),
        '/founding/admin',
      );
      expect(AdmineomSsoLauncher.sanitizeTargetPath('//evil.com'), '');
      expect(AdmineomSsoLauncher.sanitizeTargetPath('/../secret'), '');
      expect(AdmineomSsoLauncher.sanitizeTargetPath('https://evil.com'), '');
      expect(
        AdmineomSsoLauncher.buildFallbackUri(
          AppInUse.e,
          targetPath: '/founding/admin',
        ).toString(),
        'https://admin.emxi.org/founding/admin',
      );
    });

    test('parseVerifiedTargetUrl strictly validates HTTPS and exact admin host', () {
      expect(
        AdmineomSsoLauncher.parseVerifiedTargetUrl(
          'https://admin.emxi.org/founding/admin?sso_code=abc',
          expectedHost: 'admin.emxi.org',
        )?.host,
        'admin.emxi.org',
      );
      expect(
        AdmineomSsoLauncher.parseVerifiedTargetUrl(
          'http://admin.emxi.org/?sso_code=abc',
          expectedHost: 'admin.emxi.org',
        ),
        isNull,
      );
      expect(
        AdmineomSsoLauncher.parseVerifiedTargetUrl(
          'https://admin.gigmeout.com/?sso_code=abc',
          expectedHost: 'admin.emxi.org',
        ),
        isNull,
      );
    });

    test('open returns false for guest sessions without launching', () async {
      AppConfig.instance.isGuestMode = true;
      Uri? launched;
      final ok = await AdmineomSsoLauncher.open(
        targetPath: '/erp',
        minimumRole: UserRole.erp,
        launcher: (uri) async {
          launched = uri;
          return true;
        },
      );
      expect(ok, isFalse);
      expect(launched, isNull);
    });
  });
}
