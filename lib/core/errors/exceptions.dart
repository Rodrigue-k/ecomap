
class LocationServiceDisabledException implements Exception {
  final String message;
  LocationServiceDisabledException([
    this.message = 'Le service de localisation est désactivé',
  ]);

  @override
  String toString() => message;
}

class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException([
    this.message = 'Permission de localisation refusée',
  ]);

  @override
  String toString() => message;
}
