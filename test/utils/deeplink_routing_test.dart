import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/utils/deeplink_utilities.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

void main() {
  group('DeeplinkUtilities Routing & Slug Generation Tests', () {
    test('generateVanityUrl should format profile slugs with "@" prefix correctly', () {
      // 1. Profile slug that doesn't start with @
      final url1 = DeeplinkUtilities.generateVanityUrl(type: 'profile', slug: 'serzenmontoya');
      expect(url1, contains('/@serzenmontoya'));

      // 2. Profile slug that already starts with @
      final url2 = DeeplinkUtilities.generateVanityUrl(type: 'profile', slug: '@emmanuel');
      expect(url2, contains('/@emmanuel'));

      // 3. Fallback to ID if slug is empty
      final url3 = DeeplinkUtilities.generateVanityUrl(type: 'profile', id: '123456');
      expect(url3, contains('/@123456'));
    });

    test('generateVanityUrl should format posts with "/p/" prefix correctly', () {
      final url = DeeplinkUtilities.generateVanityUrl(type: 'post', id: 'xyz987');
      expect(url, contains('/p/xyz987'));
    });

    test('generateVanityUrl should format collectives with "/collective/" prefix correctly', () {
      // 1. Collective with slug
      final url1 = DeeplinkUtilities.generateVanityUrl(type: 'collective', slug: 'daft-punk');
      expect(url1, contains('/daft-punk'));

      // 2. Collective fallback to ID
      final url2 = DeeplinkUtilities.generateVanityUrl(type: 'collective', id: 'col123');
      expect(url2, contains('/collective/col123'));
    });

    test('Restful Path Builders should build correct routes', () {
      expect(AppRouteConstants.postPath('p123'), equals('/post/p123'));
      expect(AppRouteConstants.postPath('p123', slug: 'first-release'), equals('/post/first-release'));
      expect(AppRouteConstants.matePath('m123'), equals('/mate/m123'));
      expect(AppRouteConstants.matePath('m123', slug: 'serzen'), equals('/mate/serzen'));
      expect(AppRouteConstants.collectivePath('c123'), equals('/collective/c123'));
    });
  });
}
