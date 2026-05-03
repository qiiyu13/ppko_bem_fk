class SyncConflictException implements Exception {
  final String message;
  final Map<String, dynamic> serverData;
  final Map<String, dynamic> localData;

  SyncConflictException({
    required this.message,
    required this.serverData,
    required this.localData,
  });

  @override
  String toString() => 'SyncConflictException: $message';
}
