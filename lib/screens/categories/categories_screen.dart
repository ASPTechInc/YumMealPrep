import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent-tab-view.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:yummealprep/models/category_model.dart';
import 'package:yummealprep/models/models_logic.dart';
import 'package:yummealprep/screens/meals/widgets/add_meal_item_widget.dart';
import 'package:yummealprep/screens/meals/meals_screen.dart';
import 'package:yummealprep/screens/recipes/recipes_screen.dart';
import 'package:yummealprep/screens/recipes/widgets/add_recipe_widget.dart';
import 'package:yummealprep/utils/constants.dart';
import 'package:yummealprep/utils/ui_helpers.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => CategoriesScreenState();
}

class CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> categories = getCategories();
  int? isMealsCategorySelected = 1;
  int? count;

  void navigateToScreen(image, name, subtitle) {
    isMealsCategorySelected == 0
        ? pushNewScreen(
            context,
            screen: RecipesScreen(
                recipeType: name, image: image, description: subtitle),
            withNavBar: true,
            pageTransitionAnimation: PageTransitionAnimation.cupertino,
          )
        : pushNewScreen(
            context,
            screen: MealsScreen(mealType: name),
            withNavBar: true,
            pageTransitionAnimation: PageTransitionAnimation.cupertino,
          );
  }

  getItemCount(isMealsCategorySelected, type) {
    return StreamBuilder<QuerySnapshot>(
        stream: isMealsCategorySelected == 1
            ? FirebaseFirestore.instance
                .collection(dotenv.env['MEALSCOLLECTION']!)
                .where('type', isEqualTo: type)
                .snapshots()
            : FirebaseFirestore.instance
                .collection(dotenv.env['RECIPESCOLLECTION']!)
                .where('type', isEqualTo: type)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            // Empty or null
            return Badge(
                label: const Text('0'),
                child: isMealsCategorySelected == 1
                    ? const Icon(Icons.brunch_dining, color: Colors.white)
                    : const Icon(Icons.menu_book, color: Colors.white));
          } else {
            // Has data
            List<Map<String, dynamic>?>? documentData = snapshot.data?.docs
                .map((element) => element.data() as Map<String, dynamic>?)
                .toList();
            count = documentData!.length;
            return Badge(
                label: Text(count.toString()),
                child: isMealsCategorySelected == 1
                    ? const Icon(Icons.brunch_dining, color: Colors.white)
                    : const Icon(Icons.menu_book, color: Colors.white));
          }
        });
  }

  Widget categoryCard(String? image, String? name, String? description) {
    return GestureDetector(
        onTap: () => navigateToScreen(image, name, description),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    image: DecorationImage(
                        image: AssetImage(image!), fit: BoxFit.cover)),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0)),
                ),
              ),
            ),
            Positioned(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                height: 200.0, // Set height of the card
                color: Colors.black38,
                width: MediaQuery.of(context).size.width / .5,
                child: Text(
                  name!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              child: Container(
                  alignment: Alignment.bottomRight,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                  child: getItemCount(isMealsCategorySelected, name)),
            ),
          ],
          // ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: UIHelper.openDrawer(context),
      appBar: AppBar(
        title: const Text(Constants.appName),
        centerTitle: true,
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 20),
              child: IconButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        if (isMealsCategorySelected == 1) {
                          // Add new meal button
                          return const AddMealItem();
                        } else {
                          // Add new recipe button
                          return const AddRecipe();
                        }
                      });
                },
                icon: const Icon(
                  Icons.add_circle,
                  color: Colors.white,
                  size: 30,
                ),
              )),
        ],
      ),
      body: Stack(
        children: [
          // Categories' Grid
          ResponsiveGridList(
              listViewBuilderOptions: ListViewBuilderOptions(
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
              ),
              horizontalGridMargin: 30,
              verticalGridMargin: 30,
              maxItemsPerRow: 3,
              minItemWidth: 120,
              children: categories
                  .map((item) =>
                      categoryCard(item.image, item.name, item.description))
                  .toList()),
          // Options' floating button
          Positioned(
            right: 30,
            bottom: 80,
            child: ToggleSwitch(
                activeBorders: [
                  Border.all(
                    color: Colors.indigo,
                    width: 3.0,
                  ),
                  Border.all(
                    color: Colors.deepOrange.shade700,
                    width: 3.0,
                  ),
                ],
                activeFgColor: Colors.black54,
                isVertical: true,
                minWidth: 150.0,
                radiusStyle: true,
                cornerRadius: 20.0,
                initialLabelIndex: isMealsCategorySelected,
                activeBgColors: const [
                  [Colors.indigoAccent],
                  [Colors.deepOrangeAccent],
                ],
                customIcons: const [
                  Icon(Icons.menu_book, color: Colors.white),
                  Icon(Icons.brunch_dining, color: Colors.white)
                ],
                iconSize: 30.0,
                labels: const ['Recipes', 'Meals'],
                customTextStyles: const [
                  TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900),
                  TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)
                ],
                onToggle: (index) => setState(() {
                      isMealsCategorySelected = index;
                    })),
          )
        ],
      ),
    );
  }
}
