class KomandaApiConfig {
  const KomandaApiConfig._();

  /// URL pública del backend en HostGator.
  /// No debe terminar con "/".
  static const String baseUrl = String.fromEnvironment(
    'KOMANDA_API_URL',
    defaultValue: 'https://grolarstudios.com/restaurant-api/public',
  );

  static const Duration timeout = Duration(seconds: 20);

  static bool get isConfigured {
    final url = baseUrl.trim();

    return url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'));
  }
}