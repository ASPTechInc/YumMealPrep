// ignore_for_file: prefer_typing_uninitialized_variables
enum Categories { appetisers, breakfast, lunch, dinner, dessert, smoothies }

class Category {
  final String? description;
  final String? image;
  final String? name;

  const Category({
    required this.description,
    required this.image,
    required this.name,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        description: json['description'],
        image: json['image'],
        name: json['name'],
      );

  Map<String, dynamic> toJson() => {
        'description': description,
        'image': image,
        'name': name,
      };
}
