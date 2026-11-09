import '../../domain/entities/claim.dart';

class MasjidAccessModel extends MasjidAccess {
  const MasjidAccessModel({required super.canManage, super.claimStatus});

  static const columns = 'can_manage,claim_status';

  factory MasjidAccessModel.fromJson(Map<String, dynamic> j) =>
      MasjidAccessModel(
        canManage: j['can_manage'] as bool? ?? false,
        claimStatus: j['claim_status'] == null
            ? null
            : ClaimStatus.values.byName(j['claim_status'] as String),
      );
}

/// Phone as the server stores it: digits, optional leading +.
String normalisePhone(String raw) {
  final t = raw.trim();
  final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
  return t.startsWith('+') ? '+$digits' : digits;
}
