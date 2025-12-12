class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final String description;
  final List<String> ingredients;
  final int energyLevel; // 0-3
  final int timeMinutes;
  final int calories;
  final List<String> equipment; // simple string labels for mock icons

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.ingredients,
    this.energyLevel = 2,
    required this.timeMinutes,
    required this.calories,
    required this.equipment,
  });
}

