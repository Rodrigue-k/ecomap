class CacheException implements Exception {
  final String message;

  CacheException([this.message = 'Une erreur de cache est survenue']);

  @override
  String toString() => 'CacheException: $message';
}

class ServerException implements Exception {
  final String message;

  ServerException([this.message = 'Une erreur serveur est survenue']);

  @override
  String toString() => 'ServerException: $message';
}
