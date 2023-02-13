import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_awesome_select/flutter_awesome_select.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent-tab-view.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:weekly_date_picker/datetime_apis.dart';
import 'package:weekly_date_picker/weekly_date_picker.dart';
import 'package:yummealprep/models/meal_item_model.dart';
import 'package:yummealprep/models/meal_planner_item_model.dart';
import 'package:yummealprep/models/meal_slot_model.dart';
import 'package:yummealprep/models/models_logic.dart';
import 'package:yummealprep/screens/meals/meal_details_screen.dart';
import 'package:yummealprep/themes/colours.dart';
import 'package:yummealprep/utils/constants.dart';
import 'package:yummealprep/utils/meal_item.dart';
import 'package:yummealprep/utils/ui_helpers.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({Key? key}) : super(key: key);

  @override
  MealPlannerScreenState createState() => MealPlannerScreenState();
}

class MealPlannerScreenState extends State<MealPlannerScreen> {
  final CollectionReference mealsCollection =
      FirebaseFirestore.instance.collection(dotenv.env['MEALSCOLLECTION']!);

  CalendarFormat _calendarFormat = CalendarFormat.month;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey(); // Create a key

  List<MealSlot> mealSlots = getMealSlots();
  List<String> meal = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime selectedDayPopUpDialog = DateTime.now();

  Uint8List? nutritionFacts;
  Uint8List? image;
  QuerySnapshot? mealsInDB;
  List<QueryDocumentSnapshot?>? mealDocs;
  bool? isItemSelected = false;
  List<String> itemsSelectedByID = [];
  String? selectedMealSlot = '';
  String? selectedMealItem = '';
  var itemsSelectedData = [];

  Future<Uint8List> getNutritionFacts() async {
    final ByteData imageBytes =
        await rootBundle.load(Constants.blankNutritionFacts);
    return imageBytes.buffer.asUint8List();
  }

  Future<Uint8List> getImage() async {
    final ByteData imageBytes =
        await rootBundle.load(Constants.noImageAvailable);
    return imageBytes.buffer.asUint8List();
  }

  List getKeywordsFromString(String? word) {
    word = word!.toLowerCase();
    var keywordList = [];
    for (var index = 0; index < word.length; index++) {
      keywordList.add(word.substring(0, index + 1));
    }
    return keywordList;
  }

  showImage(String imageURL, String name) {
    return SmartDialog.show(builder: (context) {
      return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              width: 200,
              height: 200,
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
            Container(
              height: 50,
              width: 160,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(name,
                  maxLines: 3, style: const TextStyle(color: Colors.white)),
            ),
          ]);
    });
  }

  Future<void> addItemToMealSchedule(
      element, selectedDay, mealScheduleItem, timestamp) async {
    // setState(() {})); - refreshes/reloads the screen when an item is deleted
    try {
      await FirebaseFirestore.instance
          .collection(dotenv.env['MEALSCOLLECTION']!)
          .doc(element['id'])
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

  ListTile mealItem(element, selectedDay) {
    return ListTile(
      isThreeLine: true,
      dense: true,
      selected: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      title: Text(
        element['name'],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RichText(
              text: TextSpan(
                text: 'Drink: ',
                style: const TextStyle(
                    // fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
                children: <TextSpan>[
                  TextSpan(
                    text: element['drink'],
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                text: 'Side dish: ',
                style: const TextStyle(
                    // fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
                children: <TextSpan>[
                  TextSpan(
                    text: element['sideDish'],
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ]),
      onTap: () async {
        Row addItemToMealScheduleButtons(context) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    // Navigator.pop(context);
                    SmartDialog.dismiss();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child:
                      const Text('No', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () async {
                    var timestamp = Timestamp.fromDate(selectedDay);

                    MealPlannerItemModel mealScheduleItem =
                        MealPlannerItemModel(
                      name: element['name'],
                      category: element['category'],
                      dateCreated: timestamp,
                      dateSelected: selectedDay,
                      description: element['description'],
                      drink: element['drink'],
                      id: element['id'],
                      image: element['image'],
                      isMealInMealPlanner: true,
                      isMealLiked: element['isMealLiked'],
                      nutritionFacts: element['nutritionFacts'],
                      searchKeywords: element['searchKeywords'],
                      sideDish: element['sideDish'],
                      type: element['type'],
                    );

                    await addItemToMealSchedule(
                        element, selectedDay, mealScheduleItem, timestamp);

                    SmartDialog.showToast('Item added to meal schedule!');
                    SmartDialog.dismiss();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Yes, I am sure',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );

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
                        'Are you sure that you would like to add this item to your meal schedule?',
                        style: TextStyle(color: Colors.black))),
                // Buttons inside inner dialog
                // Cancel button

                addItemToMealScheduleButtons(context)
              ]));
        });
      },
    );
  }

  Future<void> onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  // Meal slot dialog
  mealSlotDialog() async {
    Container modalFooterButtons(state) {
      return Container(
        margin: const EdgeInsets.only(left: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 7.0,
        ),
        child: state.selection?.length != 1
            ? TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      const Color.fromARGB(255, 211, 5, 5)),
                  textStyle: MaterialStateProperty.all<TextStyle>(
                      const TextStyle(color: Colors.white)),
                ),
                onPressed: () => state.closeModal(confirmed: false),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.white)))
            : TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      Theme.of(context).primaryColor),
                  textStyle: MaterialStateProperty.all<TextStyle>(
                      const TextStyle(color: Colors.white)),
                ),
                onPressed: () => state.closeModal(confirmed: true),
                child: const Text(
                  'Select',
                  style: TextStyle(color: Colors.white),
                )),
      );
    }

    Widget mealSlotDialogContent() {
      return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(dotenv.env['MEALSCOLLECTION']!)
              .where('isMealInMealPlanner', isEqualTo: false)
              .orderBy('name')
              .snapshots(),
          builder: (context, snapshot) {
            List<Map<String, String>> mealSlotOptions = [];
            List<String> mealTypes = [];

            if (!snapshot.hasData || snapshot.data == null) {
              // Empty or null
              return Center(
                child: Image.asset(
                  Constants.noDataImage,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Image.asset(
                      Constants.errorImage,
                    ),
                  ),
                ),
              );
            } else {
              // Has data
              List<Map<String, dynamic>?>? documentData = snapshot.data?.docs
                  .map((element) => element.data() as Map<String, dynamic>?)
                  .toList();

              for (int index = 0; index < documentData!.length; index++) {
                mealSlotOptions.add({
                  'value': documentData[index]!['name'],
                  'title': documentData[index]!['name'],
                  'type': documentData[index]!['type'],
                });
                mealTypes.add(documentData[index]!['type']);
              }
              // Remove duplicate meal types
              mealTypes = mealTypes.toSet().toList();

              // Generate the meal type slots
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: mealTypes.length,
                  itemBuilder: (context, index) {
                    String? mealType = mealTypes[index];
                    // Filter meal slot options that matches meal type
                    final mealSlotOptionsFiltered = mealSlotOptions
                        .where((element) => element['type'] == mealType)
                        .toList();

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          SmartSelect<String?>.single(
                              title: mealType,
                              modalConfig: S2ModalConfig(
                                title: DateFormat('dd MMMM, yyyy')
                                    .format(_selectedDay!),
                                style: const S2ModalStyle(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20.0)),
                                  ),
                                ),
                              ),
                              placeholder: 'Choose meal item',
                              selectedValue: selectedMealItem,
                              onChange: (selected) async {
                                setState(
                                    () => selectedMealItem = selected.value);
                                final Map<String, dynamic>?
                                    selectedMealItemData =
                                    documentData.firstWhere((element) =>
                                        element!['name'] == selectedMealItem &&
                                        element['type'] == mealType);

                                // Add item to meal plan
                                var timestamp =
                                    Timestamp.fromDate(_selectedDay!);

                                MealPlannerItemModel mealScheduleItem =
                                    MealPlannerItemModel(
                                  name: selectedMealItemData!['name'],
                                  category: selectedMealItemData['category'],
                                  dateCreated: timestamp,
                                  dateSelected: _selectedDay,
                                  description:
                                      selectedMealItemData['description'],
                                  drink: selectedMealItemData['drink'],
                                  id: selectedMealItemData['id'],
                                  image: selectedMealItemData['image'],
                                  isMealInMealPlanner: true,
                                  isMealLiked:
                                      selectedMealItemData['isMealLiked'],
                                  nutritionFacts:
                                      selectedMealItemData['nutritionFacts'],
                                  searchKeywords:
                                      selectedMealItemData['searchKeywords'],
                                  selectedDayCalendarNum: _selectedDay!.day,
                                  sideDish: selectedMealItemData['sideDish'],
                                  timestamp: timestamp.seconds.toString(),
                                  type: selectedMealItemData['type'],
                                );

                                await addItemToMealSchedule(
                                    selectedMealItemData,
                                    _selectedDay,
                                    mealScheduleItem,
                                    timestamp);

                                SmartDialog.showToast(
                                    'Item added to meal schedule!');
                                // Set selected item to default value
                                setState(() => selectedMealItem = '');
                                if (context.mounted) {
                                  Navigator.of(context, rootNavigator: true)
                                      .pop('dialog');
                                }
                              },
                              choiceItems: S2Choice.listFrom<String,
                                  Map<String, String>>(
                                source: mealSlotOptionsFiltered,
                                value: (index, item) => item['value'] ?? '',
                                title: (index, item) => item['title'] ?? '',
                                group: (index, item) => item['type'] ?? '',
                              ),
                              choiceGrouped: true,
                              groupHeaderStyle: S2GroupHeaderStyle(
                                  textStyle:
                                      const TextStyle(color: Colors.white),
                                  backgroundColor:
                                      getMealSlotBgColourBasedOnMealType(
                                          mealType)),
                              modalFilter: true,
                              modalFilterAuto: true,
                              modalType: S2ModalType.popupDialog,
                              tileBuilder: (context, state) {
                                return S2Tile.fromState(
                                  state,
                                  isTwoLine: true,
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        getMealSlotBgColourBasedOnMealType(
                                            mealType),
                                  ),
                                );
                              },
                              modalFooterBuilder: (context, state) =>
                                  modalFooterButtons(state)),
                        ],
                      ),
                    );
                  },
                ),
              );
            }
          });
    }

    return await showDialog(
        context: context,
        builder: (BuildContext context) {
          Widget dialogContent = mealSlotDialogContent();
          return AlertDialog(
              title: Row(
                children: [
                  const SizedBox(width: 98),
                  const Text(
                    'Meal Slot',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              ),
              content: dialogContent // mealSlotDialogContent(),
              );
        });
  }

  Stack noMealPlannedContainer() => Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 250,
            height: 100,
            child: DottedBorder(
                color: Colors.black,
                strokeWidth: 3,
                dashPattern: const [10, 8],
                child: Container()),
          ),
          Positioned(
            top: 10,
            child: Icon(Icons.add_circle_rounded,
                size: 35, color: Colors.indigo[400]),
          ),
          const Positioned(
              top: 50,
              child: Text(
                'No meal planned',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              )),
        ],
      );

  void navigateToDetailsScreen(data) {
    pushNewScreen(
      context,
      screen: MealDetailsScreen(meals: data),
      withNavBar: true,
      pageTransitionAnimation: PageTransitionAnimation.cupertino,
    );
  }

  Future<void> removeItemFromMealPlan(itemID) async {
    // setState(() {})); - refreshes/reloads the screen when an item is deleted

    return await FirebaseFirestore.instance
        .collection(dotenv.env['MEALSCOLLECTION']!)
        .doc(itemID)
        .update({'isMealLiked': false}).then((value) => setState(() {}));
  }

  Dismissible buildContent(data) => Dismissible(
        key: Key(data!.id!),
        // Swipe from right to left to remove item from favourites
        direction: DismissDirection.endToStart,
        background: Container(
            margin: const EdgeInsets.only(left: 10),
            alignment: Alignment.centerRight,
            color: Colors.red,
            child: Container(
                margin: const EdgeInsets.only(right: 50),
                child: const Text('Remove',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)))),
        onDismissed: (direction) => removeItemFromMealPlan(data!.id!),
        child: GestureDetector(
          onTap: () => navigateToDetailsScreen(data),
          child: Container(
            margin: const EdgeInsets.all(10.0),
            padding: const EdgeInsets.only(right: 50.0),
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
                        data!.image!,
                        height: 60.0,
                        width: 60.0,
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
                            data!.name!,
                            maxLines: 1,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(fontSize: 15.0),
                          ),
                          Text(
                            data!.type!,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(fontSize: 12.0),
                          ),
                          Text(data!.description!,
                              maxLines: 2,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                      color: Colors.grey[600], fontSize: 13.5)),
                          UIHelper.verticalSpaceSmall(),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 17,
                  left: 43,
                  child: Icon(
                    Icons.favorite,
                    size: 14.0,
                    color:
                        data!.isMealLiked! ? Colors.red[800] : Colors.grey[600],
                  ),
                ),
                Positioned(
                  bottom: 59,
                  left: 48,
                  child: CircleAvatar(
                    radius: 6,
                    backgroundColor:
                        getMealSlotBgColourBasedOnMealType(data!.type!),
                  ),
                )
              ],
            ),
          ),
        ),
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
                '${DateFormat('MMM').format(DateTime(0, selectedDayPopUpDialog.month))}; Week:',
            selectedDay: selectedDayPopUpDialog,
            changeDay: (value) {
              setState(() {
                selectedDayPopUpDialog = value;
                _selectedDay = value;
              });
              selectedDayPopUpDialog.isAfter(DateTime.now()) ||
                      selectedDayPopUpDialog.isSameDateAs(DateTime.now())
                  ? mealSlotDialog()
                  : SmartDialog.showToast(
                      'Selected date must be equal to or after today\'s date!');
            },
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: UIHelper.openDrawer(context),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Meal Planner'),
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 20),
              child: IconButton(
                onPressed: () => addItemToMealPlanPopUpDialog(),
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
          // Calendar
          TableCalendar<MealPlannerItemModel>(
            firstDay: firstCalendarDate,
            lastDay: lastCalendarDate,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
            ),
            onDaySelected: onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8.0),
          const Positioned(
            top: 60, //141
            child: Divider(
              color: Colors.black,
            ),
          ),
          // Meal Items container
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(dotenv.env['MEALSCHEDULESCOLLECTION']!)
                .doc(_selectedDay!.year.toString())
                .collection(
                    DateFormat('MMMM').format(DateTime(0, _selectedDay!.month)))
                .where('selectedDayCalendarNum', isEqualTo: _selectedDay!.day)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  // Empty
                  return Positioned(
                      height: 100,
                      bottom: 140,
                      left: 80,
                      child: GestureDetector(
                          onTap: () async {
                            mealSlotDialog();
                          },
                          child: noMealPlannedContainer()));
                } else {
                  // Has data
                  return Positioned(
                    height: 400,
                    bottom: 100,
                    left: 10,
                    right: 10,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Divider(),
                          ListView.separated(
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                              height: 3.0,
                            ),
                            physics: const BouncingScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              var data = MealItemModel.fromJson(
                                  snapshot.data!.docs[index].data());
                              return buildContent(data);
                            },
                          ),
                        ]),
                  );
                }
              } else if (snapshot.hasError) {
                // Error
                return const Center(
                    child: Text('An error has occurred!',
                        maxLines: 3,
                        style: TextStyle(
                            color: Colors
                                .black))); //isDarkTheme ? Colors.white : Colors.black)));
              } else {
                // Loading
                return Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColours.primaryColour)
                        //isDarkTheme ? Colors.blue : AppColours.primaryColour),
                        ));
              }
            },
          ),
        ],
      ),
    );
  }
}
