/// Pantry Constants and Data Structure
/// Defines the 3-layer category hierarchy for manual pantry entry
library;

class PantryCategory {
  final String title;
  final String icon;
  final List<PantrySubCategory> subCategories;

  const PantryCategory({
    required this.title,
    required this.icon,
    required this.subCategories,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'icon': icon,
      'subCategories': subCategories.map((x) => x.toMap()).toList(),
    };
  }

  factory PantryCategory.fromMap(Map<String, dynamic> map) {
    return PantryCategory(
      title: map['title'] as String? ?? '',
      icon: map['icon'] as String? ?? '',
      subCategories: List<PantrySubCategory>.from(
        (map['subCategories'] as List<dynamic>? ?? []).map<PantrySubCategory>(
          (x) => PantrySubCategory.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class PantrySubCategory {
  final String title;
  final List<String> items;

  const PantrySubCategory({required this.title, required this.items});

  Map<String, dynamic> toMap() {
    return {'title': title, 'items': items};
  }

  factory PantrySubCategory.fromMap(Map<String, dynamic> map) {
    return PantrySubCategory(
      title: map['title'] as String? ?? '',
      items: List<String>.from(map['items'] as List<dynamic>? ?? []),
    );
  }
}

// Data Population based on User Request
const List<PantryCategory> kPantryCategories = [
  PantryCategory(
    title: 'Proteins',
    icon: '🥩',
    subCategories: [
      PantrySubCategory(
        title: 'Chicken',
        items: ['Breast', 'Thighs', 'Wings', 'Whole Chicken', 'Ground Chicken'],
      ),
      PantrySubCategory(
        title: 'Beef',
        items: ['Ground Beef', 'Steak', 'Roast', 'Brisket'],
      ),
      PantrySubCategory(
        title: 'Pork',
        items: ['Chops', 'Loin', 'Bacon', 'Sausage', 'Ham'],
      ),
      PantrySubCategory(
        title: 'Seafood',
        items: ['Salmon', 'Tuna', 'Shrimp', 'Tilapia', 'Cod'],
      ),
      PantrySubCategory(
        title: 'Plant-Based',
        items: ['Tofu', 'Tempeh', 'Seitan', 'Plant-Based Meat'],
      ),
      PantrySubCategory(
        title: 'Deli',
        items: ['Turkey Slices', 'Ham Slices', 'Roast Beef Slices', 'Salami'],
      ),
    ],
  ),
  PantryCategory(
    title: 'Fruits',
    icon: '🍎',
    subCategories: [
      PantrySubCategory(
        title: 'Apples',
        items: ['Gala', 'Fuji', 'Honeycrisp', 'Granny Smith', 'Red Delicious'],
      ),
      PantrySubCategory(
        title: 'Berries',
        items: ['Strawberries', 'Blueberries', 'Raspberries', 'Blackberries'],
      ),
      PantrySubCategory(
        title: 'Citrus',
        items: ['Oranges', 'Lemons', 'Limes', 'Grapefruit'],
      ),
      PantrySubCategory(
        title: 'Tropical',
        items: ['Bananas', 'Pineapple', 'Mango', 'Kiwi', 'Papaya'],
      ),
      PantrySubCategory(
        title: 'Stone Fruits',
        items: ['Peaches', 'Nectarines', 'Plums', 'Cherries', 'Apricots'],
      ),
      PantrySubCategory(
        title: 'Melons',
        items: ['Watermelon', 'Cantaloupe', 'Honeydew'],
      ),
    ],
  ),
  PantryCategory(
    title: 'Vegetables',
    icon: '🥦',
    subCategories: [
      PantrySubCategory(
        title: 'Leafy Greens',
        items: ['Spinach', 'Kale', 'Lettuce', 'Arugula', 'Cabbage'],
      ),
      PantrySubCategory(
        title: 'Cruciferous',
        items: ['Broccoli', 'Cauliflower', 'Brussels Sprouts'],
      ),
      PantrySubCategory(
        title: 'Root',
        items: [
          'Carrots',
          'Potatoes',
          'Sweet Potatoes',
          'Onions',
          'Garlic',
          'Beets',
        ],
      ),
      PantrySubCategory(
        title: 'Peppers',
        items: ['Bell Peppers', 'Jalapenos', 'Chili Peppers'],
      ),
      PantrySubCategory(
        title: 'Squash',
        items: ['Zucchini', 'Cucumber', 'Butternut Squash', 'Pumpkin'],
      ),
      PantrySubCategory(
        title: 'Fungi',
        items: ['Button Mushrooms', 'Portobello', 'Shiitake'],
      ),
    ],
  ),
  PantryCategory(
    title: 'Dairy',
    icon: '🥛',
    subCategories: [
      PantrySubCategory(
        title: 'Milk',
        items: ['Whole', '2%', 'Skim', 'Almond', 'Oat', 'Soy'],
      ),
      PantrySubCategory(
        title: 'Cheese',
        items: ['Cheddar', 'Mozzarella', 'Parmesan', 'Feta', 'Cream Cheese'],
      ),
      PantrySubCategory(
        title: 'Yogurt',
        items: ['Greek', 'Plain', 'Vanilla', 'Fruit'],
      ),
      PantrySubCategory(title: 'Eggs', items: ['Large Eggs', 'Egg Whites']),
      PantrySubCategory(
        title: 'Cream',
        items: ['Heavy Cream', 'Sour Cream', 'Half & Half'],
      ),
      PantrySubCategory(title: 'Butter', items: ['Salted', 'Unsalted']),
    ],
  ),
  PantryCategory(
    title: 'Grains & Baking',
    icon: '🍞',
    subCategories: [
      PantrySubCategory(
        title: 'Flour',
        items: ['All-Purpose', 'Bread Flour', 'Whole Wheat', 'Almond Flour'],
      ),
      PantrySubCategory(
        title: 'Rice',
        items: ['White Rice', 'Brown Rice', 'Basmati', 'Jasmine'],
      ),
      PantrySubCategory(
        title: 'Pasta',
        items: ['Spaghetti', 'Penne', 'Fusilli', 'Macaroni'],
      ),
      PantrySubCategory(
        title: 'Bread',
        items: [
          'White Bread',
          'Whole Wheat Bread',
          'Sourdough',
          'Bagels',
          'Tortillas',
        ],
      ),
      PantrySubCategory(
        title: 'Baking Needs',
        items: [
          'Sugar',
          'Brown Sugar',
          'Baking Powder',
          'Baking Soda',
          'Yeast',
          'Chocolate Chips',
        ],
      ),
      PantrySubCategory(
        title: 'Oats',
        items: ['Rolled Oats', 'Instant Oats', 'Steel Cut Oats'],
      ),
    ],
  ),
  PantryCategory(
    title: 'Pantry Staples',
    icon: '🥫',
    subCategories: [
      PantrySubCategory(
        title: 'Oils',
        items: ['Olive Oil', 'Vegetable Oil', 'Coconut Oil', 'Sesame Oil'],
      ),
      PantrySubCategory(
        title: 'Condiments',
        items: [
          'Ketchup',
          'Mustard',
          'Mayonnaise',
          'Soy Sauce',
          'Hot Sauce',
          'Vinegar',
        ],
      ),
      PantrySubCategory(
        title: 'Canned Goods',
        items: ['Beans', 'Tomatoes', 'Corn', 'Soup', 'Tuna'],
      ),
      PantrySubCategory(
        title: 'Spices',
        items: [
          'Salt',
          'Pepper',
          'Garlic Powder',
          'Onion Powder',
          'Cumin',
          'Paprika',
          'Cinnamon',
        ],
      ),
      PantrySubCategory(
        title: 'Broth',
        items: ['Chicken Broth', 'Beef Broth', 'Vegetable Broth'],
      ),
    ],
  ),
  PantryCategory(
    title: 'Frozen',
    icon: '❄️',
    subCategories: [
      PantrySubCategory(
        title: 'Vegetables',
        items: [
          'Frozen Peas',
          'Frozen Corn',
          'Frozen Mixed Veggies',
          'Frozen Spinach',
        ],
      ),
      PantrySubCategory(
        title: 'Fruits',
        items: ['Frozen Berries', 'Frozen Mango', 'Frozen Peaches'],
      ),
      PantrySubCategory(title: 'Meals', items: ['Pizza', 'TV Dinners']),
      PantrySubCategory(title: 'Desserts', items: ['Ice Cream', 'Popsicles']),
    ],
  ),
  PantryCategory(
    title: 'Snacks',
    icon: '🍿',
    subCategories: [
      PantrySubCategory(
        title: 'Chips',
        items: ['Potato Chips', 'Tortilla Chips', 'Pretzels'],
      ),
      PantrySubCategory(
        title: 'Nuts',
        items: ['Almonds', 'Peanuts', 'Cashews', 'Walnuts'],
      ),
      PantrySubCategory(title: 'Crackers', items: ['Saltines', 'Wheat Thins']),
      PantrySubCategory(
        title: 'Sweets',
        items: ['Cookies', 'Candy', 'Chocolate'],
      ),
    ],
  ),
  PantryCategory(
    title: 'Beverages',
    icon: '🥤',
    subCategories: [
      PantrySubCategory(
        title: 'Water',
        items: ['Bottled Water', 'Sparkling Water'],
      ),
      PantrySubCategory(
        title: 'Soda',
        items: ['Cola', 'Lemon-Lime', 'Root Beer'],
      ),
      PantrySubCategory(
        title: 'Juice',
        items: ['Orange Juice', 'Apple Juice', 'Grape Juice'],
      ),
      PantrySubCategory(
        title: 'Coffee & Tea',
        items: ['Ground Coffee', 'Tea Bags'],
      ),
      PantrySubCategory(title: 'Alcohol', items: ['Beer', 'Wine', 'Liquor']),
    ],
  ),
  PantryCategory(
    title: 'Other',
    icon: '📦',
    subCategories: [
      PantrySubCategory(
        title: 'Misc',
        items: ['Pet Food', 'Paper Goods', 'Cleaning Supplies'],
      ),
    ],
  ),
];
