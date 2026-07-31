import 'dart:math';

final Random _secureRandom = Random.secure();

String generateClientId() {
  final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

int? intOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String utcNow() => DateTime.now().toUtc().toIso8601String();

bool remoteVersionIsCurrent(Object? remoteValue, Object? localValue) {
  if (remoteValue == null || localValue == null) return true;
  final remote = DateTime.tryParse(remoteValue.toString());
  final local = DateTime.tryParse(localValue.toString());
  if (remote == null || local == null) return true;
  return !remote.isBefore(local);
}
