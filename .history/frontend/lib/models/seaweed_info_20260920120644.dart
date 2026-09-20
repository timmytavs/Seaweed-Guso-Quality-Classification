import '../providers/seaweed_language_provider.dart';

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

  String getName(SeaweedLanguage language) {
  switch (language) {
    case SeaweedLanguage.english:
      return englishName;

    case SeaweedLanguage.filipino:
      return filipinoName;

    case SeaweedLanguage.bisaya:
      return bisayaName;
  }
}

String getDescription(SeaweedLanguage language) {
  switch (language) {
    case SeaweedLanguage.english:
      return englishDescription;

    case SeaweedLanguage.filipino:
      return filipinoDescription;

    case SeaweedLanguage.bisaya:
      return bisayaDescription;
  }
}

String getHabitat(SeaweedLanguage language) {
  switch (language) {
    case SeaweedLanguage.english:
      return englishHabitat;

    case SeaweedLanguage.filipino:
      return filipinoHabitat;

    case SeaweedLanguage.bisaya:
      return bisayaHabitat;
  }
}

String getIdentification(SeaweedLanguage language) {
  switch (language) {
    case SeaweedLanguage.english:
      return englishIdentification;

    case SeaweedLanguage.filipino:
      return filipinoIdentification;

    case SeaweedLanguage.bisaya:
      return bisayaIdentification;
  }
}

String getUses(SeaweedLanguage language) {
  switch (language) {
    case SeaweedLanguage.english:
      return englishUses;

    case SeaweedLanguage.filipino:
      return filipinoUses;

    case SeaweedLanguage.bisaya:
      return bisayaUses;
  }
}
}