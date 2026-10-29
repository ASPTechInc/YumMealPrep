import 'package:flutter/material.dart';

import 'package:yummealprep/themes/colours.dart';
import 'package:yummealprep/utils/constants.dart';

/// The course a meal or recipe belongs to. The meal planner uses the same
/// values for the slots of a day.
enum MealType {
  appetisers(
    label: 'Appetisers',
    colour: AppColours.appetisers,
    icon: Icons.tapas,
    image: '${Constants.categoriesImageDir}appetisers.webp',
    description:
        'Find the perfect nibble, bite and nosh among these appetisers.',
  ),
  breakfast(
    label: 'Breakfast',
    colour: AppColours.breakfast,
    icon: Icons.free_breakfast,
    image: '${Constants.categoriesImageDir}breakfast.webp',
    description:
        'Start the day well with omelettes, pancakes, eggs, porridge and more.',
  ),
  lunch(
    label: 'Lunch',
    colour: AppColours.lunch,
    icon: Icons.lunch_dining,
    image: '${Constants.categoriesImageDir}lunch.webp',
    description: 'Give your lunch a makeover with these healthy ideas.',
  ),
  dinner(
    label: 'Dinner',
    colour: AppColours.dinner,
    icon: Icons.dinner_dining,
    image: '${Constants.categoriesImageDir}dinner.webp',
    description: 'Save yourself stress in the kitchen with these easy dinners.',
  ),
  dessert(
    label: 'Dessert',
    colour: AppColours.dessert,
    icon: Icons.cake,
    image: '${Constants.categoriesImageDir}dessert.webp',
    description: 'Easy desserts for effortless entertaining.',
  ),
  smoothies(
    label: 'Smoothies',
    colour: AppColours.smoothies,
    icon: Icons.local_drink,
    image: '${Constants.categoriesImageDir}smoothies.webp',
    description:
        'Drinks made by blending fruit and vegetables with a liquid base '
        'such as juice, milk, yoghurt or ice cream.',
  );

  const MealType({
    required this.label,
    required this.colour,
    required this.icon,
    required this.image,
    required this.description,
  });

  final String label;
  final Color colour;
  final IconData icon;

  /// A bundled image that represents the category.
  final String image;
  final String description;

  /// Reads a stored value. Accepts the enum name (`lunch`) and the label
  /// (`Lunch`), so older exports that stored labels still import.
  static MealType parse(Object? value) {
    for (final type in values) {
      if (type.name == value || type.label == value) return type;
    }
    return MealType.lunch;
  }
}
