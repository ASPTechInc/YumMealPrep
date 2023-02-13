import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:yummealprep/models/meal_item_model.dart';
import 'package:yummealprep/models/recipe_model.dart';
import 'package:yummealprep/screens/search/search_list_view.dart';
import 'package:yummealprep/shared_widgets/custom_divider_view.dart';
import 'package:yummealprep/themes/colours.dart';
import 'package:yummealprep/utils/constants.dart';
import 'package:yummealprep/utils/ui_helpers.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  String mealsSearchQuery = '';
  String recipesSearchQuery = '';
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      selectedIndex = _tabController!.index;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _tabController!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.only(left: 15.0, top: 2.0, bottom: 2.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(2.0),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for items...',
                          hintStyle:
                              Theme.of(context).textTheme.titleSmall!.copyWith(
                                    color: Colors.grey,
                                    fontSize: 17.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          selectedIndex == 0
                              ? setState(() {
                                  mealsSearchQuery = value;
                                })
                              : setState(() {
                                  recipesSearchQuery = value;
                                });
                        },
                      ),
                    ),
                    UIHelper.horizontalSpaceMedium(),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {},
                    )
                  ],
                ),
              ),
              UIHelper.verticalSpaceExtraSmall(),
              TabBar(
                controller: _tabController,
                unselectedLabelColor: Colors.grey,
                labelColor: Colors.black,
                indicatorColor: Colors.red[800],
                labelStyle: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(fontSize: 18.0, color: Colors.red[800]),
                unselectedLabelStyle:
                    Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontSize: 18.0,
                          color: Colors.grey[200],
                        ),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(child: Text('Meals')),
                  Tab(child: Text('Recipes')),
                ],
              ),
              UIHelper.verticalSpaceSmall(),
              const CustomDividerView(dividerHeight: 8.0),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    MealSearchList(searchQuery: mealsSearchQuery),
                    RecipeSearchList(searchQuery: recipesSearchQuery),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MealSearchList extends StatelessWidget {
  final String? mealType;
  final String? searchQuery;

  const MealSearchList({
    Key? key,
    this.mealType,
    required this.searchQuery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> getSearchResults() {
      if (searchQuery == '') {
        if (mealType == null || mealType == '') {
          // Meals data and no search query
          return FirebaseFirestore.instance
              .collection(dotenv.env['MEALSCOLLECTION']!)
              .orderBy('name')
              .snapshots();
        } else {
          // Meals data according to meal type and no search query
          return FirebaseFirestore.instance
              .collection(dotenv.env['MEALSCOLLECTION']!)
              .where('type', isEqualTo: mealType)
              .orderBy('name')
              .snapshots();
        }
      } else {
        if (mealType == null || mealType == '') {
          // Meals data and search query
          return FirebaseFirestore.instance
              .collection(dotenv.env['MEALSCOLLECTION']!)
              .where('searchKeywords', arrayContains: searchQuery)
              .orderBy('name')
              .snapshots();
        } else {
          // Meals data according to meal type and search query
          return FirebaseFirestore.instance
              .collection(dotenv.env['MEALSCOLLECTION']!)
              .where('type', isEqualTo: mealType)
              .where('searchKeywords', arrayContains: searchQuery)
              .orderBy('name')
              .snapshots();
        }
      }
    }

    return StreamBuilder<QuerySnapshot>(
        stream: getSearchResults(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
              // Empty
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

              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> documents =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  var data = MealItemModel.fromJson(documents);
                  return MealSearchListView(
                    searchResults: data,
                  );
                },
              );
            }
          } else if (snapshot.hasError) {
            // Error
            return const Center(
                child: Text('An error has occurred!',
                    maxLines: 3, style: TextStyle(color: Colors.black)));
          } else {
            // Loading
            return Center(
                child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColours.primaryColour),
            ));
          }
        });
  }
}

class RecipeSearchList extends StatelessWidget {
  final String? recipeType;
  final String? searchQuery;

  const RecipeSearchList({
    Key? key,
    this.recipeType,
    required this.searchQuery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> getSearchResults() {
      if (searchQuery == '') {
        if (recipeType == null || recipeType == '') {
          // Recipe data and no search query
          return FirebaseFirestore.instance
              .collection(dotenv.env['RECIPESCOLLECTION']!)
              .orderBy('name')
              .snapshots();
        } else {
          // Meals data according to recipe type and no search query
          return FirebaseFirestore.instance
              .collection(dotenv.env['RECIPESCOLLECTION']!)
              .where('type', isEqualTo: recipeType)
              .orderBy('name')
              .snapshots();
        }
      } else {
        if (recipeType == null || recipeType == '') {
          // Recipe data and search query
          return FirebaseFirestore.instance
              .collection(dotenv.env['RECIPESCOLLECTION']!)
              .where('searchKeywords', arrayContains: searchQuery)
              .orderBy('name')
              .snapshots();
        } else {
          // Recipe data according to recipe type and search query
          return FirebaseFirestore.instance
              .collection(dotenv.env['RECIPESCOLLECTION']!)
              .where('type', isEqualTo: recipeType)
              .where('searchKeywords', arrayContains: searchQuery)
              .orderBy('name')
              .snapshots();
        }
      }
    }

    return StreamBuilder<QuerySnapshot>(
        stream: getSearchResults(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
              // Empty
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
              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> documents =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  var data = RecipeModel.fromJson(documents);
                  return RecipeSearchListView(
                    searchResults: data,
                  );
                },
              );
            }
          } else if (snapshot.hasError) {
            // Error
            return const Center(
                child: Text('An error has occurred!',
                    maxLines: 3, style: TextStyle(color: Colors.black)));
          } else {
            // Loading
            return Center(
                child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColours.primaryColour),
            ));
          }
        });
  }
}
