import 'package:animated_floating_buttons/animated_floating_buttons.dart';
import 'package:bulleted_list/bulleted_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:like_button/like_button.dart';
import 'package:yummealprep/models/recipe_model.dart';
import 'package:yummealprep/screens/recipes/widgets/add_recipe_widget.dart';
import 'package:yummealprep/screens/recipes/widgets/edit_recipe_widget.dart';
import 'package:yummealprep/screens/recipes/widgets/share_recipe_widget.dart';
import 'package:yummealprep/themes/colours.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final RecipeModel? recipes;
  const RecipeDetailsScreen({
    Key? key,
    required this.recipes,
  }) : super(key: key);

  @override
  RecipeDetailsScreenState createState() => RecipeDetailsScreenState();
}

class RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  final GlobalKey<AnimatedFloatingActionButtonState> floatingButtonKey =
      GlobalKey<AnimatedFloatingActionButtonState>();

  Future<bool> onFavouriteIconTapped(bool isFavourite) async {
    /// send your request here
    // final bool success= await sendRequest();

    /// if failed, you can do nothing
    // return success? !isFavourite:isFavourite;

    return !isFavourite;
  }

  LikeButton favouriteButton() => LikeButton(
        onTap: onFavouriteIconTapped,
        // size: buttonSize,
        circleColor:
            const CircleColor(start: Color(0xff00ddff), end: Color(0xff0099cc)),
        bubblesColor: const BubblesColor(
          dotPrimaryColor: Color(0xff33b5e5),
          dotSecondaryColor: Color(0xff0099cc),
        ),
        likeBuilder: (bool isFavourite) {
          return Icon(
            Icons.favorite,
            color: widget.recipes!.isRecipeLiked! ? Colors.red : Colors.grey,
            // size: buttonSize,
          );
        },
        likeCount: null,
        countBuilder: (count, isFavourite, text) {
          var color = widget.recipes!.isRecipeLiked! ? Colors.red : Colors.grey;
          Widget result;
          if (count == 0) {
            result = Text(
              'love',
              style: TextStyle(color: color),
            );
          } else {
            result = Text(
              text,
              style: TextStyle(color: color),
            );
          }
          return result;
        },
      );

  Column itemDescriptionSection() {
    return Column(children: <Widget>[
      const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text(
              'Description',
              style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            )),
      ),
      const SizedBox(
        height: 10.0,
      ),
      Padding(
        padding: const EdgeInsets.only(left: 15, right: 15),
        child: Text(
          widget.recipes!.description!,
          textAlign: TextAlign.justify,
          style: const TextStyle(
              wordSpacing: 3.0, textBaseline: TextBaseline.alphabetic),
        ),
      )
    ]);
  }

  Column itemIngredientsSection() {
    return Column(children: <Widget>[
      const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text(
              'Ingredients',
              style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            )),
      ),
      const SizedBox(
        height: 10.0,
      ),
      collapsibleSection(
          'Expand to view more', 'Ingredients', widget.recipes!.ingredients!),
      const SizedBox(
        height: 10.0,
      ),
    ]);
  }

  Column instructionsSection() {
    return Column(children: <Widget>[
      const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text(
              'Instructions',
              style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            )),
      ),
      const SizedBox(
        height: 10.0,
      ),
      collapsibleSection(
          'Expand to view more', 'Instructions', widget.recipes!.instructions!),
      const SizedBox(
        height: 10.0,
      ),
    ]);
  }

  ExpandableNotifier collapsibleSection(text, field, itemList) {
    return ExpandableNotifier(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              ScrollOnExpand(
                scrollOnExpand: true,
                scrollOnCollapse: false,
                child: ExpandablePanel(
                  theme: const ExpandableThemeData(
                    headerAlignment: ExpandablePanelHeaderAlignment.center,
                    tapBodyToCollapse: true,
                  ),
                  header: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.bodyLarge,
                      )),
                  collapsed: Text(
                    field == 'Instructions'
                        ? '1. ${widget.recipes!.instructions![0]}'
                        : '1. ${widget.recipes!.ingredients![0]}',
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  expanded: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: field == 'Instructions'
                            ? BulletedList(
                                listItems: widget.recipes!.instructions!,
                                listOrder: ListOrder.ordered,
                                bulletType: BulletType.numbered,
                              )
                            : BulletedList(
                                listItems: widget.recipes!.ingredients!,
                                listOrder: ListOrder.ordered,
                              ),
                      )
                    ],
                  ),
                  builder: (_, collapsed, expanded) {
                    return Padding(
                      padding: const EdgeInsets.only(
                          left: 10, right: 10, bottom: 10),
                      child: Expandable(
                        collapsed: collapsed,
                        expanded: expanded,
                        theme: const ExpandableThemeData(crossFadePoint: 0),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Floating button
  Widget editFloatingButton() => FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return EditRecipe(item: widget.recipes!);
              });
        },
        heroTag: "editButton",
        tooltip: 'Edit recipe',
        child: const Icon(Icons.edit),
      );

  Widget deleteFloatingButton() {
    Row deleteItemButtons(context) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                SmartDialog.dismiss();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.blueGrey,
              ),
              child: const Text('No', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection(dotenv.env['MEALSCOLLECTION']!)
                    .doc(widget.recipes!.id!)
                    .delete();

                SmartDialog.showToast('Item deleted!');
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.greenAccent,
              ),
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
    return FloatingActionButton(
      backgroundColor: Colors.indigo,
      onPressed: () {
        SmartDialog.show(builder: (context) {
          return Container(
              width: 350,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(children: [
                const Card(
                    margin: EdgeInsets.all(10),
                    child: Text(
                        'Are you sure that you would like to delete this item?',
                        style: TextStyle(color: Colors.black))),
                // Buttons inside inner dialog
                // Cancel button
                deleteItemButtons(context)
              ]));
        });
      },
      heroTag: "deleteButton",
      tooltip: 'Delete recipe',
      child: const Icon(Icons.delete_forever),
    );
  }

  Widget shareButton() => FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return ShareRecipe(item: widget.recipes!);
              });
        },
        heroTag: "shareButton",
        tooltip: 'Share recipe',
        child: const Icon(Icons.share),
      );

  Widget addToFavouriteFloatingButton() => FloatingActionButton(
        backgroundColor: Colors.pink,
        onPressed: () async {
          if (widget.recipes!.isRecipeLiked!) {
            return await FirebaseFirestore.instance
                .collection(dotenv.env['RECIPESCOLLECTION']!)
                .doc(widget.recipes!.id!)
                .update({'isRecipeLiked': false}).then(
                    (value) => setState(() {}));
          } else {
            return await FirebaseFirestore.instance
                .collection(dotenv.env['RECIPESCOLLECTION']!)
                .doc(widget.recipes!.id!)
                .update({'isRecipeLiked': true}).then(
                    (value) => setState(() {}));
          }
        },
        heroTag: "favouriteButton",
        tooltip: widget.recipes!.isRecipeLiked!
            ? 'Remove recipe from favourites'
            : 'Add recipe to favourites',
        child: widget.recipes!.isRecipeLiked!
            ? const Icon(Icons.favorite)
            : const Icon(Icons.favorite_border),
      );

  Widget addNewRecipeFloatingButton() => FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return const AddRecipe();
              });
        },
        heroTag: "addRecipeButton",
        tooltip: 'Add new recipe',
        child: const Icon(Icons.post_add),
      );

  Widget buildFloatingButton() => Positioned(
        right: 30,
        bottom: 80,
        child: AnimatedFloatingActionButton(
            fabButtons: <Widget>[
              addNewRecipeFloatingButton(),
              addToFavouriteFloatingButton(),
              shareButton(),
              deleteFloatingButton(),
              editFloatingButton(),
            ],
            key: floatingButtonKey,
            colorStartAnimation: Colors.blue,
            colorEndAnimation: Colors.red,
            animatedIconData: AnimatedIcons.menu_close),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              automaticallyImplyLeading: true,
              backgroundColor: Colors.transparent,
              expandedHeight: 300.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  collapseMode: CollapseMode.parallax,
                  background: Image.network(
                    widget.recipes!.image!,
                    fit: BoxFit.cover,
                  )),
            ),
          ];
        },
        body: Stack(children: [
          SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 10.0),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(
                            left: 10.0,
                          ),
                          child: Text(
                            widget.recipes!.name!,
                            maxLines: 2,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 30.0,
                                color: AppColours.primaryColour),
                          )),
                      Padding(
                          padding: const EdgeInsets.only(
                            right: 25.0,
                          ),
                          child: favouriteButton())
                    ]),
                const SizedBox(height: 5.0),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Text(
                        '${widget.recipes!.type!} Recipe',
                        style: TextStyle(color: Colors.grey[600]),
                      )),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text(
                          'Servings',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.recipes!.servingSize!,
                              style: TextStyle(
                                  fontSize: 20.0,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold),
                            )),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          'Preparation time',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        Text(
                          widget.recipes!.preparationTime!,
                          style: TextStyle(
                              fontSize: 20.0,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          'Cooking time',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        Text(
                          widget.recipes!.cookingTime!,
                          style: TextStyle(
                              fontSize: 20.0,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 25.0),
                itemDescriptionSection(),
                Divider(color: Colors.grey[700]),
                itemIngredientsSection(),
                Divider(color: Colors.grey[700]),
                instructionsSection(),
              ],
            ),
          ),
          buildFloatingButton(),
        ]),
      ),
      // floatingActionButton: buildFloatingButton()
    );
  }
}
