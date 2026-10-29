import 'package:flutter/material.dart';

import 'package:yummealprep/widgets/catalogue_list.dart';

/// Searches every meal and recipe by name, description, ingredients, drink
/// and side dishes.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: SearchBar(
            controller: _controller,
            hintText: 'Search meals and recipes',
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(0),
            trailing: [
              if (query.isNotEmpty)
                IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(_controller.clear),
                ),
            ],
            onChanged: (value) => setState(() {}),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Meals'),
              Tab(text: 'Recipes'),
            ],
          ),
        ),
        // Both tabs search with the same text, so switching tabs keeps it.
        body: TabBarView(
          children: [
            MealList(query: query),
            RecipeList(query: query),
          ],
        ),
      ),
    );
  }
}
