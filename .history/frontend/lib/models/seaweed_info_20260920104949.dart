class SeaweedInfo {
  final String id;

  final String scientificName;

  final String englishName;
  final String filipinoName;
  final String bisayaName;

  final String imagePath;

  final String englishDescription;
  final String filipinoDescription;
  final String bisayaDescription;

  final String englishHabitat;
  final String filipinoHabitat;
  final String bisayaHabitat;

  final String englishIdentification;
  final String filipinoIdentification;
  final String bisayaIdentification;

  final String englishUses;
  final String filipinoUses;
  final String bisayaUses;

  const SeaweedInfo({
    required this.id,
    required this.scientificName,
    required this.englishName,
    required this.filipinoName,
    required this.bisayaName,
    required this.imagePath,
    required this.englishDescription,
    required this.filipinoDescription,
    required this.bisayaDescription,
    required this.englishHabitat,
    required this.filipinoHabitat,
    required this.bisayaHabitat,
    required this.englishIdentification,
    required this.filipinoIdentification,
    required this.bisayaIdentification,
    required this.englishUses,
    required this.filipinoUses,
    required this.bisayaUses,
  });
}