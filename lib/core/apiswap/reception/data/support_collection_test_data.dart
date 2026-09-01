// Donnees de test de la couche API Swapp.

import 'package:cap_mobile/swapp/models/support_collection_item.dart';
import 'package:cap_mobile/swapp/models/bl_collection_item.dart';

/// Données démo — supports d'un BL (1 support de 10 colis par unité annoncée).
abstract final class SupportCollectionDemoData {
  /// Colis contenus dans un support en démo.
  static const _colisParSupport = 10;

  /// Premier numéro de support de la série démo.
  static const _premierSupport = 42;

  static List<SupportCollectionItem> forBl(BlCollectionItem bl) {
    return [
      for (var i = 0; i < bl.total; i++)
        SupportCollectionItem(
          numSupport:
              'M0237'
              '${(_premierSupport + i).toString().padLeft(8, '0')}',
          total: _colisParSupport,
          restant: _colisParSupport,
        ),
    ];
  }
}
