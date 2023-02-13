import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:random_string/random_string.dart';

/*  Explanation of how to add recipes and meal item data to Cloud Firestore
 *  When FirebaseFirestore.instance.collection('recipes').doc() is used,
 *  a document is created in the collection called 'recipes'
 *  set() is used to create the data in that document 
 */

class AppRepository {
  final CollectionReference recipesCollection =
      FirebaseFirestore.instance.collection(dotenv.env['RECIPESCOLLECTION']!);

  /// Add restaurant items to Cloud Firestore
  // Shared field names
  final String appetiserType = 'Appetisers';
  final String breakfastType = 'Breakfast';
  final String lunchType = 'Lunch';
  final String dinnerType = 'Dinner';
  final String dessertType = 'Dessert';
  final String smoothieType = 'Smoothies';

  final bool isRecipeLiked = false;
  final bool isSideDish = false;
  final String recipeCategory = 'Recipes';

  List getKeywordsFromString(String word) {
    var keywordList = [];
    for (var index = 0; index < word.length; index++) {
      keywordList.add(word.substring(0, index + 1));
    }
    return keywordList;
  }

  // Categories

  // Meal items
  Future<void> mealItemsData() async {
    // String randomID = randomAlphaNumeric(20);
    // final CollectionReference mealsCollection =
    // FirebaseFirestore.instance.collection(dotenv.env['MEALSCOLLECTION']!);

    // bool isMealLiked = false;
    // bool isItemSelected = false;
    // bool isMealInMealPlanner = false;
    // String mealsCategory = 'Meals';

    // await mealsCollection.doc().set(MealItemModel(
    //         category: mealsCategory,
    //         description:
    //             '',
    //         drink: '',
    //         id: '',
    //         image:
    //             '',
    //         isItemSelected: isItemSelected,
    //         isMealInMealPlanner: isMealInMealPlanner,
    //         isMealLiked: isMealLiked,
    //         name: '',
    //         nutritionFacts: [
    //           ''
    //         ],
    //         searchKeywords: FieldValue.arrayUnion(
    //             getKeywordsFromString('')),
    //         sideDish: 'N/A',
    //         type: lunchType,
    //       ).toJson());
  }

  // Recipe items
  // Completed: Recipes H - O, Smoothies
//Outstanding: Recipes A-G; Recipes P - Z
  Future<void> recipeData() async {
    // Recipes A - G
    // await recipesCollection.doc().set(RecipeModel(
    //       category: recipeCategory,
    //       cookingTime: '',
    //       description: '',
    //       id: '',
    //       image: '',
    //       ingredients: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       instructions: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       isRecipeLiked: isRecipeLiked,
    //       isSideDish: isSideDish,
    //       name: '',
    //       preparationTime: '',
    //       searchKeywords: FieldValue.arrayUnion(getKeywordsFromString('')),
    //       servingSize: '',
    //       type: appetiserType,
    //     ).toJson());

    // Recipes P - Z
    // await recipesCollection.doc().set(RecipeModel(
    //       category: recipeCategory,
    //       cookingTime: '',
    //       description: '',
    //       id: '',
    //       image: '',
    //       ingredients: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       instructions: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       isRecipeLiked: isRecipeLiked,
    //       isSideDish: isSideDish,
    //       name: '',
    //       preparationTime: '',
    //       searchKeywords: FieldValue.arrayUnion(getKeywordsFromString('')),
    //       servingSize: '',
    //       type: appetiserType,
    //     ).toJson());
    // await recipesCollection.doc().set(RecipeModel(
    //       category: recipeCategory,
    //       cookingTime: '',
    //       description: '',
    //       id: '',
    //       image: '',
    //       ingredients: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       instructions: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       isRecipeLiked: isRecipeLiked,
    //       isSideDish: isSideDish,
    //       name: '',
    //       preparationTime: '',
    //       searchKeywords: FieldValue.arrayUnion(getKeywordsFromString('')),
    //       servingSize: '',
    //       type: appetiserType,
    //     ).toJson());
    // await recipesCollection.doc().set(RecipeModel(
    //       category: recipeCategory,
    //       cookingTime: '',
    //       description: '',
    //       id: '',
    //       image: '',
    //       ingredients: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       instructions: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       isRecipeLiked: isRecipeLiked,
    //       isSideDish: isSideDish,
    //       name: '',
    //       preparationTime: '',
    //       searchKeywords: FieldValue.arrayUnion(getKeywordsFromString('')),
    //       servingSize: '',
    //       type: appetiserType,
    //     ).toJson());
    // await recipesCollection.doc().set(RecipeModel(
    //       category: recipeCategory,
    //       cookingTime: '',
    //       description: '',
    //       id: '',
    //       image: '',
    //       ingredients: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       instructions: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       isRecipeLiked: isRecipeLiked,
    //       isSideDish: isSideDish,
    //       name: '',
    //       preparationTime: '',
    //       searchKeywords: FieldValue.arrayUnion(getKeywordsFromString('')),
    //       servingSize: '',
    //       type: appetiserType,
    //     ).toJson());
    // await recipesCollection.doc().set(RecipeModel(
    //       category: recipeCategory,
    //       cookingTime: '',
    //       description: '',
    //       id: '',
    //       image: '',
    //       ingredients: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       instructions: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       isRecipeLiked: isRecipeLiked,
    //       isSideDish: isSideDish,
    //       name: '',
    //       preparationTime: '',
    //       searchKeywords: FieldValue.arrayUnion(getKeywordsFromString('')),
    //       servingSize: '',
    //       type: appetiserType,
    //     ).toJson());
    // await recipesCollection.doc().set(RecipeModel(
    //       category: recipeCategory,
    //       cookingTime: '',
    //       description: '',
    //       id: '',
    //       image: '',
    //       ingredients: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       instructions: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       isRecipeLiked: isRecipeLiked,
    //       isSideDish: isSideDish,
    //       name: '',
    //       preparationTime: '',
    //       searchKeywords: FieldValue.arrayUnion(getKeywordsFromString('')),
    //       servingSize: '',
    //       type: appetiserType,
    //     ).toJson());
    // await recipesCollection.doc().set(RecipeModel(
    //       category: recipeCategory,
    //       cookingTime: '',
    //       description: '',
    //       id: '',
    //       image: '',
    //       ingredients: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       instructions: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       isRecipeLiked: isRecipeLiked,
    //       isSideDish: isSideDish,
    //       name: '',
    //       preparationTime: '',
    //       searchKeywords: FieldValue.arrayUnion(getKeywordsFromString('')),
    //       servingSize: '',
    //       type: appetiserType,
    //     ).toJson());
    // await recipesCollection.doc().set(RecipeModel(
    //       category: recipeCategory,
    //       cookingTime: '',
    //       description: '',
    //       id: '',
    //       image: '',
    //       ingredients: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       instructions: FieldValue.arrayUnion(
    //           ['', '', '', '', '', '', '', '', '', '', '', '', '']),
    //       isRecipeLiked: isRecipeLiked,
    //       isSideDish: isSideDish,
    //       name: '',
    //       preparationTime: '',
    //       searchKeywords: FieldValue.arrayUnion(getKeywordsFromString('')),
    //       servingSize: '',
    //       type: appetiserType,
    //     ).toJson());
    // await recipesCollection.doc().set(RecipeModel(
    //       category: recipeCategory,
    //       cookingTime: '3hours',
    //       description:
    //           'Simmer slowly to make a thick, flavorful sauce that is perfect for rice, smothering noodles or on pizzas',
    //       id: '',
    //       image:
    //           'https://firebasestorage.googleapis.com/v0/b/yummealprep-adb3b.appspot.com/o/recipes%2Flunch%2Ftomato_sauce.jpeg?alt=media&token=23222790-341b-4d7e-a3ea-6ac54bd41947',
    //       ingredients: FieldValue.arrayUnion([
    //         '2 tbsp tomato paste',
    //         'Onion powder',
    //         '3 tomatoes',
    //         'Sweet peppers',
    //         'Water',
    //         '2 tsp dried basil',
    //         '2 tsp dried oregano',
    //         '1½ tsp salt',
    //         '1 tbsp cooking oil'
    //       ]),
    //       instructions: FieldValue.arrayUnion([
    //         'Sauté onions in a pot',
    //         'After the onions are softened, add add the garlic to cook for an additional 30 seconds until it\'s fragrance is evident',
    //         'Add sweet peppers, dried herbs, diced tomatoes as well as all-purpose seasoning and salt',
    //         'Add a bit of water to the sauce',
    //         'Stir and bring the sauce to a simmer.',
    //         'Cover and let sauce cook for 2-3 hours. This will allow the tomatoes to break down creating a nice thick sauce'
    //       ]),
    //       isRecipeLiked: isRecipeLiked,
    //       isSideDish: true,
    //       name: 'Tomato Sauce',
    //       preparationTime: '5mins',
    //       searchKeywords:
    //           FieldValue.arrayUnion(getKeywordsFromString('tomato sauce')),
    //       servingSize: '10 bowls',
    //       type: lunchType,
    //     ).toJson());
    // await recipesCollection.doc().set(RecipeModel(
    //       category: recipeCategory,
    //       cookingTime: '20mins',
    //       description: '',
    //       id: '',
    //       image:
    //           'https://firebasestorage.googleapis.com/v0/b/yummealprep-adb3b.appspot.com/o/recipes%2Flunch%2Fvegetable_soup.jpg?alt=media&token=206f72ce-2086-4107-b43f-ef9c80599fb8',
    //       ingredients: FieldValue.arrayUnion([
    //         '2 cups of frozen mixed vegetables',
    //         'Macaroni',
    //         '3 medium peeled potatoes',
    //         'Black eye peas',
    //         'Cornmeal dumplings with husk',
    //         '½ teaspoon dried thyme'
    //       ]),
    //       instructions: FieldValue.arrayUnion([
    //         'In a medium pot, add sliced carrots, diced potatoes and thyme.',
    //         'Stir and cover the pot with a lid.',
    //         'Increase the heat and bring to a boil.',
    //         'Reduce the heat to low and let the pot simmer for 15 minutes.',
    //         'After 15 minutes have passed, add peas and macaroni to cook for an additional 5 minutes. Ensure that the macaroni and vegetables are soft before the heat is turned off'
    //       ]),
    //       isRecipeLiked: isRecipeLiked,
    //       isSideDish: isSideDish,
    //       name: 'Vegetable Soup',
    //       preparationTime: '5mins',
    //       searchKeywords:
    //           FieldValue.arrayUnion(getKeywordsFromString('vegetable soup')),
    //       servingSize: '4',
    //       type: appetiserType,
    //     ).toJson());
    // await recipesCollection.doc().set(RecipeModel(
    //       category: recipeCategory,
    //       cookingTime: '20mins',
    //       description:
    //           'Sweat ground provisions is a process where ground provisions are peeled and boiled in salted water, drained well, cut into large pieces. They can then be sautéed with onions, tomatoes and fresh herbs. Ground provisions are served as a meal by itself and can be eaten for breakfast, lunch, or dinner but usually at lunchtime. Sweat ground provisions can be served with meat or sautéed salt fish. It\'s best if you rub some cooking oil all over your hands or use a pair of latex gloves, as you may find that your hands may itch from handling them when peeling when peeling the ground provisions.',
    //       id: '',
    //       image:
    //           'https://firebasestorage.googleapis.com/v0/b/yummealprep-adb3b.appspot.com/o/recipes%2Flunch%2Fsweat_ground_provisions.png?alt=media&token=c2a89f62-0f09-4d16-b49f-2bfa4b455088',
    //       ingredients: FieldValue.arrayUnion([
    //         'Plantains',
    //         'Dasheen',
    //         'Breadfruit',
    //         'Green bananas',
    //         'Cassava',
    //         'Yam',
    //         'Sweet potatoes',
    //         'English potatoes',
    //         'Eddoes',
    //         'Corn (to boil)',
    //         'Dumpling',
    //         '1 tps salt'
    //       ]),
    //       instructions: FieldValue.arrayUnion([
    //         'Cook ground provisions within a pot of lightly salted water until a toothpick, knife or a fork can pass through them once pierced'
    //       ]),
    //       isRecipeLiked: isRecipeLiked,
    //       isSideDish: true,
    //       name: 'Sweat Ground Provisions',
    //       preparationTime: '10mins',
    //       searchKeywords: FieldValue.arrayUnion(
    //           getKeywordsFromString('sweat ground provisions')),
    //       servingSize: '5',
    //       type: appetiserType,
    //     ).toJson());
    // await recipesCollection.doc().set(RecipeModel(
    //       category: recipeCategory,
    //       cookingTime: '10mins',
    //       description:
    //           'Steaming is a healthy, easy way to cook fresh vegetables. The technique requires no added fat, and vitamins remain in the vegetables instead of leaching into the water, as can happen with boiling.',
    //       id: '',
    //       image:
    //           'https://firebasestorage.googleapis.com/v0/b/yummealprep-adb3b.appspot.com/o/recipes%2Flunch%2Fsteam_vegetables.jpg?alt=media&token=5c4cf7b7-10ac-452c-b017-6796831a79bf',
    //       ingredients: FieldValue.arrayUnion([
    //         '1/2 teaspoon salt',
    //         '3 cups of cut-up fresh vegetables such as broccoli, cauliflower',
    //         '3 cups of sliced carrots'
    //       ]),
    //       instructions: FieldValue.arrayUnion([
    //         'Add a bit of water, salt and vegetables to a pot',
    //         'Place the pot on the stove at a low temperature',
    //         'Cover the pot on the stove and let the vegetables steam for about 10 minutes'
    //       ]),
    //       isRecipeLiked: isRecipeLiked,
    //       isSideDish: true,
    //       name: 'Steam vegetables',
    //       preparationTime: '10mins',
    //       searchKeywords:
    //           FieldValue.arrayUnion(getKeywordsFromString('steam vegetables')),
    //       servingSize: '6',
    //       type: lunchType,
    //     ).toJson());
    // await recipesCollection.doc().set(RecipeModel(
    //       category: recipeCategory,
    //       cookingTime: '20 mins',
    //       description:
    //           'Tumeric vegetable rice is packed with mixed vegetables and a combination of aromatics and spices for a truly flavourful (and colourful), versatile side dish.',
    //       id: '',
    //       image:
    //           'https://firebasestorage.googleapis.com/v0/b/yummealprep-adb3b.appspot.com/o/recipes%2Flunch%2Fvegetable_rice.jpg?alt=media&token=6491861a-f365-4204-b155-63a9c047e5e3',
    //       ingredients: FieldValue.arrayUnion([
    //         '1 tsp Salt',
    //         '3 cups of rice',
    //         '1/2 teaspoon dried parsley',
    //         '1/2 teaspoon dried mixed herbs',
    //         '1/2 teaspoon dried thyme',
    //         'Onion powder',
    //         'Garlic powder',
    //         '2 cups of frozen mixed vegetables',
    //         '1 1/4 teaspoons ground turmeric'
    //       ]),
    //       instructions: FieldValue.arrayUnion([
    //         'Wash rice with water then, drain the water from the rice',
    //         'Add salt, rice, tumeric, vegetables, condiments to the pot of rice with boiling water',
    //         'Cook on medium heat',
    //         'Let the pot  come to a boil - then lower the heat to a minimum low',
    //         'Cover the pot and let the rice cook on low heat for 15 minutes undisturbed',
    //         'After 15 minutes have passed, switch the heat off and let the rice sit for 10 minutes'
    //       ]),
    //       isRecipeLiked: isRecipeLiked,
    //       isSideDish: isSideDish,
    //       name: 'Vegetable rice',
    //       preparationTime: '5 mins',
    //       searchKeywords:
    //           FieldValue.arrayUnion(getKeywordsFromString('vegetable rice')),
    //       servingSize: '5',
    //       type: lunchType,
    //     ).toJson());
    // await recipesCollection.doc().set(RecipeModel(
    //       category: recipeCategory,
    //       cookingTime: '15-20mins',
    //       description:
    //           'Plain white rice is an excellent inexpensive side dish for nearly any meal—it\'s hard to find a dish that rice doesn\'t complement. It\'s also a blank canvas to which you can add countless ingredients for extra flavor, and it does a good job of soaking up the sauces of whatever you pair it with, too.',
    //       id: '',
    //       image:
    //           'https://firebasestorage.googleapis.com/v0/b/yummealprep-adb3b.appspot.com/o/recipes%2Flunch%2Fwhite_rice.jpeg?alt=media&token=cd9d9f0a-e159-4ef8-b828-a8cc0eee7255',
    //       ingredients: FieldValue.arrayUnion([
    //         '2 cups of rice (long grain rice)',
    //         '1 tsp salt',
    //         '2 1/2 cups of water'
    //       ]),
    //       instructions: FieldValue.arrayUnion([
    //         'Add rice to a pot that is on the stove',
    //         'Add 2 and a half cups of hot/boiled water to cover the rice',
    //         'Add condiments to the rice',
    //         'Turn the heat of the stove down for the rice to cook'
    //       ]),
    //       isRecipeLiked: isRecipeLiked,
    //       isSideDish: isSideDish,
    //       name: 'White rice (Plain)',
    //       preparationTime: '5mins',
    //       searchKeywords:
    //           FieldValue.arrayUnion(getKeywordsFromString('white rice')),
    //       servingSize: '5',
    //       type: lunchType,
    //     ).toJson());
  }

  // Smoothies
  // Future<void> smoothieData() async {
  //   String smoothieType = 'Smoothie';
  //   String cookingTime = '';
  //   String preparationTime = '';
  //   String servingSize = '';
  //   //  await recipesCollection.doc().set(RecipeModel(
  //   //       category: recipeCategory,
  //   // cookingTime:cookingTime,
  //   //       description:
  //   //           '',
  //   //       id: '',
  //   //       image:
  //   //           'https://firebasestorage.googleapis.com/v0/b/yummealprep-adb3b.appspot.com/o/recipes%2Fsmoothies%2Frecipe_banana_smoothie.png?alt=media&token=4ca9c570-7a20-40c9-9ef0-f8514e8e9e8b',
  //   //       ingredients: FieldValue.arrayUnion([
  //   //         '',
  //   //         '',
  //   //         '',
  //   //         '',
  //   //         '',
  //   //       ]),
  //   //       instructions: FieldValue.arrayUnion([
  //   //         '',
  //   //         '',
  //   //         '',
  //   //         ''
  //   //       ]),
  //   //       isRecipeLiked: isRecipeLiked,
  //   //       isSideDish: isSideDish,
  //   //       name: '',
  //   // preparationTime:preparationTime,
  //   //       searchKeywords:
  //   //           FieldValue.arrayUnion(getKeywordsFromString('')),
  //   //       type: smoothieType,
  //   // servingSize:servingSize,
  //   // )
  //   //   .toJson());
  // }
}
