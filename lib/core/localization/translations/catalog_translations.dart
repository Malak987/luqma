import 'package:flutter/widgets.dart';

class CatalogTranslations {
  CatalogTranslations(this.locale);
  final Locale locale;
  bool get _ar => locale.languageCode == 'ar';

  String get retry => _ar ? 'حاول مرة أخرى' : 'Try again';
  String get loadMore => _ar ? 'عرض المزيد من المتاجر' : 'Show more stores';

  String get phone => _ar ? 'الهاتف' : 'Phone';
  String get all => _ar ? 'الكل' : 'All';
  String get cuisines => _ar ? 'المطابخ' : 'Cuisines';
  String get cuisinesHint =>
      _ar ? 'اختر مطبخك المفضل' : 'Find your favourite cuisine';
  String get stores => _ar ? 'المتاجر' : 'Stores';
  String get storesHint =>
      _ar ? 'اكتشف المتاجر المناسبة لذوقك' : 'Discover something you will love';
  String get openNowFilter => _ar ? 'المفتوح الآن فقط' : 'Open now only';
  String get clearFilters => _ar ? 'مسح التصفية' : 'Clear filters';
  String get open => _ar ? 'مفتوح الآن' : 'Open now';
  String get closed => _ar ? 'مغلق الآن' : 'Closed now';
  String get loadingCuisines => _ar ? 'جارٍ تحميل المطابخ' : 'Loading cuisines';
  String get cuisinesFailed => _ar
      ? 'تعذر تحميل المطابخ. يمكنك تصفح كل المتاجر.'
      : 'Cuisines could not load. You can still browse all stores.';
  String get cuisinesEmpty => _ar
      ? 'لا توجد مطابخ متاحة حاليًا'
      : 'No cuisines are available right now';
  String get loadingStores => _ar ? 'جارٍ تحميل المتاجر' : 'Loading stores';
  String get storesFailed =>
      _ar ? 'تعذر تحميل المتاجر' : 'We could not load the stores';
  String get storesEmpty =>
      _ar ? 'لا توجد متاجر تطابق اختياراتك' : 'No stores match your selection';
  String get loadingMore => _ar ? 'جارٍ تحميل المزيد' : 'Loading more';
  String get paginationFailed => _ar
      ? 'تعذر تحميل المزيد. المتاجر السابقة ما زالت متاحة.'
      : 'More stores could not load. Your existing results are still here.';
  String get menu => _ar ? 'قائمة الطعام' : 'Menu';
  String get menuCategories => _ar ? 'الأقسام' : 'Categories';
  String get menuCategoriesHint =>
      _ar ? 'اختر قسمًا لتصفح منتجاته' : 'Choose a category to explore';
  String get allCategories => _ar ? 'كل الأقسام' : 'All categories';
  String get loadingMenuCategories =>
      _ar ? 'جارٍ تحميل الأقسام' : 'Loading categories';
  String get menuCategoriesFailed => _ar
      ? 'تعذر تحميل الأقسام. يمكنك تصفح كل المنتجات.'
      : 'Categories could not load. You can still browse all products.';
  String get menuCategoriesEmpty => _ar
      ? 'لا توجد أقسام متاحة حاليًا'
      : 'No categories are available right now';
  String get products => _ar ? 'المنتجات' : 'Products';
  String get productsHint =>
      _ar ? 'اكتشف قائمة المتجر' : 'Explore this store’s menu';
  String get loadingProducts =>
      _ar ? 'جارٍ تحميل المنتجات' : 'Loading products';
  String get productsFailed =>
      _ar ? 'تعذر تحميل المنتجات' : 'We could not load the products';
  String get productsEmpty => _ar
      ? 'لا توجد منتجات تطابق اختياراتك'
      : 'No products match your selection';
  String get loadMoreProducts =>
      _ar ? 'عرض المزيد من المنتجات' : 'Show more products';
  String get productPaginationFailed => _ar
      ? 'تعذر تحميل المزيد. المنتجات السابقة ما زالت متاحة.'
      : 'More products could not load. Your existing results are still here.';
  String get searchProducts => _ar ? 'ابحث في القائمة' : 'Search the menu';
  String get clearSearch => _ar ? 'مسح البحث' : 'Clear search';
  String get productFilters => _ar ? 'تصفية المنتجات' : 'Filter products';
  String get minPrice => _ar ? 'أقل سعر' : 'Minimum price';
  String get maxPrice => _ar ? 'أعلى سعر' : 'Maximum price';
  String get applyPrices => _ar ? 'تطبيق السعر' : 'Apply prices';
  String get invalidPrices => _ar
      ? 'أدخل أسعارًا صحيحة غير سالبة، وأقل سعر لا يتجاوز الأعلى.'
      : 'Enter valid nonnegative prices, with minimum no greater than maximum.';
  String get saleOnly => _ar ? 'العروض فقط' : 'On sale only';
  String get productDetails => _ar ? 'تفاصيل المنتج' : 'Product details';
  String get sale => _ar ? 'عرض' : 'On sale';
  String get price => _ar ? 'السعر' : 'Price';
  String get previousPrice => _ar ? 'السعر السابق' : 'Previous price';
  String get soldByWeight => _ar ? 'يباع بالوزن' : 'Sold by weight';
  String get weight => _ar ? 'الوزن' : 'Weight';
  String get options => _ar ? 'اختر أحد الخيارات' : 'Choose an option';
  String get addons => _ar ? 'إضافات اختيارية' : 'Optional addons';
  String get clearOption => _ar ? 'إلغاء اختيار الخيار' : 'Clear option';
  String get saveChoices => _ar ? 'حفظ الاختيارات' : 'Save choices';
  String get localChoicesNotice => _ar
      ? 'تُحفظ اختياراتك أثناء تصفح هذا المتجر فقط، ولا تُضاف إلى سلة.'
      : 'Choices stay while you browse this store. Nothing is added to a cart.';
  String get noCustomizations => _ar
      ? 'لا توجد خيارات أو إضافات لهذا المنتج'
      : 'This product has no options or addons';

  String get restaurants => _ar ? 'المطاعم' : 'Restaurants';
  String get restaurantsUnavailable => _ar
      ? 'تعذر تحميل قسم المطاعم. حاول مرة أخرى.'
      : 'We could not load the restaurants section. Please try again.';
  String get restaurantsCategoryUnsupported => _ar
      ? 'لا يوجد تصنيف مطاعم معروف متاح حاليًا'
      : 'No recognized restaurants category is available right now';
  String get searchRestaurants =>
      _ar ? 'ابحث عن مطعم...' : 'Search for a restaurant...';
  String get searchStores => _ar ? 'ابحث عن متجر...' : 'Search for a store...';
  String get suggestedRestaurants =>
      _ar ? 'المطاعم المقترحة' : 'Suggested restaurants';
  String get suggestedRestaurantsHint => _ar
      ? 'مختارة بعناية لتناسب ذوقك اليوم'
      : 'Hand-picked to suit your taste today';
  String get suggestedStores => _ar ? 'المتاجر المقترحة' : 'Suggested stores';
  String get suggestedStoresHint =>
      _ar ? 'اكتشف المتاجر المناسبة لذوقك' : 'Discover something you will love';
  String get showAll => _ar ? 'عرض الكل' : 'Show all';
  String get filters => _ar ? 'التصفية' : 'Filters';
  String get done => _ar ? 'تم' : 'Done';
  String get notifications => _ar ? 'الإشعارات' : 'Notifications';
  String get noSearchResults => _ar
      ? 'لا توجد نتائج مطابقة بين المتاجر المحمّلة'
      : 'No loaded stores match your search';
  String get add => _ar ? 'إضافة' : 'Add';
  String get addToCart => _ar ? 'إضافة إلى السلة' : 'Add to cart';
  String get share => _ar ? 'مشاركة' : 'Share';
  String get favorite => _ar ? 'إضافة إلى المفضلة' : 'Add to favourites';
  String get openStatusLabel => _ar ? 'الحالة' : 'Status';

  /// Displays the supplied number without currency, unit or guessed rounding.
  String number(num value) {
    var text = value.toString();
    if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
    if (!_ar) return text;
    const digits = '٠١٢٣٤٥٦٧٨٩';
    return text
        .replaceAllMapped(
          RegExp(r'[0-9]'),
          (match) => digits[int.parse(match[0]!)],
        )
        .replaceAll('.', '٫');
  }

  // ---- Money ---------------------------------------------------------------

  /// The currency of the catalog. The API does not return one yet (see
  /// BACKEND_MISSING_DATA.md), so the app-wide default is declared here only.
  String get currency => _ar ? 'ج.م' : 'EGP';

  /// `number` + currency, e.g. "٢٥ ج.م" / "25 EGP".
  String money(num value) => '${number(value)} $currency';

  /// Whole number with a thousands separator, e.g. "٢٬٥٠٠" / "2,500".
  String grouped(num value) {
    final text = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(_ar ? '٬' : ',');
      buffer.write(text[i]);
    }
    return _ar ? _toArabicDigits(buffer.toString()) : buffer.toString();
  }

  String groupedMoney(num value) => '${grouped(value)} $currency';

  String _toArabicDigits(String input) {
    const digits = '٠١٢٣٤٥٦٧٨٩';
    return input.replaceAllMapped(
      RegExp(r'[0-9]'),
      (match) => digits[int.parse(match[0]!)],
    );
  }

  // ---- Filter sheet --------------------------------------------------------

  String get filterSubtitle => _ar ? '(فلترة البحث)' : '(Search filter)';
  String get diningOption => _ar ? 'طريقة الطلب' : 'Dining option';
  String get delivery => _ar ? 'توصيل' : 'Delivery';
  String get pickup => _ar ? 'استلام من الفرع' : 'Pickup';
  String get filterCategories => _ar ? 'الفئات' : 'Categories';
  String get moreCategories => _ar ? '+ المزيد من الفئات' : '+ More categories';
  String get fewerCategories => _ar ? 'عرض أقل' : 'Show less';
  String get sortBy => _ar ? 'ترتيب حسب' : 'Sort by';
  String get sortRecommended => _ar ? 'الأكثر ترشيحًا' : 'Most recommended';
  String get sortPopular => _ar ? 'الأكثر شهرة' : 'Most popular';
  String get sortNearest => _ar ? 'الأقرب إليك' : 'Nearest';
  String get applyFilters => _ar ? 'تطبيق التصفية' : 'Apply filters';
  String get clearAll => _ar ? 'مسح الكل' : 'Clear all';
  String get close => _ar ? 'إغلاق' : 'Close';

  // ---- Price range ---------------------------------------------------------

  String get priceRange => _ar ? 'نطاق السعر' : 'Price range';
  String get anyPrice => _ar ? 'كل الأسعار' : 'Any price';
  String get setPriceRange => _ar ? 'تحديد نطاق السعر' : 'Set price range';
  String get selectedBudget => _ar ? 'الميزانية المختارة:' : 'Selected budget:';
  String get currentRange => _ar ? 'النطاق المحدد حاليًا:' : 'Current range:';
  String get applyPriceRange =>
      _ar ? 'تطبيق النطاق السعري' : 'Apply price range';
  String priceRangeText(num min, num max) => _ar
      ? 'من ${groupedMoney(min)} إلى ${groupedMoney(max)}'
      : 'From ${groupedMoney(min)} to ${groupedMoney(max)}';

  // ---- Product sheet -------------------------------------------------------

  String get multipleLabel => _ar ? 'متعدد' : 'Multiple';
  String get chooseOne => _ar ? 'اختر خيارًا واحدًا' : 'Choose one';
  String get chooseAny => _ar ? 'اختر ما يناسب ذوقك' : 'Pick what you like';
  String get free => _ar ? 'مجانًا' : 'Free';
  String get readMore => _ar ? 'قراءة المزيد' : 'Read more';
  String get readLess => _ar ? 'عرض أقل' : 'Show less';
  String discountPercent(int percent) =>
      _ar ? 'خصم ${number(percent)}%' : '$percent% off';

  // ---- Store info ----------------------------------------------------------

  String distanceKm(num value) =>
      _ar ? '${number(value)} كم' : '${number(value)} km';
  String ratingCount(int count) =>
      _ar ? '(${number(count)} تقييم)' : '($count reviews)';
  String ratingWithCount(num rating, int count) => _ar
      ? 'التقييم ${number(rating)} من ٥، ${number(count)} تقييم'
      : 'Rated ${number(rating)} out of 5, $count reviews';
  String deliveryMinutes(int minutes) =>
      _ar ? '${number(minutes)} دقيقة' : '$minutes min';
  /// A published delivery fee. Zero is the API's "not provided" value, so it
  /// is never rendered as "Free"; callers hide the field in that case.
  String deliveryFee(num fee) => money(fee);
  String priceLevelValue(String value) =>
      _ar ? 'مستوى السعر: $value' : 'Price level: $value';
  String get openLocation => _ar ? 'فتح الموقع' : 'Open location';
  String get locationOpenFailed => _ar
      ? 'تعذر فتح موقع المطعم.'
      : 'We could not open this restaurant location.';
  String priceBand(num from, num to) =>
      from == to ? money(from) : '${number(from)} - ${number(to)} $currency';
  String get openingHours => _ar ? 'ساعات العمل' : 'Opening hours';

  /// Formats an API clock value (`09:00:00`) for display (`9:00 AM` / `٩:٠٠ ص`).
  /// Returns null for anything that is not a real time of day, so the caller
  /// omits it instead of printing a raw server string.
  String? clockTime(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?').firstMatch(text);
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    final isAfternoon = hour >= 12;
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final minuteText = _toArabicDigits(minute.toString().padLeft(2, '0'));
    final suffix = _ar
        ? (isAfternoon ? 'م' : 'ص')
        : (isAfternoon ? 'PM' : 'AM');
    return '${number(hour12)}:$minuteText $suffix';
  }

  /// `9:00 AM – 11:00 PM`, or null when either end is not a real time.
  String? openingWindow(String? openTime, String? closeTime) {
    final open = clockTime(openTime);
    final close = clockTime(closeTime);
    if (open == null || close == null) return null;
    return '$open – $close';
  }

  /// Shown on a closed store: `Opens 10:00 AM` / `يفتح ١٠:٠٠ ص`.
  String? opensAt(String? openTime) {
    final open = clockTime(openTime);
    if (open == null) return null;
    return _ar ? 'يفتح $open' : 'Opens $open';
  }

  String get invalidNavigation => _ar
      ? 'تعذر فتح هذه الصفحة. ارجع واختر متجرًا أو قسمًا.'
      : 'This page could not be opened. Go back and select a store or category.';
}
