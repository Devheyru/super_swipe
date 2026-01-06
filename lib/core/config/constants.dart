// GENERATED CODE - DO NOT MODIFY BY HAND
// This file contains app-wide constants for Super Swipe
// Last updated: 2024-12-14

/// App-wide constants for configuration and magic numbers
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // ==================== API & ENVIRONMENT ====================
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.superswipe.com',
  );

  static const String openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');

  // ==================== FIRESTORE COLLECTIONS ====================
  static const String usersCollection = 'users';
  static const String recipesCollection = 'recipes';
  static const String ingredientsCollection = 'ingredients';

  // Sub-collections
  static const String pantrySubCollection = 'pantry';
  static const String savedRecipesSubCollection = 'savedRecipes';
  static const String recipeHistorySubCollection = 'recipeHistory';

  // ==================== PAGINATION ====================
  static const int pantryPageSize = 20;
  static const int recipesPageSize = 10;
  static const int historyPageSize = 50;

  // ==================== CARROTS SYSTEM ====================
  static const int maxCarrotsPerWeek = 5;
  static const int carrotCostPerRecipe = 1;
  static const int freeUserMaxCarrots = 5;
  static const int premiumUserMaxCarrots = 999; // Unlimited

  // ==================== CACHE CONFIGURATION ====================
  static const Duration cacheExpiration = Duration(minutes: 5);
  static const int maxCachedImages = 200;
  static const int imageCacheDays = 7;

  // ==================== ML KIT ====================
  static const double mlConfidenceThreshold = 0.5;
  static const int maxDetectedItems = 20;
  static const int maxSimilarIngredients = 5;

  // ==================== IMAGES ====================
  static const int imageMaxWidth = 1024;
  static const int imageMaxHeight = 1024;
  static const int imageQuality = 85; // 0-100
  static const int thumbnailSize = 200;

  // ==================== ANIMATION DURATIONS ====================
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  static const Duration veryLongAnimation = Duration(milliseconds: 800);

  // ==================== DEBOUNCE / THROTTLE ====================
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration autoSaveDebounce = Duration(milliseconds: 1000);

  // ==================== VALIDATION ====================
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minIngredientNameLength = 2;
  static const int maxIngredientNameLength = 50;
  static const int maxRecipeInstructions = 20;

  // ==================== ANALYTICS EVENTS ====================
  static const String eventRecipeSwipe = 'recipe_swipe';
  static const String eventRecipeUnlock = 'recipe_unlock';
  static const String eventPantryScan = 'pantry_scan';
  static const String eventPantryAdd = 'pantry_add';
  static const String eventSignUp = 'sign_up';
  static const String eventSignIn = 'sign_in';

  // ==================== ERROR CODES ====================
  static const String errorNoInternet = 'ERROR_NO_INTERNET';
  static const String errorFirestore = 'ERROR_FIRESTORE';
  static const String errorAuth = 'ERROR_AUTH';
  static const String errorMl = 'ERROR_ML';
  static const String errorPermission = 'ERROR_PERMISSION';
}

/// User-facing strings used throughout the app
class AppStrings {
  AppStrings._();

  // ==================== APP INFO ====================
  static const String appName = 'Super Swipe';
  static const String appTagline = 'Swipe for Your Perfect Meal';

  // ==================== ONBOARDING ====================
  static const String onboardingTitle1 = 'Swipe for Your Perfect Meal';
  static const String onboardingDesc1 =
      'Discover recipes tailored to your pantry. Swipe right to unlock delicious meals!';

  static const String onboardingTitle2 = 'Scan Your Pantry Instantly';
  static const String onboardingDesc2 =
      'Use your camera to detect ingredients. Building your pantry has never been easier.';

  static const String onboardingTitle3 = 'Unlock with Carrots';
  static const String onboardingDesc3 =
      'Get 5 free recipe unlocks per week. Premium users get unlimited access!';

  // ==================== ERRORS ====================
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNoInternet =
      'No internet connection. Please check your network.';
  static const String errorLoadingProfile =
      'Error loading profile. Please sign in again.';
  static const String errorLoadingPantry = 'Could not load your pantry items.';
  static const String errorNoCarrots =
      'Out of carrots! 🥕 Upgrade for unlimited access.';
  static const String errorCameraPermission =
      'Camera permission is required to scan ingredients.';
  static const String errorMlProcessing =
      'Could not detect ingredients. Try another photo.';

  // ==================== SUCCESS MESSAGES ====================
  static const String successRecipeUnlocked =
      'Recipe Unlocked & Saved! 🎉 -1 Carrot';
  static const String successPantryAdded = 'Added to your pantry!';
  static const String successPantryUpdated = 'Ingredient updated!';
  static const String successPantryDeleted = 'Ingredient removed!';
  static const String successSignUp = 'Account created successfully!';
  static const String successSignIn = 'Welcome back!';

  // ==================== BUTTONS ====================
  static const String buttonGetStarted = 'Get Started';
  static const String buttonSignIn = 'Sign In';
  static const String buttonSignUp = 'Sign Up';
  static const String buttonContinue = 'Continue';
  static const String buttonCancel = 'Cancel';
  static const String buttonSave = 'Save';
  static const String buttonDelete = 'Delete';
  static const String buttonConfirm = 'Confirm';
  static const String buttonUnlock = 'Unlock';
  static const String buttonAddToPantry = 'Add to Pantry';
  static const String buttonStartSwiping = 'Start Swiping';
  static const String buttonViewIngredients = 'View Ingredients';
  static const String buttonShowDirections = 'Show Directions';

  // ==================== EMPTY STATES ====================
  static const String emptyPantry = 'Your pantry is empty';
  static const String emptyPantryDesc =
      'Add ingredients to get personalized recipe suggestions.';
  static const String emptySavedRecipes = 'No saved recipes yet';
  static const String emptySavedRecipesDesc =
      'Unlock recipes by swiping right to build your collection.';
  static const String emptySearchResults = 'No ingredients found';

  // ==================== LOADING ====================
  static const String loadingGeneric = 'Loading...';
  static const String loadingProfile = 'Loading your profile...';
  static const String loadingPantry = 'Loading pantry...';
  static const String loadingRecipes = 'Finding recipes...';
  static const String scanningIngredients = 'Detecting ingredients...';
  static const String processingImage = 'Processing image...';
}

/// Asset paths for images, icons, and other resources
class AppAssets {
  AppAssets._();

  // ==================== IMAGES ====================
  static const String imagesPath = 'assets/images/';

  // Onboarding
  static const String onboarding1 = '${imagesPath}onboarding_1.png';
  static const String onboarding2 = '${imagesPath}onboarding_2.png';
  static const String onboarding3 = '${imagesPath}onboarding_3.png';

  // Placeholders
  static const String placeholderRecipe =
      'https://images.unsplash.com/photo-1737032571846-445ec57a41da?q=80';
  static const String placeholderProfile =
      '${imagesPath}profile_placeholder.png';

  // ==================== ICONS ====================
  static const String iconCarrot = '🥕';
  static const String iconFire = '🔥';
  static const String iconTimer = '⏱️';
  static const String iconStar = '⭐';

  // ==================== LOTTIE ANIMATIONS ====================
  static const String lottieLoading = 'assets/lottie/loading.json';
  static const String lottieSuccess = 'assets/lottie/success.json';
  static const String lottieError = 'assets/lottie/error.json';
  static const String lottieEmpty = 'assets/lottie/empty.json';
}

/// Route names for navigation
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String swipe = '/swipe';
  static const String pantry = '/pantry';
  static const String scan = '/scan';
  static const String scanResults = '/scan/results';
  static const String recipes = '/recipes';
  static const String recipeDetail = '/recipes/:id';
  static const String profile = '/profile';
  static const String settings = '/settings';
}
