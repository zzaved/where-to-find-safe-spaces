import 'package:share_plus/share_plus.dart';

import '../../features/spaces/domain/entities/safe_space.dart';
import '../../features/spaces/domain/entities/safety_label.dart';

/// Builds shareable text about a place and hands it to the native iOS/Android
/// share sheet.
class ShareService {
  const ShareService();

  Future<void> shareSpace(SafeSpace space) async {
    final buffer = StringBuffer()
      ..writeln('📍 ${space.name}')
      ..writeln('${_labelText(space.safetyLabel)} • Safe Score ${space.safetyScore}/100');

    if (space.address != null) buffer.writeln(space.address);
    if (space.classificationSummary != null) {
      buffer
        ..writeln()
        ..writeln(space.classificationSummary);
    }
    if (space.googleMapsUri != null) {
      buffer
        ..writeln()
        ..writeln('Ver no mapa: ${space.googleMapsUri}');
    }
    buffer
      ..writeln()
      ..writeln('Compartilhado via Safe Spaces 🏳️‍🌈');

    await Share.share(buffer.toString(), subject: 'Safe Spaces — ${space.name}');
  }

  String _labelText(SafetyLabel label) {
    return switch (label) {
      SafetyLabel.safe => '✅ Espaço seguro',
      SafetyLabel.notSafe => '⛔ Não recomendado',
      SafetyLabel.neutral => '⚠️ Sinais mistos',
    };
  }
}
