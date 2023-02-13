// ignore_for_file: prefer_typing_uninitialized_variables

class RecipeModel {
  final String? category;
  final String? cookingTime;
  final String? description;
  final String? id;
  final String? image;
  final ingredients;
  final instructions; // List? or FieldValue
  final bool? isRecipeLiked;
  final bool? isSideDish;
  final String? name;
  final String? preparationTime;
  final searchKeywords;
  final String? servingSize;
  final String? type;

  const RecipeModel({
     this.category,
    this.cookingTime,
     this.description,
     this.id,
     this.image,
    this.ingredients,
    this.instructions,
     this.isRecipeLiked,
     this.isSideDish,
     this.name,
    this.preparationTime,
    this.searchKeywords,
    this.servingSize,
     this.type,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) => RecipeModel(
        category: json['category'],
        cookingTime: json['cookingTime'],
        description: json['description'],
        id: json['id'],
        image: json['image'],
        ingredients: json['ingredients'],
        instructions: json['instructions'],
        isRecipeLiked: json['isRecipeLiked'],
        isSideDish: json['isSideDish'],
        name: json['name'],
        preparationTime: json['preparationTime'],
        searchKeywords: json['searchKeywords'],
        servingSize: json['servingSize'],
        type: json['type'],
      );

  Map<String, dynamic> toJson() => {
        'category': category,
        'cookingTime': cookingTime,
        'description': description,
        'id': id,
        'image': image,
        'ingredients': ingredients,
        'instructions': instructions,
        'isRecipeLiked': isRecipeLiked,
        'isSideDish': isSideDish,
        'name': name,
        'preparationTime': preparationTime,
        'searchKeywords': searchKeywords,
        'servingSize': servingSize,
        'type': type,
      };
}
