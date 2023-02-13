// ignore_for_file: prefer_typing_uninitialized_variables
class MealItemModel {
  final String? category;
  final String? description;
  final String? drink;
  final String? id;
  final String? image;
  final bool? isItemSelected;
  final bool? isMealInMealPlanner;
  final bool? isMealLiked;

  final String? name;
  final nutritionFacts;
  final searchKeywords;
  final String? sideDish;
  final String? type;

  const MealItemModel({
    this.category,
    this.description,
    this.drink,
    this.id,
    this.image,
    this.isItemSelected,
    this.isMealLiked,
    this.isMealInMealPlanner,
    this.name,
    this.nutritionFacts,
    this.searchKeywords,
    this.sideDish,
    this.type,
  });

  factory MealItemModel.fromJson(Map<String, dynamic> json) => MealItemModel(
        name: json['name'],
        category: json['category'],
        description: json['description'],
        drink: json['drink'],
        id: json['id'],
        image: json['image'],
        isItemSelected: json['isItemSelected'],
        isMealInMealPlanner: json['isMealInMealPlanner'],
        isMealLiked: json['isMealLiked'],
        nutritionFacts: json['nutritionFacts'],
        searchKeywords: json['searchKeywords'],
        sideDish: json['sideDish'],
        type: json['type'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'description': description,
        'drink': drink,
        'id': id,
        'image': image,
        'isItemSelected': isItemSelected,
        'isMealInMealPlanner': isMealInMealPlanner,
        'isMealLiked': isMealLiked,
        'nutritionFacts': nutritionFacts,
        'searchKeywords': searchKeywords,
        'sideDish': sideDish,
        'type': type,
      };
}
