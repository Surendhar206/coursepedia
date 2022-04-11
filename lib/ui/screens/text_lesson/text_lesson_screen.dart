import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:masterstudy_app/data/utils.dart';
import 'package:masterstudy_app/theme/theme.dart';
import 'package:masterstudy_app/ui/bloc/text_lesson/bloc.dart';
import 'package:masterstudy_app/ui/screens/assignment/assignment_screen.dart';
import 'package:masterstudy_app/ui/screens/final/final_screen.dart';
import 'package:masterstudy_app/ui/screens/lesson_stream/lesson_stream_screen.dart';
import 'package:masterstudy_app/ui/screens/lesson_video/lesson_video_screen.dart';
import 'package:masterstudy_app/ui/screens/questions/questions_screen.dart';
import 'package:masterstudy_app/ui/screens/quiz_lesson/quiz_lesson_screen.dart';
import 'package:masterstudy_app/ui/screens/user_course_locked/user_course_locked_screen.dart';
import 'package:masterstudy_app/ui/widgets/warning_lessong_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../main.dart';

class TextLessonScreenArgs {
  final int lessonId;
  final int courseId;
  final String authorAva;
  final String authorName;
  final bool hasPreview;
  final bool trial;
  final dynamic itemsId;

  TextLessonScreenArgs(this.courseId, this.lessonId, this.authorAva, this.authorName, this.hasPreview, this.trial, {this.itemsId});
}

class TextLessonScreen extends StatelessWidget {
  static const routeName = "textLessonScreen";
  final TextLessonBloc bloc;

  const TextLessonScreen(this.bloc) : super();

  @override
  Widget build(BuildContext context) {
    TextLessonScreenArgs args = ModalRoute.of(context)?.settings.arguments as TextLessonScreenArgs;
    return BlocProvider<TextLessonBloc>(
        create: (context) => bloc,
        child: TextLessonWidget(
          args.courseId,
          args.lessonId,
          args.authorAva,
          args.authorName,
          args.hasPreview,
          args.trial,
          itemsId: args.itemsId,
        ));
  }
}

// ignore: must_be_immutable
class TextLessonWidget extends StatefulWidget {
  final int lessonId;
  final int courseId;
  final String authorAva;
  final String authorName;
  final bool hasPreview;
  final bool trial;
  final dynamic itemsId;

  const TextLessonWidget(this.courseId, this.lessonId, this.authorAva, this.authorName, this.hasPreview, this.trial, {this.itemsId}) : super();

  @override
  State<StatefulWidget> createState() => TextLessonWidgetState();
}

class TextLessonWidgetState extends State<TextLessonWidget> {
  late TextLessonBloc _bloc;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  bool completed = false;

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _bloc = BlocProvider.of<TextLessonBloc>(context)..add(FetchEvent(widget.courseId, widget.lessonId));
    ImageDownloader.callback(onProgressUpdate: (String? imageId, int progress) {
      setState(() {
        _progress = progress;
      });
    });
  }

  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      log(e.toString());
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener(
      bloc: _bloc,
      listener: (context, state) {
        if (state is CacheWarningLessonState) {
          showDialog(context: context, builder: (context) => WarningLessonDialog());
        }
      },
      child: BlocBuilder<TextLessonBloc, TextLessonState>(
        bloc: _bloc,
        builder: (BuildContext context, TextLessonState state) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: HexColor.fromHex("#273044"),
              title: _buildTitle(state),
            ),
            body: SingleChildScrollView(
              child: _buildBody(state),
            ),
            bottomNavigationBar: (!widget.trial) ? null : _buildBottomNavigation(state),
          );
        },
      ),
    );
  }

  _buildTitle(TextLessonState state) {
    if (state is InitialTextLessonState) return Center();

    if (state is LoadedTextLessonState) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  state.lessonResponse.section?.number,
                  textScaleFactor: 1.0,
                  style: TextStyle(fontSize: 14.0, color: Colors.white),
                ),
                Flexible(
                  child: Text(
                    state.lessonResponse.section?.label,
                    textScaleFactor: 1.0,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          (widget.hasPreview)
              ? Center()
              : SizedBox(
                  width: 40,
                  height: 40,
                  child: FlatButton(
                    shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(20.0), side: BorderSide(color: HexColor.fromHex("#3E4555"))),
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        QuestionsScreen.routeName,
                        arguments: QuestionsScreenArgs(widget.lessonId, 1),
                      );
                    },
                    padding: EdgeInsets.all(0.0),
                    color: HexColor.fromHex("#3E4555"),
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: SvgPicture.asset(
                          "assets/icons/question_icon.svg",
                          color: Colors.white,
                        )),
                  ),
                )
        ],
      );
    }
  }

  _buildBody(TextLessonState state) {
    if (state is InitialTextLessonState) return _buildLoading();

    if (state is LoadedTextLessonState) {
      return Column(
        children: [
          _buildWebView(state),
            _connectionStatus == ConnectivityResult.wifi || _connectionStatus == ConnectivityResult.mobile ?
            _buildLessonMaterials(state) : SizedBox(),
        ],
      );
    }
  }

  _buildLoading() => Center(
        child: CircularProgressIndicator(),
      );

  late WebViewController _webViewController;
  bool showLoadingWebview = true;

  _buildWebView(LoadedTextLessonState state) {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: WebView(
        javascriptMode: JavascriptMode.unrestricted,
        initialUrl: 'data:text/html;base64,${base64Encode(const Utf8Encoder().convert(state.lessonResponse.content))}',
        onPageFinished: (some) async {},
        onWebViewCreated: (controller) async {
          controller.clearCache();
          this._webViewController = controller;
        },
      ),
    );
  }

  var progress = '';
  int _progress = 0;
  bool isLoading = false;
  Map<String, dynamic>? progressMap = {};
  Widget? svgIcon;

  _buildLessonMaterials(LoadedTextLessonState state) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 25),
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Text 'Materials'
          state.lessonResponse.materials.isNotEmpty
              ? Text(
                  'Materials',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : const SizedBox(),

          //Materials
          ListView.builder(
            shrinkWrap: true,
            itemCount: state.lessonResponse.materials.length,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext ctx, int index) {
              var item = state.lessonResponse.materials[index];
              switch (item!.type) {
                case 'audio':
                  svgIcon = SvgPicture.asset('assets/icons/audio.svg');
                  break;
                case 'avi':
                  svgIcon = SvgPicture.asset('assets/icons/avi.svg');
                  break;
                case 'doc':
                  svgIcon = SvgPicture.asset('assets/icons/doc.svg');
                  break;
                case 'docx':
                  svgIcon = SvgPicture.asset('assets/icons/docx.svg');
                  break;
                case 'gif':
                  svgIcon = SvgPicture.asset('assets/icons/gif.svg');
                  break;
                case 'jpeg':
                  svgIcon = SvgPicture.asset('assets/icons/jpeg.svg');
                  break;
                case 'jpg':
                  svgIcon = SvgPicture.asset('assets/icons/jpg.svg');
                  break;
                case 'mov':
                  svgIcon = SvgPicture.asset('assets/icons/mov.svg');
                  break;
                case 'mp3':
                  svgIcon = SvgPicture.asset('assets/icons/mp3.svg');
                  break;
                case 'mp4':
                  svgIcon = SvgPicture.asset('assets/icons/mp4.svg');
                  break;
                case 'pdf':
                  svgIcon = SvgPicture.asset('assets/icons/pdf.svg');
                  break;
                case 'png':
                  svgIcon = SvgPicture.asset('assets/icons/png.svg');
                  break;
                case 'ppt':
                  svgIcon = SvgPicture.asset('assets/icons/ppt.svg');
                  break;
                case 'pptx':
                  svgIcon = SvgPicture.asset('assets/icons/pptx.svg');
                  break;
                case 'psd':
                  svgIcon = SvgPicture.asset('assets/icons/psd.svg');
                  break;
                case 'txt':
                  svgIcon = SvgPicture.asset('assets/icons/txt.svg');
                  break;
                case 'xls':
                  svgIcon = SvgPicture.asset('assets/icons/xls.svg');
                  break;
                case 'xlsx':
                  svgIcon = SvgPicture.asset('assets/icons/xlsx.svg');
                  break;
                case 'zip':
                  svgIcon = SvgPicture.asset('assets/icons/zip.svg');
                  break;
                default :
                  svgIcon = SvgPicture.asset('assets/icons/txt.svg');
              }
              return Container(
                margin: EdgeInsets.only(top: 20),
                padding: EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: mainColor,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 50,height: 30, child: svgIcon!),
                    const SizedBox(width: 10),
                    //Materials Label
                    Expanded(
                      child: Text(
                        '${item.label}.${item.type} (${item.size})',
                        style: TextStyle(
                          color: HexColor.fromHex("#FFFFFF"),
                        ),
                      ),
                    ),
                    item.url == progressMap!['itemUrl']
                        ? Text(
                            progress,
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          )
                        : const SizedBox(),
                    //Icon download
                    IconButton(
                      onPressed: () async {
                        String? dir;
                        if (Platform.isAndroid) {
                          dir = (await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS));
                        } else if (Platform.isIOS) {
                          dir = (await getApplicationDocumentsDirectory()).path;
                        }

                        var cyrillicSymbols = RegExp('[а-яёА-ЯЁ]');

                        bool isSymbols = cyrillicSymbols.hasMatch(item.url);

                        ///If file is jpeg/png/jpg
                        if (item.url.toString().contains('jpeg') || item.url.toString().contains('png') || item.url.toString().contains('jpg')) {
                          if (Platform.isIOS && isSymbols) {
                            AlertDialog alert = AlertDialog(
                              title: Text('Error image', textScaleFactor: 1.0, style: TextStyle(color: Colors.black, fontSize: 20.0)),
                              content: Text(
                                "Photo format error",
                                textScaleFactor: 1.0,
                              ),
                              actions: [
                                ElevatedButton(
                                  child: Text(
                                    'Ok',
                                    textScaleFactor: 1.0,
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.white,
                                  ),
                                )
                              ],
                            );

                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return alert;
                              },
                            );
                          } else {
                            var imageId = await ImageDownloader.downloadImage(item.url);

                            if (imageId == null) {
                              return print('Error');
                            }

                            //When image downloaded
                            final snackBar = SnackBar(
                              content: Text(
                                'Image downloaded',
                                textScaleFactor: 1.0,
                              ),
                              duration: const Duration(seconds: 1),
                            );

                            if (_progress == 100) {
                              WidgetsBinding.instance?.addPostFrameCallback((_) {
                                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                _progress = 0;
                              });
                            }
                          }
                        } else {
                          String fileName = item.url.substring(item.url.lastIndexOf("/") + 1);

                          String fullPath = dir! + '/$fileName';

                          setState(() {
                            isLoading = true;
                          });
                          Response response = await dio.get(
                            item.url,
                            onReceiveProgress: (received, total) {
                              setState(() {
                                progress = ((received / total * 100).toStringAsFixed(0) + '%');
                              });
                              progressMap!.addParam('itemUrl', item.url);
                              progressMap!.addParam('progress', progress);
                            },

                            //Received data with List<int>
                            options: Options(
                              responseType: ResponseType.bytes,
                              followRedirects: false,
                            ),
                          );

                          File file = File(fullPath);
                          // var raf = file.openSync(mode: FileMode.write);
                          // raf.writeFromSync(response.data);
                          // await raf.close();

                          if (mounted) {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }
                      },
                      icon: isLoading && item.url == progressMap!['itemUrl'] && progress == 0
                          ? CircularProgressIndicator()
                          : Icon(
                              item.url == progressMap!['itemUrl'] && progressMap!['progress'] == '${100}%' ? Icons.check : Icons.download,
                              color: Colors.white,
                            ),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }

  _buildBottomNavigation(TextLessonState state) {
    if (state is InitialTextLessonState) return Center(child: CircularProgressIndicator());

    if (state is LoadedTextLessonState) {
      return Container(
        decoration: BoxDecoration(color: HexColor.fromHex("#FFFFFF"), boxShadow: [BoxShadow(color: HexColor.fromHex("#000000").withOpacity(.1), offset: Offset(0, 0), blurRadius: 6, spreadRadius: 2)]),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              SizedBox(
                  width: 35,
                  height: 35,
                  child: (state.lessonResponse.prev_lesson != "")
                      ? FlatButton(
                          shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(20.0), side: BorderSide(color: mainColor!)),
                          onPressed: () {
                            switch (state.lessonResponse.prev_lesson_type) {
                              case "video":
                                Navigator.of(context).pushReplacementNamed(
                                  LessonVideoScreen.routeName,
                                  arguments:
                                      LessonVideoScreenArgs(widget.courseId, int.tryParse(state.lessonResponse.prev_lesson)!, widget.authorAva, widget.authorName, widget.hasPreview, widget.trial),
                                );
                                break;
                              case "quiz":
                                Navigator.of(context).pushReplacementNamed(
                                  QuizLessonScreen.routeName,
                                  arguments: QuizLessonScreenArgs(widget.courseId, int.tryParse(state.lessonResponse.prev_lesson)!, widget.authorAva, widget.authorName),
                                );
                                break;
                              case "assignment":
                                Navigator.of(context).pushReplacementNamed(
                                  AssignmentScreen.routeName,
                                  arguments: AssignmentScreenArgs(widget.courseId, int.tryParse(state.lessonResponse.prev_lesson)!, widget.authorAva, widget.authorName),
                                );
                                break;
                              case "stream":
                                Navigator.of(context).pushReplacementNamed(
                                  LessonStreamScreen.routeName,
                                  arguments: LessonStreamScreenArgs(widget.courseId, int.tryParse(state.lessonResponse.prev_lesson)!, widget.authorAva, widget.authorName),
                                );
                                break;
                              default:
                                Navigator.of(context).pushReplacementNamed(
                                  TextLessonScreen.routeName,
                                  arguments:
                                      TextLessonScreenArgs(widget.courseId, int.tryParse(state.lessonResponse.prev_lesson)!, widget.authorAva, widget.authorName, widget.hasPreview, widget.trial),
                                );
                            }
                          },
                          padding: EdgeInsets.all(0.0),
                          color: mainColor,
                          child: Icon(Icons.chevron_left),
                        )
                      : Center()),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: MaterialButton(
                      height: 50,
                      color: mainColor,
                      padding: EdgeInsets.all(0.0),
                      onPressed: () async {
                        var connectivityResult = await (Connectivity().checkConnectivity());

                        ///If user connect to mobile or wifi
                        if (connectivityResult == ConnectivityResult.wifi || connectivityResult == ConnectivityResult.mobile) {
                          if (state is LoadedTextLessonState && !state.lessonResponse.completed) {
                            _bloc.add(CompleteLessonEvent(widget.courseId, widget.lessonId));
                            setState(() {
                              completed = true;
                            });
                          }
                        } else {
                          if (preferences.getString('textLessonComplete') != null) {
                            var existRecord = jsonDecode(preferences.getString('textLessonComplete'));

                            for (var el in existRecord) {
                              if (el.toString().contains('added') && el['lesson_id'] == widget.lessonId) {
                                print('exist');
                              } else {
                                recordMap.add({
                                  'course_id': widget.courseId,
                                  'lesson_id': widget.lessonId,
                                  'added': 1,
                                });

                                preferences.setString('textLessonComplete', jsonEncode(recordMap));

                                setState(() {
                                  completed = true;
                                });
                              }
                            }
                          } else {
                            recordMap.add({
                              'course_id': widget.courseId,
                              'lesson_id': widget.lessonId,
                              'added': 1,
                            });

                            preferences.setString('textLessonComplete', jsonEncode(recordMap));
                            setState(() {
                              completed = true;
                            });
                          }
                        }
                      },
                      child: _buildButtonChild(state)),
                ),
              ),
              SizedBox(
                width: 35,
                height: 35,
                child: FlatButton(
                  shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(20.0), side: BorderSide(color: mainColor!)),
                  onPressed: () {
                    if (state.lessonResponse.next_lesson != "") {
                      if (state.lessonResponse.next_lesson_available) {
                        switch (state.lessonResponse.next_lesson_type) {
                          case "video":
                            Navigator.of(context).pushReplacementNamed(
                              LessonVideoScreen.routeName,
                              arguments: LessonVideoScreenArgs(widget.courseId, int.tryParse(state.lessonResponse.next_lesson)!, widget.authorAva, widget.authorName, widget.hasPreview, widget.trial),
                            );
                            break;
                          case "quiz":
                            Navigator.of(context).pushReplacementNamed(
                              QuizLessonScreen.routeName,
                              arguments: QuizLessonScreenArgs(widget.courseId, int.tryParse(state.lessonResponse.next_lesson)!, widget.authorAva, widget.authorName),
                            );
                            break;
                          case "assignment":
                            Navigator.of(context).pushReplacementNamed(
                              AssignmentScreen.routeName,
                              arguments: AssignmentScreenArgs(widget.courseId, int.tryParse(state.lessonResponse.next_lesson)!, widget.authorAva, widget.authorName),
                            );
                            break;
                          case "stream":
                            Navigator.of(context).pushReplacementNamed(
                              LessonStreamScreen.routeName,
                              arguments: LessonStreamScreenArgs(widget.courseId, int.tryParse(state.lessonResponse.next_lesson)!, widget.authorAva, widget.authorName),
                            );
                            break;
                          default:
                            Navigator.of(context).pushReplacementNamed(
                              TextLessonScreen.routeName,
                              arguments: TextLessonScreenArgs(widget.courseId, int.tryParse(state.lessonResponse.next_lesson)!, widget.authorAva, widget.authorName, widget.hasPreview, widget.trial),
                            );
                        }
                      } else {
                        Navigator.of(context).pushNamed(
                          UserCourseLockedScreen.routeName,
                          arguments: UserCourseLockedScreenArgs(widget.courseId),
                        );
                      }
                    } else {
                      var future = Navigator.of(context).pushNamed(
                        FinalScreen.routeName,
                        arguments: FinalScreenArgs(widget.courseId),
                      );
                      future.then((value) {
                        Navigator.pop(context);
                      });
                    }
                  },
                  padding: EdgeInsets.all(0.0),
                  color: mainColor,
                  child: Icon(Icons.chevron_right),
                ),
              )
            ],
          ),
        ),
      );
    }
  }

  _buildButtonChild(TextLessonState state) {
    Widget icon;

    if (state is InitialTextLessonState)
      return SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      );
    if (state is LoadedTextLessonState) {
      if (state.lessonResponse.completed || completed) {
        icon = Icon(Icons.check_circle);
      } else {
        icon = Icon(Icons.panorama_fish_eye);
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          icon,
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              localizations!.getLocalization("complete_lesson_button"),
              textScaleFactor: 1.0,
            ),
          )
        ],
      );
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
