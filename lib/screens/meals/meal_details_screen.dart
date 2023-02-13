import 'package:animated_floating_buttons/animated_floating_buttons.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:like_button/like_button.dart';
import 'package:recase/recase.dart';
import 'package:weekly_date_picker/datetime_apis.dart';
import 'package:weekly_date_picker/weekly_date_picker.dart';
import 'package:yummealprep/models/meal_item_model.dart';
import 'package:yummealprep/models/meal_planner_item_model.dart';
import 'package:yummealprep/screens/meals/widgets/add_meal_item_widget.dart';
import 'package:yummealprep/screens/meals/widgets/edit_meal_item_widget.dart';
import 'package:yummealprep/screens/meals/widgets/share_meal_widget.dart';
import 'package:yummealprep/themes/colours.dart';
import 'package:yummealprep/utils/constants.dart';

class MealDetailsScreen extends StatefulWidget {
  final MealItemModel? meals;
  const MealDetailsScreen({
    Key? key,
    required this.meals,
  }) : super(key: key);

  @override
  MealDetailsScreenState createState() => MealDetailsScreenState();
}

class MealDetailsScreenState extends State<MealDetailsScreen> {
  final GlobalKey<AnimatedFloatingActionButtonState> floatingButtonKey =
      GlobalKey<AnimatedFloatingActionButtonState>();
  DateTime selectedDay = DateTime.now();

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
            color: widget.meals!.isMealLiked! ? Colors.red : Colors.grey,
            // size: buttonSize,
          );
        },
        likeCount: null,
        countBuilder: (count, isFavourite, text) {
          var color = widget.meals!.isMealLiked! ? Colors.red : Colors.grey;
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
          widget.meals!.description!,
          textAlign: TextAlign.justify,
          style: const TextStyle(
              wordSpacing: 3.0, textBaseline: TextBaseline.alphabetic),
        ),
      )
    ]);
  }

  AwesomeDialog itemImageDialog(context, String imageURL) {
    // Filter the imageURL to extract the name of the nutrition facts
    String startString = "nutrition_facts%2F";
    String endString = "_nutrition_facts";
    int startIndex = imageURL.indexOf(startString);
    int endIndex = imageURL.indexOf(endString, startIndex + startString.length);

    String output =
        imageURL.substring(startIndex + startString.length, endIndex);

    String itemName = output.replaceAll('_', ' ');
    Column centreImage() => Column(children: [
          Container(
            width: 400,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(
                  width: 4, color: Theme.of(context).scaffoldBackgroundColor),
              boxShadow: [
                BoxShadow(
                    spreadRadius: 2,
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 10))
              ],
              shape: BoxShape.rectangle,
              image: DecorationImage(
                  fit: BoxFit.fill,
                  image: imageURL.isNotEmpty
                      ? NetworkImage(imageURL)
                      : const NetworkImage(Constants.noImageAvailable)),
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(itemName.sentenceCase,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(
            height: 10,
          ),
        ]);

    return AwesomeDialog(
      context: context,
      width: 600,
      animType: AnimType.scale,
      dialogType: DialogType.success,
      showCloseIcon: true,
      dismissOnTouchOutside: true,
      dismissOnBackKeyPress: true,
      body: centreImage(),
    )..show();
  }

  ExpandableNotifier nutritionFactsCollapsibleSection(text, field, itemList) {
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
                    tapBodyToCollapse: false,
                  ),
                  header: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.bodyLarge,
                      )),
                  collapsed: const Text(
                    'Nutrition Facts for each meal item',
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  expanded: SizedBox(
                    height: 300,
                    child: ListView.separated(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (context, index) => const SizedBox(
                        width: 5.0,
                      ),
                      itemCount: widget.meals!.nutritionFacts!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                          onTap: () => itemImageDialog(context,
                              widget.meals!.nutritionFacts![index].toString()),
                          child: Image.network(
                              widget.meals!.nutritionFacts![index],
                              fit: BoxFit.fill),
                        );
                      },
                    ),
                    //   ],
                    // ),
                    //   )
                    // ],
                    // ),
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

  Column nutritionFactsSection() {
    return Column(children: <Widget>[
      const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text(
              'Nutrition Facts',
              style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            )),
      ),
      const SizedBox(
        height: 10.0,
      ),
      nutritionFactsCollapsibleSection('Expand to view more', 'Nutrition Facts',
          widget.meals!.nutritionFacts!),
      const SizedBox(
        height: 10.0,
      ),
    ]);
  }

// Floating button
  Widget editFloatingButton() => FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return EditMealItem(item: widget.meals!);
              });
        },
        heroTag: "editButton",
        tooltip: 'Edit meal',
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
                    .doc(widget.meals!.id!)
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
      tooltip: 'Delete meal',
      child: const Icon(Icons.delete_forever),
    );
  }

  Widget shareButton() => FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return ShareMealItemScreen(item: widget.meals!);
              });
        },
        heroTag: "shareButton",
        tooltip: 'Share meal',
        child: const Icon(Icons.share),
      );

  Widget addToFavouriteFloatingButton() => FloatingActionButton(
        backgroundColor: Colors.pink,
        onPressed: () async {
          if (widget.meals!.isMealLiked!) {
            return await FirebaseFirestore.instance
                .collection(dotenv.env['MEALSCOLLECTION']!)
                .doc(widget.meals!.id!)
                .update({'isMealLiked': false}).then(
                    (value) => setState(() {}));
          } else {
            return await FirebaseFirestore.instance
                .collection(dotenv.env['MEALSCOLLECTION']!)
                .doc(widget.meals!.id!)
                .update({'isMealLiked': true}).then((value) => setState(() {}));
          }
        },
        heroTag: "favouriteButton",
        tooltip: widget.meals!.isMealLiked!
            ? 'Remove meal from favourites'
            : 'Add meal to favourites',
        child: widget.meals!.isMealLiked!
            ? const Icon(Icons.favorite)
            : const Icon(Icons.favorite_border),
      );

  Future<void> addItemToMealSchedule(
      selectedDay, mealScheduleItem, timestamp) async {
    // setState(() {})); - refreshes/reloads the screen when an item is deleted
    try {
      await FirebaseFirestore.instance
          .collection(dotenv.env['MEALSCOLLECTION']!)
          .doc(widget.meals!.id)
          .update({'isMealInMealPlanner': true});

      await FirebaseFirestore.instance
          .collection(dotenv.env['MEALSCHEDULESCOLLECTION']!)
          .doc(selectedDay.year.toString())
          .collection(DateFormat('MMMM').format(DateTime(0, selectedDay.month)))
          .doc(timestamp.seconds.toString())
          .set(mealScheduleItem.toJson());

      SmartDialog.showToast('Item added to meal schedule!');
      SmartDialog.dismiss();
    } catch (error) {
      SmartDialog.showToast('An $error has ocurred!');
    }
  }

  Widget addNewMealFloatingButton() => FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return const AddMealItem();
              });
        },
        heroTag: "addNewMealButton",
        tooltip: 'Add new meal',
        child: const Icon(Icons.post_add),
      );

  Widget addMealToMealPlanFloatingButton() {
    Row confirmAdditionOfMealItemToMealPlanButtons(context) => Row(
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
                Timestamp timestamp = Timestamp.fromDate(selectedDay);

                MealPlannerItemModel mealScheduleItem = MealPlannerItemModel(
                  name: widget.meals!.name,
                  category: widget.meals!.category,
                  dateCreated: timestamp,
                  dateSelected: selectedDay,
                  description: widget.meals!.description,
                  drink: widget.meals!.drink,
                  id: widget.meals!.id,
                  image: widget.meals!.image,
                  isMealInMealPlanner: true,
                  isMealLiked: widget.meals!.isMealLiked,
                  nutritionFacts: widget.meals!.nutritionFacts,
                  searchKeywords: widget.meals!.searchKeywords,
                  selectedDayCalendarNum: selectedDay.day,
                  sideDish: widget.meals!.sideDish,
                  timestamp: timestamp.seconds.toString(),
                  type: widget.meals!.type,
                );

                await addItemToMealSchedule(
                    selectedDay, mealScheduleItem, timestamp);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );

    Future<dynamic> addItemToMealPlanPopUpDialog() {
      return SmartDialog.show(
        builder: (context) {
          return Container(
            width: 350,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: WeeklyDatePicker(
              enableWeeknumberText: true,
              weekdayText:
                  '${DateFormat('MMM').format(DateTime(0, selectedDay.month))}; Week:',
              selectedDay: selectedDay,
              changeDay: (value) {
                setState(() {
                  selectedDay = value;
                });
                selectedDay.isAfter(DateTime.now()) ||
                        selectedDay.isSameDateAs(DateTime.now())
                    ? SmartDialog.show(builder: (context) {
                        return Container(
                            width: 300,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Column(children: [
                              Card(
                                  margin: const EdgeInsets.all(10),
                                  child: Text(
                                      'Are you sure that you would like to add this item to the plan for ${Jiffy(DateTime(selectedDay.year, selectedDay.month, selectedDay.day)).format("EEEE do MMMM, yyyy")}?',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold))),

                              // Buttons inside  dialog

                              confirmAdditionOfMealItemToMealPlanButtons(
                                  context)
                            ]));
                      })
                    : SmartDialog.showToast(
                        'Selected date must be equal to or after today\'s date!');
              },
            ),
          );
        },
      );
    }

    return FloatingActionButton(
      backgroundColor: Colors.brown,
      onPressed: () => addItemToMealPlanPopUpDialog(),
      heroTag: "addMealToScheduleButton",
      tooltip: 'Add new item to meal plan',
      child: const Icon(Icons.calendar_month),
    );
  }

  Positioned buildFloatingButton() => Positioned(
        right: 30,
        bottom: 80,
        child: AnimatedFloatingActionButton(
            fabButtons: <Widget>[
              addMealToMealPlanFloatingButton(),
              addNewMealFloatingButton(),
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
                  collapseMode: CollapseMode.pin,
                  background: Image.network(
                    widget.meals!.image!,
                    fit: BoxFit.cover,
                  )),
            ),
          ];
        },
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 10.0),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 10.0,
                      ),
                      child: Text(
                        widget.meals!.name!,
                        maxLines: 2,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 23.0,
                            color: AppColours.primaryColour),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5.0),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              '${widget.meals!.type!} Meal',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                              padding: const EdgeInsets.only(right: 25.0),
                              child: favouriteButton()),
                        ),
                      ]),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Text(
                            'Drink',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.meals!.drink!,
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
                            'Side dish',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          Text(
                            widget.meals!.sideDish!,
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
                  nutritionFactsSection(),
                ],
              ),
            ),
            buildFloatingButton(),
          ],
        ),
      ),
    );
  }
}
