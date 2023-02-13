import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:app_feedback/app_feedback.dart';
import 'package:bulleted_list/bulleted_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent-tab-view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yummealprep/screens/meals/widgets/add_meal_item_widget.dart';
import 'package:yummealprep/screens/recipes/widgets/add_recipe_widget.dart';
import 'package:yummealprep/screens/uploadDataToDB/upload_data_screen.dart';
import 'package:yummealprep/utils/constants.dart';
import 'package:yummealprep/shared_widgets/choices.dart' as choices;

class UIHelper {
  static AppFeedback feedbackForm = AppFeedback.instance;
  static const double _verticalSpaceExtraSmall = 4.0;
  static const double _verticalSpaceMedium = 16.0;
  static const double _verticalSpaceSmall = 8.0;
  static const double _horizontalSpaceMedium = 16.0;
  static const double _horizontalSpaceSmall = 8.0;
  static SizedBox verticalSpace(double height) => SizedBox(height: height);

  static SizedBox horizontalSpace(double width) => SizedBox(width: width);
  static SizedBox verticalSpaceExtraSmall() =>
      verticalSpace(_verticalSpaceExtraSmall);
  static SizedBox verticalSpaceSmall() => verticalSpace(_verticalSpaceSmall);
  static SizedBox verticalSpaceMedium() => verticalSpace(_verticalSpaceMedium);
  static SizedBox horizontalSpaceMedium() =>
      horizontalSpace(_horizontalSpaceMedium);
  static SizedBox horizontalSpaceSmall() =>
      horizontalSpace(_horizontalSpaceSmall);

  static SizedBox openDrawer(context) {
    Future<void> launchURL(url,
        {LaunchMode mode = LaunchMode.inAppWebView}) async {
      if (!await launchUrl(url, mode: mode)) {
        throw 'Could not launch $url';
      }
    }

    String? encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map((MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }

    return SizedBox(
      width: MediaQuery.of(context!).size.width * 0.5, //<-- SEE HERE
      child: Drawer(
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.deepOrange[400]),
              accountName:  Text(
                dotenv.env['COMPANYNAMEALIAS']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail:  Text(
                dotenv.env['COMPANYEMAILADDRESS']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                  radius: 30.0, backgroundImage: AssetImage(Constants.appLogo)),
            ),
            ListTile(
              leading: const Icon(
                Icons.brush,
              ),
              title: const Text('Change theme'),
              onTap: () {
                AdaptiveTheme.of(context).toggleThemeMode();
              },
            ),
            ListTile(
                title: const Text('Add meal'),
                leading: const Icon(Icons.add_reaction),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return const AddMealItem();
                      });
                }),
            ListTile(
                title: const Text('Add recipe'),
                leading: const Icon(Icons.add_box_rounded),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return const AddRecipe();
                      });
                }),
            ListTile(
                title: const Text('Upload Items'),
                leading: const Icon(Icons.upload),
                onTap: () {
                  pushNewScreen(
                    context,
                    screen: const DBDataUploadScreen(),
                    withNavBar: true,
                    pageTransitionAnimation: PageTransitionAnimation.cupertino,
                  );
                }),
            const Divider(
              color: Colors.black,
            ),
            ListTile(
                title: const Text('${Constants.appName} web app'),
                leading: const Icon(Icons.language),
                onTap: () {
                  launchURL(Uri.parse(dotenv.env['COMPANYWEBSITE']!));
                }),
            AboutListTile(
              dense: true,
              icon: const Icon(
                Icons.info,
              ),
              applicationIcon: const CircleAvatar(
                  radius: 30.0, backgroundImage: AssetImage(Constants.appLogo)),
              applicationName: Constants.appName,
              applicationVersion: Constants.appVersion,
              applicationLegalese: '© 2022 ${dotenv.env['COMPANYNAME']!}',
              aboutBoxChildren: [
                ///Content goes here...
                const SizedBox(height: 10),
                const Text(
                    '${Constants.appName} is a food planning application as well as a digital recipe and meal cook book.\n'),
                const Text('Features',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline)),
                BulletedList(
                  style: const TextStyle(fontSize: 15),
                  listItems: choices.appFeatures,
                  bulletType: BulletType.numbered,
                ),
                ListTile(
                  title: const Text('Terms of Service'),
                  leading: const Icon(Icons.description),
                  onTap: () {
                    launchURL(Uri.parse(dotenv.env['TERMSANDCONDITIONS']!));
                  },
                ),
                ListTile(
                  title: const Text('Privacy Policy'),
                  leading: const Icon(Icons.privacy_tip),
                  onTap: () {
                    launchURL(Uri.parse(dotenv.env['PRIVACYPOLICY']!));
                  },
                ),
                ListTile(
                  title: const Text('GitHub Repository'),
                  leading: const Icon(Icons.language),
                  onTap: () {
                    launchURL(Uri.parse(dotenv.env['GITHUBAPPREPOSITORY']!),
                        mode: LaunchMode.externalApplication);
                  },
                ),
              ],
              child: const Text('About'),
            ),
            ListTile(
                title: const Text('Give app feedback'),
                leading: const Icon(Icons.feedback),
                onTap: () {
                  feedbackForm.display(context,
                      option: Option(
                        maxRating: 10,
                        ratingButtonTheme: RatingButtonThemeData.circular,
                      ), onSubmit: (feedback) {
                    final Uri emailLaunchURI = Uri(
                      scheme: 'mailto',
                      path: dotenv.env['COMPANYEMAILADDRESS']!,
                      query: encodeQueryParameters(<String, String>{
                        'subject': 'YumMealPrep Feedback',
                        'body':
                            'Dear ASPTech. Inc.,\n\n$feedback\n\nKind regards,\nYumMealPrep App User'
                      }),
                    );
                    launchURL(emailLaunchURI);
                  });
                }),
          ],
        ),
      ),
    );
  }
}
