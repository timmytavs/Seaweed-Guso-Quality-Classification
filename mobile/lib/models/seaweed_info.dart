class SeaweedInfo {
  final String id;
  final String scientificName;
  final String englishName;
  final String filipinoName;
  final String bisayaName;

  final String englishDescription;
  final String filipinoDescription;
  final String bisayaDescription;

  final String imagePath;

  const SeaweedInfo({
    required this.id,
    required this.scientificName,
    required this.englishName,
    required this.filipinoName,
    required this.bisayaName,
    required this.englishDescription,
    required this.filipinoDescription,
    required this.bisayaDescription,
    required this.imagePath,
  });

  String getName(String language) {
    switch (language) {
      case 'Filipino':
        return filipinoName;

      case 'Bisaya':
        return bisayaName;

      case 'English':
      default:
        return englishName;
    }
  }

  String getDescription(String language) {
    switch (language) {
      case 'Filipino':
        return filipinoDescription;

      case 'Bisaya':
        return bisayaDescription;

      case 'English':
      default:
        return englishDescription;
    }
  }

  bool matchesSearch(
    String query,
    String language,
  ) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return true;
    }

    return scientificName.toLowerCase().contains(normalizedQuery) ||
        getName(language).toLowerCase().contains(normalizedQuery);
  }
}