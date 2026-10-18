/// The gallery keeps a single switch: whenever the RTL toggle is on, the
/// sample copy shows Arabic; otherwise everything stays English.
bool demoArabic = false;

/// Picks between an English and an Arabic phrasing.
String tr(String en, String arText) => demoArabic ? arText : en;

/// A small noun table for the sample keys that double as labels, so the
/// keys themselves stay stable while the display localizes.
const Map<String, String> _nounsAr = {
  'pen': 'قلم',
  'pencil': 'قلم رصاص',
  'brush': 'فرشاة',
  'ink': 'حبر',
  'wash': 'غسلة',
  'gouache': 'غواش',
  'grid': 'شبكة',
  'list': 'قائمة',
  'kanban': 'كانبان',
  'dash': 'شرطة',
  'check': 'علامة صح',
  'idle': 'خامل',
  'loading': 'يحمّل',
  'success': 'نجاح',
  'error': 'خطأ',
  'outline': 'محدد',
  'solid': 'مصمت',
  'scribble': 'خربشة',
  'neutral': 'محايد',
  'accent': 'مميز',
  'danger': 'خطر',
  'fine': 'رقيق',
  'medium': 'متوسط',
  'broad': 'عريض',
  'open': 'فتح',
  'save': 'احفظ',
  'apple': 'تفاحة',
  'banana': 'موزة',
  'cherry': 'كرزة',
  'durian': 'دوريان',
  'elderberry': 'توت البيلسان',
  'fig': 'تين',
  'export': 'صدّر',
  'clear': 'امسح',
  'Ruled paper': 'ورق مسطر',
  'Graph paper': 'ورق مربعات',
  'Tracing paper': 'ورق شفاف',
};

/// Translates a sample-key noun; unknown keys pass through untouched.
String ar(String en) => demoArabic ? (_nounsAr[en] ?? en) : en;

const List<String> _monthsEn = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _monthsAr = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

const List<String> _weekdaysEn = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

const List<String> _weekdaysAr = ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح'];

/// Calendar month titles for the sample's date pickers.
List<String> get monthNames => demoArabic ? _monthsAr : _monthsEn;

/// Calendar weekday initials for the sample's date pickers.
List<String> get weekdayLabels => demoArabic ? _weekdaysAr : _weekdaysEn;
