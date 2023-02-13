import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent-tab-view.dart';
import 'package:yummealprep/models/recipe_model.dart';
import 'package:yummealprep/screens/recipes/recipe_details_screen.dart';
import 'package:yummealprep/screens/search/search_screen.dart';
import 'package:yummealprep/utils/constants.dart';
import 'package:yummealprep/utils/ui_helpers.dart';

class RecipesScreen extends StatefulWidget {
  final String? recipeType;
  final String? image;
  final String? description;

  const RecipesScreen({
    Key? key,
    this.recipeType,
    this.image,
    this.description,
  }) : super(key: key);

  @override
  State<RecipesScreen> createState() => RecipesScreenState();
}

class RecipesScreenState extends State<RecipesScreen> {
  String searchQuery = '';

  Widget searchBar() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: TextField(
            cursorColor: Colors.grey,
            decoration: InputDecoration(
              // fillColor: Colors.white,
              // filled: true,
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              hintText: 'Search...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 18),
              prefixIcon: Container(
                padding: const EdgeInsets.all(15),
                width: 18,
                child: const Icon(Icons.search),
              ),
            ),
            onChanged: (value) => setState(() {
                  searchQuery = value;
                })));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Image header
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Image.asset(
                    widget.image!,
                    height: MediaQuery.of(context).size.height / 3,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  UIHelper.verticalSpaceMedium(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${widget.recipeType!.toUpperCase()} RECIPES',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(fontSize: 19.0),
                        ),
                        UIHelper.verticalSpaceSmall(),
                        Text(
                          widget.description!,
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  searchBar(),
                  const Divider(),
                  // Recipe item list
                  Container(
                      padding: const EdgeInsets.only(
                          bottom: 15.0, right: 15.0, left: 15, top: 2),
                      child: RecipeSearchList(
                          recipeType: widget.recipeType!,
                          searchQuery: searchQuery)),
                ],
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 10.0,
            left: 2.4,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  size: 28.0,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }
}

class RecipeHeader extends StatelessWidget {
  const RecipeHeader({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Image.asset(
          '${Constants.appImageDir}banner1.png',
          height: MediaQuery.of(context).size.height / 2.1,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Positioned(
          top: 40.0,
          left: 0.4,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              size: 28.0,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        )
      ],
    );
  }
}

class RecipeList extends StatelessWidget {
  final RecipeModel? recipes;
  // final recipes;
  const RecipeList({
    Key? key,
    required this.recipes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    void navigateToRecipeDetailsScreen() {
      pushNewScreen(
        context,
        screen: RecipeDetailsScreen(recipes: recipes),
        withNavBar: true,
        pageTransitionAnimation: PageTransitionAnimation.cupertino,
      );
    }

    return GestureDetector(
      onTap: () => navigateToRecipeDetailsScreen(),
      child: Container(
        margin: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.white,
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 2.0,
                  )
                ],
              ),
              child: Image.network(
                recipes!.image!, // recipes['image'],
                height: 80.0,
                width: 80.0,
                fit: BoxFit.fill,
              ),
            ),
            UIHelper.horizontalSpaceSmall(),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    recipes!.name!,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall!
                        .copyWith(fontSize: 15.0),
                  ),
                  Text(recipes!.description!,
                      maxLines: 3,
                      textAlign: TextAlign.justify,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(color: Colors.grey[600], fontSize: 13.5)),
                  UIHelper.verticalSpaceSmall(),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.timelapse,
                        size: 14.0,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 5),
                      Text(
                        recipes!.preparationTime!,
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
