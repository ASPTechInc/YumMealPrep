abstract final class Constants {
  static const String appName = 'YumMealPrep';
  static const String developer = 'ASPTechnologies Incorporation';
  static const String firstYear = '2022';

  // Links. Everything else the app shows is bundled and works offline.
  static const String sourceCodeUrl =
      'https://github.com/ASPTechInc/YumMealPrep';
  static const String issuesUrl = '$sourceCodeUrl/issues/new/choose';

  // Bundled assets
  static const String imageDir = 'assets/images/';
  static const String appImageDir = '${imageDir}app/';
  static const String mealsImageDir = '${imageDir}meals/';
  static const String recipesImageDir = '${imageDir}recipes/';
  static const String categoriesImageDir = '${imageDir}categories/';
  static const String photoCredits = '${imageDir}CREDITS.md';
  static const String appLogo = '${appImageDir}yummealprep-logo.png';
  static const String noDataImage = '${appImageDir}empty.png';
  static const String seedData = 'assets/data/seed.json';
  static const String changelog = 'CHANGELOG.md';
  static const String licence = 'LICENSE';
  static const String privacyPolicy = 'PRIVACY_POLICY.md';

  /// Suggestions offered when adding a meal. Any other text is allowed.
  static const List<String> drinkSuggestions = [
    'Chocolate Tea',
    'Coconut Water',
    'Coffee',
    'Juice',
    'Mauby',
    'Milk',
    'Sorrel',
    'Tea',
    'Water',
  ];

  /// Side dishes offered as chips when adding a meal.
  static const List<String> sideDishSuggestions = [
    'Baked Beans',
    'Baked Potatoes',
    'Boiled Corn',
    'Broccoli',
    'Coleslaw',
    'Dinner Rolls',
    'French Fries',
    'Fried Plantains',
    'Fruit Salad',
    'Garlic Bread',
    'Macaroni Salad',
    'Mashed Potatoes',
    'Potato Salad',
    'Roast Potatoes',
    'Roasted Vegetables',
    'Steamed Vegetables',
    'Sweat Ground Provisions',
    'Toast',
    'Tossed Salad',
  ];
}
