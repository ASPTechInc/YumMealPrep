import 'dart:io';
import 'package:another_flushbar/flushbar.dart';
import 'package:card_settings/card_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:yummealprep/models/meal_item_model.dart';
import 'package:yummealprep/shared_widgets/choices.dart' as choices;
import 'package:yummealprep/themes/colours.dart';
import 'package:yummealprep/utils/constants.dart';

class EditMealItem extends StatefulWidget {
  final MealItemModel item;

  const EditMealItem({Key? key, required this.item}) : super(key: key);
  @override
  State<StatefulWidget> createState() => EditMealItemState();
}

class EditMealItemState extends State<EditMealItem> {
  List<MealItemModel> mealTypes = choices.mealTypes2;
  List<MealItemModel> mealTypesFilteredList = [];

  String searchQuery = '';

  // Form keys
  final GlobalKey<FormState> _nameKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _descriptionKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _drinkKey = GlobalKey<FormState>();
  final GlobalKey<FormState> mealItemEditFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _imageKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _nutritionFactsKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _sideDishKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _typeKey = GlobalKey<FormState>();

  // Form nodes
  final FocusNode _nameNode = FocusNode();
  final FocusNode _descriptionNode = FocusNode();

  // Other
  final CollectionReference mealsCollection =
      FirebaseFirestore.instance.collection(dotenv.env['MEALSCOLLECTION']!);

  AutovalidateMode _autoValidateMode = AutovalidateMode.onUserInteraction;
  Uint8List? nutritionFacts;
  Uint8List? image;

  Flushbar showFlushBar(context, String value) {
    return Flushbar(
      backgroundColor: AppColours.dark,
      messageText: Text(value,
          textAlign: TextAlign.center,
          style: GoogleFonts.workSans(
            color: Colors.white,
            fontSize: 16.0,
          )),
      icon: Icon(value.contains('Meal edited') ? Icons.check_box : Icons.close,
          size: 28.0,
          color: value.contains('Meal edited')
              ? Colors.green[300]
              : Colors.red[500]),
      leftBarIndicatorColor:
          value.contains('Meal edited') ? Colors.green[300] : Colors.red[500],
      duration: const Duration(seconds: 3),
      onStatusChanged: (status) {
        // if (status == FlushbarStatus.SHOWING && value != 'Meal edited') {
        //   Future.delayed(const Duration(seconds: 3), () {
        //     Navigator.of(context).pushNamed(Constants.editProfileScreen);
        //   });
        // }
      },
    )..show(this.context);
  }

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

  Future<void> uploadImageToFirebaseStorage(Uint8List? imageInUint8List,
      mealType, imageAttribute, String imageFolderName) async {
    // Convert Uint8List to File image
    final tempDir = await path.getTemporaryDirectory();
    File imageFile = await File('${tempDir.path}/image.png').create();
    imageFile.writeAsBytesSync(imageInUint8List!);
    var imageFileName = basename(imageFile.path);

    // Upload to Firebase Storage

    var firebaseStorageRef = FirebaseStorage.instance
        .ref()
        .child('$imageFolderName/$mealType/$imageFileName');
    var uploadTask = firebaseStorageRef.putFile(imageFile);

    try {
      await uploadTask.then((_) {
        firebaseStorageRef
            .getDownloadURL()
            .then((value) => {imageAttribute = value});
      });
    } catch (error) {
      showFlushBar(context, error.toString());
    }
  }

  Future<void> validateForm(meal) async {
    final form = mealItemEditFormKey.currentState;

    if (form!.validate()) {
      form.save();
      try {
        await mealsCollection.doc(meal.id).update(meal.toJson());
        showFlushBar(context, 'Meal edited!');
      } catch (error) {
        showFlushBar(context, error.toString());
      }
    } else {
      showFlushBar(context, 'Invalid form!');
      setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
    }
  }

  List getKeywordsFromString(String? word) {
    word = word!.toLowerCase();
    var keywordList = [];
    for (var index = 0; index < word.length; index++) {
      keywordList.add(word.substring(0, index + 1));
    }
    return keywordList;
  }

  CardSettingsButton editMealButton(meal) {
    return CardSettingsButton(
      label: 'EDIT ITEM',
      textColor: Colors.white,
      backgroundColor: Colors.teal,
      onPressed: () => validateForm(meal),
    );
  }

  CardSettingsText nameField(mealItemModel) {
    return CardSettingsText(
      key: _nameKey,
      label: 'Name',
      initialValue: widget.item.name,
      autovalidateMode: _autoValidateMode,
      focusNode: _nameNode,
      inputAction: TextInputAction.next,
      inputActionNode: _nameNode,
      numberOfLines: 3,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Name is required';
        return null;
      },
      onChanged: (value) {
        mealItemModel.name = value;
        mealItemModel.searchKeywords =
            FieldValue.arrayUnion(getKeywordsFromString(value));
      },
    );
  }

  CardSettingsParagraph descriptionField(mealItemModel) {
    return CardSettingsParagraph(
        key: _descriptionKey,
        label: 'Description',
        initialValue: widget.item.description,
        numberOfLines: 3,
        focusNode: _descriptionNode,
        onChanged: (value) => mealItemModel.description = value);
  }

  CardSettingsListPicker drinkField(mealItemModel) {
    return CardSettingsListPicker<PickerModel>(
      key: _drinkKey,
      label: 'Drink',
      initialItem: PickerModel(widget.item.drink!),
      hintText: widget.item.drink!,
      autovalidateMode: _autoValidateMode,
      items: choices.drinkTypes,
      validator: (PickerModel? value) {
        if (value == null || value.toString().isEmpty) {
          return 'You must pick a type.';
        }
        return null;
      },
      onChanged: (value) => mealItemModel.drink = value,
    );
  }

  CardSettingsListPicker mealTypeField(mealItemModel) {
    return CardSettingsListPicker<PickerModel>(
      key: _typeKey,
      label: 'Type',
      initialItem: PickerModel(widget.item.type!),
      hintText: widget.item.type!,
      autovalidateMode: _autoValidateMode,
      items: choices.mealTypes,
      validator: (PickerModel? value) {
        if (value == null || value.toString().isEmpty) {
          return 'You must pick a type.';
        }
        return null;
      },
      onChanged: (value) => mealItemModel.type = value,
    );
  }

  CardSettingsCheckboxPicker sideDishField(mealItemModel) {
    return CardSettingsCheckboxPicker<String>(
      key: _sideDishKey,
      label: 'Side Dish',
      initialItems: [widget.item.sideDish!],
      items: choices.allSideDishes,
      autovalidateMode: _autoValidateMode,
      validator: (List<String>? value) {
        if (value == null || value.isEmpty) {
          return 'You must pick at least one side dish.';
        }
        return null;
      },
      onChanged: (value) => mealItemModel.sideDish = value,
    );
  }

  CardSettingsFilePicker nutritionFactsField(mealItemModel) {
    return CardSettingsFilePicker(
        key: _nutritionFactsKey,
        icon: const Icon(Icons.label, color: Colors.teal),
        label: 'Nutrition Facts',
        fileType: FileType.image,
        initialValue: nutritionFacts,
        allowedExtensions: const ['jpeg', 'png', 'jpg'],
        onChanged: (value) => uploadImageToFirebaseStorage(
            value,
            mealItemModel.type,
            mealItemModel.nutritionFacts,
            'nutrition_facts'));
  }

  CardSettingsFilePicker itemImageField(mealItemModel) =>
      CardSettingsFilePicker(
          key: _imageKey,
          icon: const Icon(Icons.photo, color: Colors.teal),
          label: 'Image',
          fileType: FileType.image,
          initialValue: image,
          onChanged: (value) => uploadImageToFirebaseStorage(
              value, mealItemModel.type, mealItemModel.image, 'meals'));

  editMealItemDialog(MealItemModel mealItemModel) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: CardSettings.sectioned(
          labelWidth: 150,
          contentAlign: TextAlign.right,
          cardless: false,
          children: <CardSettingsSection>[
            CardSettingsSection(
              header: CardSettingsHeader(
                labelAlign: TextAlign.center,
                label: 'Edit Meal Details',
              ),
              children: <CardSettingsWidget>[
                nameField(mealItemModel),
                descriptionField(mealItemModel),
                mealTypeField(mealItemModel),
                drinkField(mealItemModel),
                sideDishField(mealItemModel),
                nutritionFactsField(mealItemModel),
                itemImageField(mealItemModel),
              ],
            ),
            CardSettingsSection(
              children: <CardSettingsWidget>[
                editMealButton(mealItemModel),
              ],
            ),
          ],
        ),
      );
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const MealItemModel mealItemModel = MealItemModel(
        category: '',
        description: '',
        drink: '',
        id: '',
        image: Constants.noImageAvailable,
        isMealLiked: false,
        name: '',
        nutritionFacts: Constants.blankNutritionFacts,
        searchKeywords: [],
        sideDish: '',
        type: '');

    return editMealItemDialog(mealItemModel);
  }
}
