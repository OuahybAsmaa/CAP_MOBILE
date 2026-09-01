import 'package:cap_mobile/swapp/models/info_ot_item.dart';
import 'package:cap_mobile/swapp/models/info_transfert_item.dart';

abstract final class TransfertMapper {
  static InfoOtItem ot(Map<String, dynamic> json) => InfoOtItem.fromJson(json);
  static InfoTransfertFiche fiche(Map<String, dynamic> json) =>
      InfoTransfertFiche.fromJson(json);
}
