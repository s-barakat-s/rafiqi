enum WirdReaderMode { focus, list, reading }

extension WirdReaderModeDetails on WirdReaderMode {
  String get label => switch (this) {
    WirdReaderMode.focus => 'البطاقات',
    WirdReaderMode.list => 'القائمة',
    WirdReaderMode.reading => 'القراءة',
  };

  String get subtitle => switch (this) {
    WirdReaderMode.focus => 'ذكر واحد في كل مرة',
    WirdReaderMode.list => 'جميع الأذكار في بطاقات',
    WirdReaderMode.reading => 'قراءة هادئة بدون تفاعل',
  };
}
