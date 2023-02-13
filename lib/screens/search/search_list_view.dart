import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent-tab-view.dart';
import 'package:yummealprep/models/meal_item_model.dart';
import 'package:yummealprep/models/recipe_model.dart';
import 'package:yummealprep/screens/meals/meal_details_screen.dart';
import 'package:yummealprep/screens/recipes/recipe_details_screen.dart';
import 'package:yummealprep/utils/ui_helpers.dart';

class MealSearchListView extends StatelessWidget {
  final MealItemModel? searchResults;
  const MealSearchListView({Key? key, this.searchResults}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    void navigateToMealDetailsScreen() {
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //       builder: (context) => MealDetailsScreen(
      //           meals: searchResults)),
      // );
      pushNewScreen(
        context,
        screen: MealDetailsScreen(meals: searchResults),
        withNavBar: true,
        pageTransitionAnimation: PageTransitionAnimation.cupertino,
      );
    }

    return GestureDetector(
      onTap: () => navigateToMealDetailsScreen(),
      child: Container(
        margin: const EdgeInsets.all(10.0),
        child: Stack(
          children: [
            Row(
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
                    searchResults!.image!,
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
                        searchResults!.name!,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall!
                            .copyWith(fontSize: 15.0),
                      ),
                      Text(searchResults!.description!,
                          maxLines: 3,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                                  color: Colors.grey[600], fontSize: 13.5)),
                      UIHelper.verticalSpaceSmall(),
                    ],
                  ),
                )
              ],
            ),
            Positioned(
                bottom: 5,
                left: 57,
                child: Icon(
                  Icons.favorite,
                  size: 18.0,
                  color: searchResults!.isMealLiked!
                      ? Colors.red[800]
                      : Colors.grey[600],
                ))
          ],
        ),
      ),
    );
  }
}

class RecipeSearchListView extends StatelessWidget {
  final RecipeModel? searchResults;
  const RecipeSearchListView({Key? key, this.searchResults}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    void navigateToRecipeDetailsScreen() {
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //       builder: (context) => RecipeDetailsScreen(
      //           recipes: searchResults)),
      // );
      pushNewScreen(
        context,
        screen: RecipeDetailsScreen(recipes: searchResults),
        withNavBar: true,
        pageTransitionAnimation: PageTransitionAnimation.cupertino,
      );
    }

    return GestureDetector(
      onTap: () => navigateToRecipeDetailsScreen(),
      child: Container(
        margin: const EdgeInsets.all(10.0),
        child: Stack(
          children: [
            Row(
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
                    searchResults!.image!,
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
                        searchResults!.name!,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall!
                            .copyWith(fontSize: 15.0),
                      ),
                      Text(searchResults!.description!,
                          maxLines: 3,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                                  color: Colors.grey[600], fontSize: 13.5)),
                      UIHelper.verticalSpaceSmall(),
                    ],
                  ),
                )
              ],
            ),
            Positioned(
                bottom: 5,
                left: 57,
                child: Icon(
                  Icons.favorite,
                  size: 18.0,
                  color: searchResults!.isRecipeLiked!
                      ? Colors.red[800]
                      : Colors.grey[600],
                ))
          ],
        ),
      ),
    );
  }
}
