// Tests for `BaseItemMapper`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/utils/mappers/base_item_mapper.dart';
import 'package:neom_core/domain/model/app_media_item.dart';
import 'package:neom_core/domain/model/app_release_item.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/neom/neom_chamber_preset.dart';
import 'package:neom_core/domain/model/neom/neom_frequency.dart';

void main() {
  group('BaseItemMapper.fromAppReleaseItem', () {
    test('mapea campos básicos', () {
      final release = AppReleaseItem(
        id: 'r1',
        name: 'My Album',
        description: 'desc',
        imgUrl: 'https://img',
        previewUrl: 'https://preview',
        duration: 240,
        state: 3,
        ownerEmail: 'creator@x.com',
        ownerName: 'Ana',
        externalUrl: 'https://ext',
        createdTime: 2024,
      );
      final base = BaseItemMapper.fromAppReleaseItem(release);

      expect(base.id, 'r1');
      expect(base.name, 'My Album');
      expect(base.description, 'desc');
      expect(base.imgUrl, 'https://img');
      expect(base.url, 'https://preview',
          reason: 'mapper usa previewUrl como url');
      expect(base.duration, 240);
      expect(base.state, 3);
      expect(base.ownerId, 'creator@x.com',
          reason: 'mapper usa ownerEmail como ownerId');
      expect(base.ownerName, 'Ana');
      expect(base.permaUrl, 'https://ext');
      expect(base.publishedYear, 2024,
          reason: 'mapper usa createdTime como publishedYear');
    });

    test('externalUrl null → permaUrl ""', () {
      final r = AppReleaseItem(externalUrl: null);
      expect(BaseItemMapper.fromAppReleaseItem(r).permaUrl, '');
    });
  });

  group('BaseItemMapper.fromAppMediaItem', () {
    test('mapea campos básicos', () {
      final media = AppMediaItem(
        id: 'm1', name: 'Track',
        description: 'desc',
        imgUrl: 'https://img',
        url: 'https://stream',
        duration: 180,
        state: 1,
        ownerName: 'Artist',
        ownerId: 'sp_1',
        permaUrl: 'https://perma',
      );
      final base = BaseItemMapper.fromAppMediaItem(media);
      expect(base.id, 'm1');
      expect(base.name, 'Track');
      expect(base.url, 'https://stream');
      expect(base.duration, 180);
      expect(base.ownerId, 'sp_1');
      expect(base.permaUrl, 'https://perma');
    });

    test('ownerId null → ""', () {
      final m = AppMediaItem(ownerId: null);
      expect(BaseItemMapper.fromAppMediaItem(m).ownerId, '');
    });

    test('publishedYear null → 0', () {
      final m = AppMediaItem(publishedYear: null);
      expect(BaseItemMapper.fromAppMediaItem(m).publishedYear, 0);
    });

    test('categories null → []', () {
      final m = AppMediaItem(categories: null);
      expect(BaseItemMapper.fromAppMediaItem(m).categories, isEmpty);
    });
  });

  group('BaseItemMapper.fromExternalItem', () {
    test('mapea campos básicos', () {
      final ext = ExternalItem(
        id: 'e1', name: 'Track',
        imgUrl: 'https://x', url: 'https://stream',
        duration: 200, state: 2, permaUrl: 'https://perma',
        ownerName: 'Artist',
      );
      final base = BaseItemMapper.fromExternalItem(ext);
      expect(base.id, 'e1');
      expect(base.name, 'Track');
      expect(base.url, 'https://stream');
      expect(base.duration, 200);
      expect(base.ownerName, 'Artist');
    });
  });

  group('BaseItemMapper.fromChamberPreset', () {
    test('mapea campos básicos del preset', () {
      final preset = NeomChamberPreset(
        id: 'preset_1',
        name: 'Mi preset',
        description: 'desc',
        imgUrl: 'https://img.png',
        ownerId: 'u1',
        state: 4,
        mainFrequency: NeomFrequency(frequency: 432.5),
      );
      final base = BaseItemMapper.fromChamberPreset(preset);
      expect(base.id, 'preset_1');
      expect(base.name, 'Mi preset');
      expect(base.description, 'desc');
      expect(base.imgUrl, 'https://img.png');
      expect(base.ownerId, 'u1');
      expect(base.state, 4);
      expect(base.duration, 433,
          reason: 'mapper usa mainFrequency.frequency.ceil() como duration');
      expect(base.permaUrl, 'https://img.png',
          reason: 'mapper usa imgUrl como permaUrl');
      expect(base.galleryUrls, isNull);
    });

    test('preset sin mainFrequency → duration 0', () {
      final preset = NeomChamberPreset();
      expect(BaseItemMapper.fromChamberPreset(preset).duration, 0);
    });
  });

  group('BaseItemMapper.fromPlayableItem', () {
    test('AppReleaseItem se redirige a fromAppReleaseItem', () {
      final r = AppReleaseItem(id: 'r1', name: 'X');
      final base = BaseItemMapper.fromPlayableItem(r);
      expect(base.id, 'r1');
      expect(base.name, 'X');
    });

    test('AppMediaItem se redirige a fromAppMediaItem', () {
      final m = AppMediaItem(id: 'm1', name: 'Y');
      final base = BaseItemMapper.fromPlayableItem(m);
      expect(base.id, 'm1');
      expect(base.name, 'Y');
    });
  });

  group('BaseItemMapper.fromDynamicItem', () {
    test('PlayableItem → mapea correctamente', () {
      final r = AppReleaseItem(id: 'r1', name: 'X');
      final base = BaseItemMapper.fromDynamicItem(r);
      expect(base.id, 'r1');
    });

    test('ExternalItem → mapea correctamente', () {
      final ext = ExternalItem(id: 'e1', name: 'Y');
      final base = BaseItemMapper.fromDynamicItem(ext);
      expect(base.id, 'e1');
    });

    test('item desconocido → BaseItem default vacío', () {
      // El método NO lanza para tipos desconocidos — devuelve BaseItem()
      final base = BaseItemMapper.fromDynamicItem('not_an_item');
      expect(base.id, '');
      expect(base.name, '');
    });
  });
}
