import 'package:flutter/material.dart';
import 'package:yummealprep/models/category_model.dart';
import 'package:yummealprep/models/meal_item_model.dart';
import 'package:yummealprep/models/meal_slot_model.dart';
import 'package:yummealprep/utils/constants.dart';

// Categories
List<Category> getCategories() {
  return [
    Category(
        description:
            'Find the perfect nibble, bite and nosh among these killer appetiser recipes',
        image: '${Constants.recipesImageDir}recipe_appetisers.png',
        name: describeCategoryEnum(Categories.appetisers)),
    Category(
        description:
            'Explore loads of brilliant healthy breakfast recipes like omelettes, pancakes, eggs, porridge and more! ',
        image: '${Constants.recipesImageDir}recipe_breakfast.png',
        name: describeCategoryEnum(Categories.breakfast)),
    Category(
        description:
            'Give your lunch a makeover with these healthy lunch recipes',
        image: '${Constants.recipesImageDir}recipe_lunch.png',
        name: describeCategoryEnum(Categories.lunch)),
    Category(
        description:
            'Save yourself stress in the kitchen with these easy dinner recipes',
        image: '${Constants.recipesImageDir}recipe_dinner.png',
        name: describeCategoryEnum(Categories.dinner)),
    Category(
        description: 'Easy desserts for effortless entertaining',
        image: '${Constants.recipesImageDir}recipe_dessert.png',
        name: describeCategoryEnum(Categories.dessert)),
    Category(
        description:
            'A beverage made by puréeing ingredients in a blender with a liquid base like fruit juice, milk, yoghurt or icecream.',
        image: '${Constants.recipesImageDir}smoothie.png',
        name: describeCategoryEnum(Categories.smoothies)),
  ];
}

String describeCategoryEnum(category) {
  switch (category) {
    case Categories.appetisers:
      return 'Appetisers';
    case Categories.breakfast:
      return 'Breakfast';
    case Categories.lunch:
      return 'Lunch';
    case Categories.dinner:
      return 'Dinner';
    case Categories.dessert:
      return 'Dessert';
    case Categories.smoothies:
      return 'Smoothies';
    default:
      return 'Appetiser';
  }
}

// Meals

List<MealItemModel> getMeals() {
  return const [
    MealItemModel(
      name: 'Pancake and Scrambled Eggs',
      category: 'Meals',
      description: 'Good food',
      drink: 'Mauby',
      id: '121',
      image: '${Constants.imageDir}food1.png',
      isMealLiked: false,
      nutritionFacts: 'fats.png',
      searchKeywords: ['p', 'pa', 'pan'],
      sideDish: 'Macaroni Salad',
      type: 'Breakfast',
    ),
    MealItemModel(
      name: 'Pancake and Scrambled Eggs',
      category: 'Meals',
      description: 'Good food',
      drink: 'Mauby',
      id: '121',
      image: '${Constants.imageDir}food2.png',
      isMealLiked: false,
      nutritionFacts: 'fats.png',
      searchKeywords: ['p', 'pa', 'pan'],
      sideDish: 'Macaroni Salad',
      type: 'Breakfast',
    ),
    MealItemModel(
      name: 'Pancake and Scrambled Eggs',
      category: 'Meals',
      description: 'Good food',
      drink: 'Mauby',
      id: '121',
      image: '${Constants.imageDir}food3.png',
      isMealLiked: false,
      nutritionFacts: 'fats.png',
      searchKeywords: ['p', 'pa', 'pan'],
      sideDish: 'Macaroni Salad',
      type: 'Breakfast',
    ),
    MealItemModel(
      name: 'Pancake and Scrambled Eggs',
      category: 'Meals',
      description: 'Good food',
      drink: 'Mauby',
      id: '121',
      image: '${Constants.imageDir}food4.png',
      isMealLiked: false,
      nutritionFacts: 'fats.png',
      searchKeywords: ['p', 'pa', 'pan'],
      sideDish: 'Macaroni Salad',
      type: 'Breakfast',
    ),
    MealItemModel(
      name: 'Pancake and Scrambled Eggs',
      category: 'Meals',
      description: 'Good food',
      drink: 'Mauby',
      id: '121',
      image: '${Constants.imageDir}food5.png',
      isMealLiked: false,
      nutritionFacts: 'fats.png',
      searchKeywords: ['p', 'pa', 'pan'],
      sideDish: 'Macaroni Salad',
      type: 'Breakfast',
    ),
    MealItemModel(
      name: 'Quaker Oats',
      category: 'Meals',
      description: 'Good food',
      drink: 'Mauby',
      id: '121',
      image: '${Constants.imageDir}food6.png',
      isMealLiked: false,
      nutritionFacts: 'fats.png',
      searchKeywords: ['p', 'pa', 'pan'],
      sideDish: 'Macaroni Salad',
      type: 'Breakfast',
    ),
    MealItemModel(
      name: 'Lasagne',
      category: 'Meals',
      description: 'Good food',
      drink: 'Mauby',
      id: '121',
      image: '${Constants.imageDir}food7.png',
      isMealLiked: false,
      nutritionFacts: 'fats.png',
      searchKeywords: ['p', 'pa', 'pan'],
      sideDish: 'Macaroni Salad',
      type: 'Breakfast',
    ),
    MealItemModel(
      name: 'Icecream',
      category: 'Meals',
      description: 'Good food',
      drink: '',
      id: '12109',
      image: '${Constants.imageDir}food8.png',
      isMealLiked: false,
      nutritionFacts: 'fats.png',
      searchKeywords: ['p', 'pa', 'pan'],
      sideDish: '',
      type: 'Dessert',
    ),
  ];
}

List<MealSlot> getMealSlots() {
  return [
    MealSlot(
        name: describeCategoryEnum(Categories.appetisers),
        colour: describeMealSlotColourEnum(Colours.green)),
    MealSlot(
        name: describeCategoryEnum(Categories.breakfast),
        colour: describeMealSlotColourEnum(Colours.amber)),
    MealSlot(
        name: describeCategoryEnum(Categories.lunch),
        colour: describeMealSlotColourEnum(Colours.brown)),
    MealSlot(
        name: describeCategoryEnum(Categories.dinner),
        colour: describeMealSlotColourEnum(Colours.purple)),
    MealSlot(
        name: describeCategoryEnum(Categories.dessert),
        colour: describeMealSlotColourEnum(Colours.orange)),
    MealSlot(
        name: describeCategoryEnum(Categories.smoothies),
        colour: describeMealSlotColourEnum(Colours.pink)),
  ];
}

Color describeMealSlotColourEnum(colour) {
  switch (colour) {
    case Colours.green:
      return Colors.green;
    case Colours.amber:
      return Colors.amber;
    case Colours.brown:
      return Colors.brown;
    case Colours.purple:
      return Colors.purple;
    case Colours.orange:
      return Colors.orange;
    case Colours.pink:
      return Colors.pink;
    default:
      return Colors.green;
  }
}

Color getMealSlotBgColourBasedOnMealType(type) {
  switch (type) {
    case 'Appetisers':
      return Colors.green;
    case 'Breakfast':
      return Colors.amber;
    case 'Lunch':
      return Colors.blue;
    case 'Dinner':
      return Colors.indigo;
    case 'Dessert':
      return Colors.orange;
    case 'Smoothies':
      return Colors.pink;
    default:
      return Colors.green;
  }
}
