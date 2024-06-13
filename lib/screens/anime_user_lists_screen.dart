import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unyo/models/models.dart';
import 'package:unyo/widgets/widgets.dart';
import 'package:unyo/screens/screens.dart';
import 'package:unyo/api/anilist_api_anime.dart';

class AnimeUserListsScreen extends StatefulWidget {
  const AnimeUserListsScreen({super.key});

  @override
  State<AnimeUserListsScreen> createState() => _AnimeUserListsScreenState();
}

class _AnimeUserListsScreenState extends State<AnimeUserListsScreen>
    with TickerProviderStateMixin {
  Map<String, List<AnimeModel>> userAnimeLists = {};
  String? userName;
  int? userId;
  final double minimumWidth = 124.08;
  final double minimumHeight = 195.44;
  double maximumWidth = 0;
  double maximumHeight = 0;

  @override
  void initState() {
    super.initState();
    setSharedPreferences();
    // initUserAnimeListsMap();
    //TODO find this value with totalHeight and totalWidth in the future
    maximumWidth = minimumWidth * 1.4;
    maximumHeight = minimumHeight * 1.4;
  }

  //horizontalPadding must be given as half of its real value as to avoid multiple divisions
  List<Widget> generateAnimeWidgetRows(
      double totalWidth,
      double horizontalPadding,
      String title,
      double calculatedWidth,
      double calculatedHeight,
      List<AnimeModel> animeList) {
    List<Widget> rowsList = [];
    int rowWidgetNum = totalWidth ~/
            (min(max(calculatedWidth, minimumWidth), maximumWidth) +
                2 * horizontalPadding) -
        1;
    for (int i = 0; i < animeList.length; i++) {
      int actualIndex = i * rowWidgetNum;
      //NOTE there is at least x more elements
      if (actualIndex < animeList.length - rowWidgetNum - 1) {
        rowsList.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: getAnimeRowWidgets(actualIndex, rowWidgetNum, title,
              animeList, calculatedWidth, calculatedHeight, horizontalPadding),
        ));
      } else {
        rowsList.add(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: getAnimeRowWidgets(
              actualIndex,
              animeList.length - actualIndex,
              title,
              animeList,
              calculatedWidth,
              calculatedHeight,
              horizontalPadding),
        ));
        break;
      }
    }
    return rowsList;
  }

  List<Widget> getAnimeRowWidgets(
      int currentIndex,
      int rowWidgetNum,
      String title,
      List<AnimeModel> animeList,
      double calculatedWidth,
      double calculatedHeight,
      double padding) {
    List<Widget> rowWidgets = [];
    //NOTE goes ahead and adds those x elements to the row
    for (int j = currentIndex; j < currentIndex + rowWidgetNum; j++) {
      rowWidgets.add(Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Hero(
          tag: "${"user-anime-list-$title-view"}-$j",
          child: AnimeWidget(
            title: animeList[j].title,
            score: animeList[j].averageScore,
            coverImage: animeList[j].coverImage,
            onTap: () {
              openAnime(
                animeList[j],
                "${"user-anime-list-$title-view"}-$j",
              );
            },
            textColor: Colors.white,
            height: min(max(calculatedHeight, minimumHeight), maximumHeight),
            width: min(max(calculatedWidth, minimumWidth), maximumWidth),
            year: animeList[j].startDate,
            format: animeList[j].format,
            status: animeList[j].status,
          ),
        ),
      ));
    }
    return rowWidgets;
  }

  double getAdjustedHeight(double value) {
    if (MediaQuery.of(context).size.aspectRatio > 1.77777777778) {
      return value;
    } else {
      return value *
          ((MediaQuery.of(context).size.aspectRatio) / (1.77777777778));
    }
  }

  double getAdjustedWidth(double value) {
    if (MediaQuery.of(context).size.aspectRatio < 1.77777777778) {
      return value;
    } else {
      return value *
          ((1.77777777778) / (MediaQuery.of(context).size.aspectRatio));
    }
  }

  void openAnime(AnimeModel currentAnime, String tag) {
    var animeScreen = AnimeDetailsScreen(
      currentAnime: currentAnime,
      tag: tag,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => animeScreen),
    );
  }

  void initUserAnimeListsMap() async {
    var newUserAnimeLists = await getAllUserAnimeLists(userId!, 0);
    setState(() {
      userAnimeLists = newUserAnimeLists;
    });
  }

  void setSharedPreferences() async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getString("accessToken") == null) {
      // _startServer();
      // goToLogin();
      return;
    } else {
      // accessToken = prefs.getString("accessToken");
      userName = prefs.getString("userName");
      userId = prefs.getInt("userId");
      initUserAnimeListsMap();
    }
  }

  @override
  Widget build(BuildContext context) {
    //TODO must calculate both adjustedHeight and adjustedWidth in the future so it doesn't depend on 16/9 aspect ratio

    TabController tabContrller =
        TabController(length: userAnimeLists.entries.length, vsync: this);
    //sizes calculations
    double totalWidth = MediaQuery.of(context).size.width;
    double totalHeight = MediaQuery.of(context).size.height;
    double adjustedWidth = getAdjustedWidth(totalWidth);
    double adjustedHeight = getAdjustedHeight(totalHeight);
    double calculatedWidth = adjustedWidth * 0.1;
    double calculatedHeight = adjustedHeight * 0.28;

    return Material(
      color: const Color.fromARGB(255, 37, 37, 37),
      child: Column(
        children: [
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  onPressed: () {
                    goTo(1);
                  },
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "${userName ?? ""} Anime List",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              isScrollable: true,
              controller: tabContrller,
              tabs: [
                ...userAnimeLists.entries.map((entry) {
                  String title = entry.key;
                  return SizedBox(
                    width: 150,
                    child: Tab(
                      text: title,
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(
            width: totalWidth,
            height: totalHeight - 100,
            child: TabBarView(
              controller: tabContrller,
              children: [
                //TODO temp, must use wrap in the future
                ...userAnimeLists.entries.map(
                  (entry) {
                    String title = entry.key;
                    List<AnimeModel> animeList = entry.value;
                    List<Widget> rowsList = generateAnimeWidgetRows(totalWidth,
                        2, title, calculatedWidth, calculatedHeight, animeList);
                    return SizedBox(
                      width: totalWidth,
                      height: double.infinity,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          // child: Wrap(
                          //   runSpacing: -(totalWidth * 0.1),
                          //   alignment: WrapAlignment.center,
                          //   children: [
                          //     ...animeList.mapIndexed(
                          //       (index, mediaModel) {
                          //         return Hero(
                          //           tag:
                          //               "${"user-anime-list-$title-view"}-$index",
                          //           child: AnimeWidget(
                          //             title: mediaModel.title,
                          //             score: mediaModel.averageScore,
                          //             coverImage: mediaModel.coverImage,
                          //             onTap: () {
                          //               openAnime(
                          //                 mediaModel,
                          //                 "${"user-anime-list-$title-view"}-$index",
                          //               );
                          //             },
                          //             textColor: Colors.white,
                          //             height: min(
                          //                 max(calculatedHeight, minimumHeight),
                          //                 maximumHeight),
                          //             width: min(
                          //                 max(calculatedWidth, minimumWidth),
                          //                 maximumWidth),
                          //             year: mediaModel.startDate,
                          //             format: mediaModel.format,
                          //             status: mediaModel.status,
                          //           ),
                          //         );
                          //       },
                          //     ),
                          //   ],
                          // ),
                          child: SizedBox(
                            width: totalWidth,
                            height: totalHeight,
                            child: Center(
                              child: ListView.builder(
                                itemCount: rowsList.length,
                                itemBuilder: (context, index) {
                                  return rowsList[index];
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}