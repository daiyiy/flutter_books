import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_books/data/model/request/genuine_source_req.dart';
import 'package:flutter_books/data/model/response/book_chapters_resp.dart';
import 'package:flutter_books/data/model/response/book_content_resp.dart';
import 'package:flutter_books/data/model/response/book_genuine_source_resp.dart';
import 'package:flutter_books/data/repository/repository.dart';
import 'package:flutter_books/db/db_helper.dart';
import 'package:flutter_books/res/colors.dart';
import 'package:flutter_books/res/dimens.dart';
import 'package:flutter_books/widget/load_view.dart';
import 'package:fluttertoast/fluttertoast.dart';

///@author longshaohua
///小说内容浏览页

class BookContentPage extends StatefulWidget {
  String _bookUrl;
  String _bookId;
  String _bookImage;
  String _bookName;
  int _index = 0;
  bool _isReversed;

  BookContentPage(this._bookUrl, this._bookId, this._bookImage, this._index,
      this._isReversed, this._bookName);

  @override
  State<StatefulWidget> createState() {
    return BookContentPageState();
  }
}

class BookContentPageState extends State<BookContentPage>
    with OnLoadReloadListener {
  var _dbHelper = DbHelper();
  static final double _addBookshelfWidth = 95;
  static final double _bottomHeight = 200;

  LoadStatus _loadStatus = LoadStatus.LOADING;
  ScrollController _controller = new ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  String _content = "";
  double _height = 0;
  double _bottomPadding = _bottomHeight;
  double _imagePadding = 18;
  double _addBookshelfPadding = _addBookshelfWidth;
  int _duration = 200;
  double _spaceValue = 1.2;
  double _textSizeValue = 18;
  bool _isNighttime = false;
  bool _isAddBookshelf = false;
  List<BookChaptersBean> _listBean = [];
  String _title = "";
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      print(_controller.offset);
      _offset = _controller.offset;
    });
    getData();
    getChaptersData();
    setStemStyle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _isNighttime ? Colors.black : Colors.white,
      //侧滑菜单显示章节
      drawer: Drawer(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Container(
              height: MediaQuery.of(context).padding.top,
              color: Colors.black,
            ),
            Container(
              height: 50,
              color: MyColors.homeGrey,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    this.widget._isReversed = !this.widget._isReversed;
                    _listBean = _listBean.reversed.toList();
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "目录",
                      style: TextStyle(
                          fontSize: Dimens.titleTextSize,
                          color: MyColors.textPrimaryColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      width: 4,
                    ),
                    Image.asset(
                      "images/icon_chapters_turn.png",
                      width: 15,
                      height: 15,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _listBean.length,
                itemBuilder: (context, index) {
                  return itemView(index);
                },
                separatorBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(Dimens.leftMargin, 0, 0, 0),
                    child: Divider(height: 1, color: MyColors.dividerDarkColor),
                  );
                },
              ),
            )
          ],
        ),
      ),
      body: Stack(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              setState(() {
//                  _isSettingGone = !_isSettingGone;
                _bottomPadding == 0
                    ? _bottomPadding = _bottomHeight
                    : _bottomPadding = 0;
                _height == Dimens.titleHeight
                    ? _height = 0
                    : _height = Dimens.titleHeight;
                _imagePadding == 0 ? _imagePadding = 18 : _imagePadding = 0;
                _addBookshelfPadding == 0
                    ? _addBookshelfPadding = _addBookshelfWidth
                    : _addBookshelfPadding = 0;
              });
            },
            child: _loadStatus == LoadStatus.LOADING
                ? LoadingView()
                : _loadStatus == LoadStatus.FAILURE
                    ? FailureView(this)
                    : SingleChildScrollView(
                        controller: _controller,
                        reverse: false,
                        padding: EdgeInsets.fromLTRB(
                          Dimens.leftMargin,
                          16 + MediaQuery.of(context).padding.top,
                          Dimens.rightMargin,
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _title,
                              style: TextStyle(
                                fontSize: _textSizeValue + 2,
                                color: Color(0xFF9F8C54),
                              ),
                            ),
                            SizedBox(
                              height: 16,
                            ),
                            Text(
                              _content,
                              style: TextStyle(
                                color: _isNighttime
                                    ? MyColors.contentColor
                                    : MyColors.black,
                                fontSize: _textSizeValue,
                                letterSpacing: 1,
                                wordSpacing: 1,
                                height: _spaceValue,
                              ),
                            ),
                            SizedBox(
                              height: 16,
                            ),

                            /// 章节切换
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: <Widget>[
                                MaterialButton(
                                  minWidth: 125,
                                  textColor: MyColors.textPrimaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(125)),
                                    side: BorderSide(
                                        color: MyColors.textPrimaryColor,
                                        width: 1),
                                  ),
                                  onPressed: () {
                                    if (this.widget._isReversed) {
                                      if (this.widget._index >=
                                          _listBean.length - 1) {
                                        Fluttertoast.showToast(
                                            msg: "没有上一章了", fontSize: 14.0);
                                      } else {
                                        setState(() {
                                          _loadStatus = LoadStatus.LOADING;
                                          ++this.widget._index;
                                          this.widget._bookUrl =
                                              _listBean[this.widget._index]
                                                  .link;
                                          getData();
                                        });
                                      }
                                    } else {
                                      if (this.widget._index == 0) {
                                        Fluttertoast.showToast(
                                            msg: "没有上一章了", fontSize: 14.0);
                                      } else {
                                        setState(() {
                                          _loadStatus = LoadStatus.LOADING;
                                          --this.widget._index;
                                          this.widget._bookUrl =
                                              _listBean[this.widget._index]
                                                  .link;
                                          getData();
                                        });
                                      }
                                    }
                                  },
                                  child: Text("上一章"),
                                ),
                                MaterialButton(
                                  minWidth: 125,
                                  textColor: MyColors.textPrimaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(125)),
                                    side: BorderSide(
                                        color: MyColors.textPrimaryColor,
                                        width: 1),
                                  ),
                                  onPressed: () {
                                    if (!this.widget._isReversed) {
                                      if (this.widget._index >=
                                          _listBean.length - 1) {
                                        Fluttertoast.showToast(
                                            msg: "没有下一章了", fontSize: 14.0);
                                      } else {
                                        setState(() {
                                          _loadStatus = LoadStatus.LOADING;
                                          ++this.widget._index;
                                          this.widget._bookUrl =
                                              _listBean[this.widget._index]
                                                  .link;
                                          getData();
                                        });
                                      }
                                    } else {
                                      if (this.widget._index == 0) {
                                        Fluttertoast.showToast(
                                            msg: "没有下一章了", fontSize: 14.0);
                                      } else {
                                        setState(() {
                                          _loadStatus = LoadStatus.LOADING;
                                          --this.widget._index;
                                          this.widget._bookUrl =
                                              _listBean[this.widget._index]
                                                  .link;
                                          getData();
                                        });
                                      }
                                    }
                                  },
                                  child: Text("下一章"),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 16,
                            ),
                          ],
                        ),
                      ),
          ),
          settingView(),

          /// 加入书架
          Positioned(
            top: 78,
            right: 0,
            child: Container(
              width: _addBookshelfWidth,
              child: AnimatedPadding(
                padding: EdgeInsets.fromLTRB(_addBookshelfPadding, 30, 0, 0),
                duration: Duration(milliseconds: _duration),
                child: GestureDetector(
                  onTap: () {
                    addBookshelf();
                  },
                  child: Container(
                    width: _addBookshelfWidth,
                    padding: EdgeInsets.fromLTRB(10, 7, 0, 7),
                    decoration: BoxDecoration(
                      color: MyColors.contentBgColor,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(50),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Image.asset(
                          "images/icon_add_bookshelf.png",
                          height: 20,
                          width: 20,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          "加入书架",
                          style: TextStyle(
                            color: MyColors.contentColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          //状态栏颜色
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  //隐藏设置view
  void closeSettingView() {
    setState(() {
      _bottomPadding = _bottomHeight;
      _height = 0;
      _imagePadding = 18;
      _addBookshelfPadding = _addBookshelfWidth;
    });
  }

  Widget settingView() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: MediaQuery.of(context).padding.top,
        ),
        AnimatedContainer(
          height: _height,
          duration: Duration(milliseconds: _duration),
          child: Container(
            height: Dimens.titleHeight,
            color: MyColors.contentBgColor,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          Dimens.leftMargin, 0, Dimens.rightMargin, 0),
                      child: Image.asset(
                        'images/icon_title_back.png',
                        width: 20,
                        height: Dimens.titleHeight,
                        color: MyColors.contentColor,
                      ),
                    ),
                  ),
                ),
                Expanded(child: SizedBox()),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Image.asset(
                        'images/icon_bookshelf_more.png',
                        width: 3.0,
                        height: Dimens.titleHeight,
                        color: MyColors.contentColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: SizedBox()),
        Container(
          margin: EdgeInsets.fromLTRB(Dimens.leftMargin, 0, 0, 0),
          width: 36,
          height: 36,
          child: AnimatedPadding(
            duration: Duration(milliseconds: _duration),
            padding: EdgeInsets.fromLTRB(
                _imagePadding, _imagePadding, _imagePadding, _imagePadding),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isNighttime = !_isNighttime;
                });
              },
              child: Image.asset(
                _isNighttime
                    ? "images/icon_content_daytime.png"
                    : "images/icon_content_nighttime.png",
                height: 36,
                width: 36,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Container(
          height: _bottomHeight,
          child: AnimatedPadding(
            duration: Duration(milliseconds: _duration),
            padding: EdgeInsets.fromLTRB(0, _bottomPadding, 0, 0),
            child: Container(
              height: _bottomHeight,
              padding: EdgeInsets.fromLTRB(
                  Dimens.leftMargin, 20, Dimens.rightMargin, Dimens.leftMargin),
              color: MyColors.contentBgColor,
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "字号",
                        style: TextStyle(
                            color: MyColors.contentColor,
                            fontSize: Dimens.textSizeM),
                      ),
                      SizedBox(
                        width: 14,
                      ),
                      Image.asset(
                        "images/icon_content_font_small.png",
                        color: MyColors.white,
                        width: 28,
                        height: 18,
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            valueIndicatorColor: MyColors.textPrimaryColor,
                            inactiveTrackColor: MyColors.white,
                            activeTrackColor: MyColors.textPrimaryColor,
                            activeTickMarkColor: Colors.transparent,
                            trackHeight: 2.5,
                            thumbShape:
                                RoundSliderThumbShape(enabledThumbRadius: 8),
                          ),
                          child: Slider(
                            value: _textSizeValue,
                            label: "字号：$_textSizeValue",
                            divisions: 20,
                            min: 10,
                            max: 30,
                            onChanged: (double value) {
                              setState(() {
                                _textSizeValue = value;
                              });
                            },
                          ),
                        ),
                      ),
                      Image.asset(
                        "images/icon_content_font_big.png",
                        color: MyColors.white,
                        width: 28,
                        height: 18,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "间距",
                        style: TextStyle(
                            color: MyColors.contentColor,
                            fontSize: Dimens.textSizeM),
                      ),
                      SizedBox(
                        width: 14,
                      ),
                      Image.asset(
                        "images/icon_content_space_big.png",
                        color: MyColors.white,
                        width: 28,
                        height: 18,
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            valueIndicatorColor: MyColors.textPrimaryColor,
                            inactiveTrackColor: MyColors.white,
                            activeTrackColor: MyColors.textPrimaryColor,
                            activeTickMarkColor: Colors.transparent,
                            trackHeight: 2.5,
                            thumbShape:
                                RoundSliderThumbShape(enabledThumbRadius: 8),
                          ),
                          child: Slider(
                            value: _spaceValue,
                            label: "字间距：$_spaceValue",
                            min: 1.0,
                            divisions: 20,
                            max: 3.0,
                            onChanged: (double value) {
                              setState(() {
                                _spaceValue = value;
                              });
                            },
                          ),
                        ),
                      ),
                      Image.asset(
                        "images/icon_content_space_small.png",
                        color: MyColors.white,
                        width: 28,
                        height: 18,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 32,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          print("openDrawer");
                          closeSettingView();
                          _scaffoldKey.currentState.openDrawer();
                        },
                        child: Image.asset(
                          "images/icon_content_catalog.png",
                          height: 50,
                        ),
                      ),
                      Image.asset(
                        "images/icon_content_setting.png",
                        height: 50,
                      ),
                      Image.asset(
                        "images/icon_content_brightness.png",
                        height: 50,
                      ),
                      Image.asset(
                        "images/icon_content_read.png",
                        height: 50,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget itemView(int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            setState(() {
              _loadStatus = LoadStatus.LOADING;
              this.widget._index = index;
              this.widget._bookUrl = _listBean[index].link;
              getData();
            });
          });
          Navigator.pop(context);
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              Dimens.leftMargin, 16, Dimens.rightMargin, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(0, 4, 0, 0),
                child: Text(
                  "${index + 1}.  ",
                  style: TextStyle(fontSize: 9, color: MyColors.textBlack9),
                ),
              ),
              Expanded(
                child: Text(
                  _listBean[index].title,
                  style: TextStyle(
                    fontSize: Dimens.textSizeM,
                    color: this.widget._index == index
                        ? MyColors.textPrimaryColor
                        : MyColors.textBlack9,
                  ),
                ),
              ),
              _listBean[index].isVip
                  ? Image.asset(
                      "images/icon_chapters_vip.png",
                      width: 16,
                      height: 16,
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  showVipDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text("该章节为 Vip 章节，请联系作者"),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("确定"),
            )
          ],
        );
      },
    );
  }

  void addBookshelf() {
    var bookshelfBean = BookshelfBean(
      this.widget._bookName,
      this.widget._bookImage,
      (this.widget._index * 100 ~/ _listBean.length).toInt().toString(),
      this.widget._bookUrl,
      this.widget._bookId,
      _offset,
      this.widget._isReversed ? 1 : 0,
      this.widget._index,
    );
    _dbHelper.addBookshelfItem(bookshelfBean);
  }

  void getData() async {
    await Repository()
        .getBookChaptersContent(this.widget._bookUrl)
        .then((json) {
      BookContentResp bookContentResp = BookContentResp(json);
      setState(() {
        _loadStatus = LoadStatus.SUCCESS;

        ///部分小说文字排版有问题，需要特殊处理
        _content = bookContentResp.chapter.cpContent
            .replaceAll("\t", "\n")
            .replaceAll("\n\n\n\n", "\n\n");
        _title = bookContentResp.chapter.title;
        if (bookContentResp.chapter.isVip) {
          showVipDialog();
        }
      });
    }).catchError((e) {
      //请求出错
      setState(() {
        _loadStatus = LoadStatus.FAILURE;
        _title = "";
      });
    });
  }

  //获取章节内容
  void getChaptersData() async {
    GenuineSourceReq genuineSourceReq =
        GenuineSourceReq("summary", this.widget._bookId);
    var entryPoint =
        await Repository().getBookGenuineSource(genuineSourceReq.toJson());
    BookGenuineSourceResp bookGenuineSourceResp =
        BookGenuineSourceResp(entryPoint);
    if (bookGenuineSourceResp.data != null &&
        bookGenuineSourceResp.data.length > 0) {
      await Repository()
          .getBookChapters(bookGenuineSourceResp.data[0].id)
          .then((json) {
        BookChaptersResp bookChaptersResp = BookChaptersResp(json);
        setState(() {
          _listBean = bookChaptersResp.chapters;
          if (this.widget._isReversed) {
            _listBean = _listBean.reversed.toList();
          }
        });
      }).catchError((e) {
        //请求出错
        print(e.toString());
      });
    }
  }

  //设置状态文字颜色
  void setStemStyle() async {
    await Future.delayed(const Duration(milliseconds: 500),
        () => SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light));
  }

  @override
  void onReload() {
    _loadStatus = LoadStatus.LOADING;
    getData();
  }

  @override
  void dispose() {
    super.dispose();
    _dbHelper.close();
  }
}
