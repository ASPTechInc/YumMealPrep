import 'package:yummealprep/utils/constants.dart';

// ignore_for_file: prefer_typing_uninitialized_variables
class MealPlannerItemModel {
  final String? category;
  final String? description;
  final dateCreated;
  final dateSelected; //DateTime
  final String? drink;
  final String? id;
  final String? image;
  final bool? isMealInMealPlanner;
  final bool? isMealLiked;
  final String? name;
  final nutritionFacts;
  final int? selectedDayCalendarNum;
  final searchKeywords;
  final String? sideDish;
  final String? timestamp;
  final String? type;

  const MealPlannerItemModel({
    this.category,
    this.dateCreated,
    this.dateSelected,
    this.description,
    this.drink,
    this.id,
    this.image,
    this.isMealLiked,
    this.isMealInMealPlanner,
    this.name,
    this.nutritionFacts,
    this.searchKeywords,
    this.selectedDayCalendarNum,
    this.sideDish,
    this.timestamp,
    this.type,
  });

  factory MealPlannerItemModel.fromJson(Map<String, dynamic> json) =>
      MealPlannerItemModel(
        name: json['name'],
        category: json['category'],
        dateCreated: json['dateCreated'],
        dateSelected: json['dateSelected'],
        description: json['description'],
        drink: json['drink'],
        id: json['id'],
        image: json['image'],
        isMealInMealPlanner: json['isMealInMealPlanner'],
        isMealLiked: json['isMealLiked'],
        nutritionFacts: json['nutritionFacts'],
        searchKeywords: json['searchKeywords'],
        selectedDayCalendarNum: json['selectedDayCalendarNum'],
        sideDish: json['sideDish'],
        timestamp: json['timestamp'],
        type: json['type'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'dateCreated': dateCreated,
        'dateSelected': dateSelected,
        'description': description,
        'drink': drink,
        'id': id,
        'image': image,
        'isMealInMealPlanner': isMealInMealPlanner,
        'isMealLiked': isMealLiked,
        'nutritionFacts': nutritionFacts,
        'searchKeywords': searchKeywords,
        'selectedDayCalendarNum': selectedDayCalendarNum,
        'sideDish': sideDish,
        'timestamp': timestamp,
        'type': type,
      };

  static List<MealPlannerItemModel> getMeals() {
    return const [
      MealPlannerItemModel(
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
      MealPlannerItemModel(
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
      MealPlannerItemModel(
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
      MealPlannerItemModel(
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
      MealPlannerItemModel(
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
      MealPlannerItemModel(
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
      MealPlannerItemModel(
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
      MealPlannerItemModel(
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
}
