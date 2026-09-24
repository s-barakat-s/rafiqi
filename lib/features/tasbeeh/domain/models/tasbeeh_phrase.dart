class TasbeehPhrase {
  const TasbeehPhrase({
    required this.id,
    required this.text,
    this.isBuiltIn = true,
  });

  final String id;
  final String text;
  final bool isBuiltIn;

  factory TasbeehPhrase.fromJson(Map<String, dynamic> json) => TasbeehPhrase(
    id: json['id'] as String,
    text: json['text'] as String,
    isBuiltIn: json['isBuiltIn'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isBuiltIn': isBuiltIn,
  };

  static const defaultPhrases = [
    TasbeehPhrase(id: 'subhan_allah', text: 'سبحان الله'),
    TasbeehPhrase(id: 'alhamdulillah', text: 'الحمد لله'),
    TasbeehPhrase(id: 'allahu_akbar', text: 'الله أكبر'),
    TasbeehPhrase(id: 'la_ilaha_illa_allah', text: 'لا إله إلا الله'),
    TasbeehPhrase(id: 'astaghfirullah', text: 'أستغفر الله'),
    TasbeehPhrase(id: 'subhan_allahi_wa_bihamdih', text: 'سبحان الله وبحمده'),
    TasbeehPhrase(id: 'salat_ala_alnabi', text: 'الصلاة على النبي ﷺ'),
  ];

  static TasbeehPhrase builtInById(String id) => defaultPhrases.firstWhere(
    (phrase) => phrase.id == id,
    orElse: () => defaultPhrases.first,
  );
}
