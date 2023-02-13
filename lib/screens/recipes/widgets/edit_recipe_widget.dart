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
import 'package:yummealprep/models/recipe_model.dart';
import 'package:yummealprep/themes/colours.dart';
import 'package:yummealprep/utils/constants.dart';
import 'package:yummealprep/shared_widgets/choices.dart' as choices;

class EditRecipe extends StatefulWidget {
  final RecipeModel item;

  const EditRecipe({Key? key, required this.item}) : super(key: key);
  @override
  State<StatefulWidget> createState() => EditRecipeState();
}

class EditRecipeState extends State<EditRecipe> {
  List<RecipeModel> recipeTypes = choices.recipeTypes2;

  // Form keys
  final GlobalKey<FormState> recipeEditFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> itemNameKey = GlobalKey<FormState>();
  final GlobalKey<FormState> itemDescriptionKey = GlobalKey<FormState>();
  final GlobalKey<FormState> recipeTypeKey = GlobalKey<FormState>();
  final GlobalKey<FormState> ingredientsKey = GlobalKey<FormState>();
  final GlobalKey<FormState> instructionsKey = GlobalKey<FormState>();
  final GlobalKey<FormState> cookingTimeKey = GlobalKey<FormState>();
  final GlobalKey<FormState> preparationTimeKey = GlobalKey<FormState>();
  final GlobalKey<FormState> servingSizeKey = GlobalKey<FormState>();
  final GlobalKey<FormState> recipeImageKey = GlobalKey<FormState>();

  // Focus nodes
  final FocusNode itemNameNode = FocusNode();
  final FocusNode itemDescriptionNode = FocusNode();
  final FocusNode ingredientsNode = FocusNode();
  final FocusNode instructionsNode = FocusNode();

  // Other
  final CollectionReference recipesCollection =
      FirebaseFirestore.instance.collection(dotenv.env['RECIPESCOLLECTION']!);

  AutovalidateMode _autoValidateMode = AutovalidateMode.onUserInteraction;
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
      icon: Icon(
          value.contains('Recipe edited') ? Icons.check_box : Icons.close,
          size: 28.0,
          color: value.contains('Recipe edited')
              ? Colors.green[300]
              : Colors.red[500]),
      leftBarIndicatorColor:
          value.contains('Recipe edited') ? Colors.green[300] : Colors.red[500],
      duration: const Duration(seconds: 3),
      onStatusChanged: (status) {
        // if (status == FlushbarStatus.SHOWING && value != 'Recipe edited') {
        //   Future.delayed(const Duration(seconds: 3), () {
        //     Navigator.of(context).pushNamed(Constants.editProfileScreen);
        //   });
        // }
      },
    )..show(this.context);
  }

  Future<Uint8List> getImage() async {
    final ByteData imageBytes =
        await rootBundle.load(Constants.noImageAvailable);
    return imageBytes.buffer.asUint8List();
  }

  Future<void> uploadImageToFirebaseStorage(Uint8List? imageInUint8List,
      recipeType, imageAttribute, String imageFolderName) async {
    // Convert Uint8List to File image
    final tempDir = await path.getTemporaryDirectory();
    File imageFile = await File('${tempDir.path}/image.png').create();
    imageFile.writeAsBytesSync(imageInUint8List!);
    var imageFileName = basename(imageFile.path);

    // Upload to Firebase Storage

    var firebaseStorageRef = FirebaseStorage.instance
        .ref()
        .child('$imageFolderName/$recipeType/$imageFileName');
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

  Future<void> validateForm(recipe) async {
    final form = recipeEditFormKey.currentState;

    if (form!.validate()) {
      form.save();
      try {
        await recipesCollection.doc(recipe.id).update(recipe.toJson());
        showFlushBar(context, 'Recipe edited!');
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

  CardSettingsButton editRecipeButton(recipe) {
    return CardSettingsButton(
      label: 'EDIT ITEM',
      textColor: Colors.white,
      backgroundColor: Colors.teal,
      onPressed: () => validateForm(recipe),
    );
  }

  CardSettingsText nameField(recipeModel) {
    return CardSettingsText(
      key: itemNameKey,
      label: 'Name',
      initialValue: widget.item.name,
      autovalidateMode: _autoValidateMode,
      focusNode: itemNameNode,
      inputAction: TextInputAction.next,
      inputActionNode: itemNameNode,
      numberOfLines: 3,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Name is required';
        return null;
      },
      onChanged: (value) {
        recipeModel.name = value;
        recipeModel.searchKeywords =
            FieldValue.arrayUnion(getKeywordsFromString(value));
      },
    );
  }

  CardSettingsParagraph descriptionField(recipeModel) {
    return CardSettingsParagraph(
        key: itemDescriptionKey,
        label: 'Description',
        initialValue: widget.item.description,
        numberOfLines: 3,
        focusNode: itemDescriptionNode,
        onChanged: (value) => recipeModel.description = value);
  }

  CardSettingsListPicker recipeTypeField(recipeModel) {
    return CardSettingsListPicker<PickerModel>(
      key: recipeTypeKey,
      label: 'Type',
      initialItem: PickerModel(widget.item.type!),
      hintText: widget.item.type!,
      autovalidateMode: _autoValidateMode,
      items: choices.recipeTypes,
      validator: (PickerModel? value) {
        if (value == null || value.toString().isEmpty) {
          return 'You must pick a type.';
        }
        return null;
      },
      onChanged: (value) => recipeModel.type = value,
    );
  }

  CardSettingsParagraph ingredientsField(recipeModel) {
    return CardSettingsParagraph(
        key: ingredientsKey,
        label: 'Ingredients',
        initialValue: widget.item.ingredients!,
        numberOfLines: 3,
        focusNode: ingredientsNode,
        onChanged: (value) {
          // Split ingredients' field text by full stop
          List<String> lstSplit = value.split('.');
          List<String> stringsLst = [];

          for (final item in lstSplit) {
            stringsLst.add('"$item."');
          }
          recipeModel.ingredients = FieldValue.arrayUnion(stringsLst);
        });
  }

  CardSettingsParagraph instructionsField(recipeModel) {
    return CardSettingsParagraph(
        key: instructionsKey,
        label: 'Instructions',
        initialValue: widget.item.instructions!,
        numberOfLines: 3,
        focusNode: instructionsNode,
        onSaved: (value) {
          // Split instructions' field text by full stop
          List<String> lstSplit = value!.split('.');
          List<String> stringsLst = [];

          for (final item in lstSplit) {
            stringsLst.add('"$item."');
          }
          recipeModel.instructions = FieldValue.arrayUnion(stringsLst);
        });
  }

  CardSettingsNumberPicker cookingTimeField(recipeModel) {
    // Convert string to int exclusive of the time unit
    return CardSettingsNumberPicker(
        key: cookingTimeKey,
        label: 'Cooking Time',
        initialValue: int.parse(
            widget.item.cookingTime!.replaceAll(RegExp('[^0-9]'), '')),
        min: 1,
        max: 120,
        onSaved: (value) => recipeModel.cookingTime = '$value mins');
  }

  CardSettingsNumberPicker preparationTimeField(recipeModel) {
    // Convert string to int exclusive of the time unit
    return CardSettingsNumberPicker(
        key: preparationTimeKey,
        label: 'Preparation Time',
        initialValue: int.parse(
            widget.item.preparationTime!.replaceAll(RegExp('[^0-9]'), '')),
        min: 1,
        max: 120,
        onSaved: (value) => recipeModel.preparationTime = '$value mins');
  }

  CardSettingsNumberPicker servingSizeField(recipeModel) {
    return CardSettingsNumberPicker(
        key: servingSizeKey,
        label: 'Serving Size',
        initialValue: int.parse(
            widget.item.servingSize!.replaceAll(RegExp('[^0-9]'), '')),
        min: 1,
        max: 10,
        onSaved: (value) => recipeModel.servingSize = '$value mins');
  }

  CardSettingsFilePicker recipeImageField(recipeModel) {
    return CardSettingsFilePicker(
        key: recipeImageKey,
        icon: const Icon(Icons.photo, color: Colors.teal),
        label: 'Image',
        fileType: FileType.image,
        initialValue: image,
        onSaved: (value) => uploadImageToFirebaseStorage(
            value, recipeModel.type, recipeModel.image, 'recipes'));
  }

  Dialog addRecipeDialog(RecipeModel recipeModel) => Dialog(
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
                label: 'Edit Recipe Details',
              ),
              children: <CardSettingsWidget>[
                nameField(recipeModel),
                descriptionField(recipeModel),
                recipeTypeField(recipeModel),
                ingredientsField(recipeModel),
                instructionsField(recipeModel),
                cookingTimeField(recipeModel),
                preparationTimeField(recipeModel),
                servingSizeField(recipeModel),
                recipeImageField(recipeModel),
              ],
            ),
            CardSettingsSection(
              children: <CardSettingsWidget>[
                editRecipeButton(recipeModel),
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
    const RecipeModel recipeModel = RecipeModel(
        category: '',
        cookingTime: '',
        description: '',
        id: '',
        image: Constants.noImageAvailable,
        ingredients: '',
        instructions: '',
        isRecipeLiked: false,
        isSideDish: false,
        name: '',
        preparationTime: '',
        searchKeywords: [],
        servingSize: '',
        type: '');

    return addRecipeDialog(recipeModel);
  }
}
