import 'package:carousel_slider/carousel_slider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:medico/blocs/home_bloc.dart';
import 'package:medico/models/doctors.dart';
import 'package:medico/pages/conversations.dart' as prefix0;
import 'package:medico/pages/diagnostic_page.dart';
import 'package:medico/pages/doctors.dart';
import 'package:medico/pages/health_assist_page.dart';
import 'package:medico/pages/medicines.dart';
import 'package:medico/services/api_client.dart';
import 'package:medico/services/auth.dart';
import 'package:medico/services/doctor_use_case.dart';
import 'package:medico/util/server_model.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'account.dart';
import 'package:location/location.dart';
import '../services/location_helper.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();

  final HomeBloc bloc;
  final User user;
  final DoctorUseCase doctorUseCase;
  static Widget create(
    BuildContext context,
    User user,
  ) {
    final useCase = DoctorUseCase(Provider.of<ApiClient>(context));
    return Provider(
      create: (_) => HomeBloc(DoctorUseCase(Provider.of<ApiClient>(context))),
      dispose: (_, bloc) => bloc.dispose(),
      child: Consumer<HomeBloc>(
        builder: (context, bloc, _) => Home(
          bloc: bloc,
          user: user,
          doctorUseCase: useCase,
        ),
      ),
    );
  }

  Home({Key key, this.bloc, this.user, this.doctorUseCase}) : super(key: key);
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {

  Future<String> _getCurrentUserLocation() async {
    final locData = await Location().getLocation();
    final address = await LocationHelper.getPlaceAddress(locData.latitude, locData.longitude);
    return address;
  }
  Future<String> addr = _getCurrentUserLocation();
  HomeBloc bloc;
  User user;

  AnimationController _controller;
  int _page = 0;

  Widget _currentPage(int page) {
    switch (page) {
      case 0:
        return homeWidget();
      case 1:
        return prefix0.Conversation();
      case 2:
        return AccountWidget.create(context, user);
      default:
        return homeWidget();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    bloc = this.widget.bloc;
    user = this.widget.user;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bloc.getDoctorsList();
    return Scaffold(
      body: _currentPage(_page),
      bottomNavigationBar: CurvedNavigationBar(
        initialIndex: 0,
        items: <Widget>[
          Icon(
            Icons.home,
            size: 25,
            color: Theme.of(context).primaryColor,
          ),
          Icon(
            Icons.chat,
            size: 25,
            color: Theme.of(context).primaryColor,
          ),
          Icon(
            Icons.perm_identity,
            size: 25,
            color: Theme.of(context).primaryColor,
          ),
        ],
        color: Theme.of(context).accentColor,
        buttonBackgroundColor: Theme.of(context).accentColor,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: Duration(milliseconds: 600),
        onTap: (index) {
          setState(() {
            _page = index;
            _currentPage(_page);
          });
        },
      ),
    );
  }

  StreamBuilder homeWidget() {
    return StreamBuilder<ServerModel<List<Doctor>>>(
      stream: bloc.doctorStream,
      initialData: null,
      builder: (context, snapshot) {
        if (snapshot.data == null)
          return Center(child: CircularProgressIndicator());
        final doctorsList = snapshot.data.data;
        final error = snapshot.data.getException;
        return error == null
            ? SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        Container(
                          height: 120,
                          padding:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(25.0),
                                bottomRight: Radius.circular(25.0)),
                            color: Theme.of(context).accentColor,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    'Plan My Health',
                                    style: TextStyle(
                                      fontSize: 22.0,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.8),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Hi ${user.name}',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 16.0,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                      Text(addr.toString())
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 80.0),
                          padding:
                              const EdgeInsets.only(left: 20.0, right: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              topHeading(
                                imageAsset: 'images/nurse.png',
                                title: 'Doctors',
                                subtitle: 'Search Doctors',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DoctorsList.create(
                                          doctorsList,
                                          user,
                                          this.widget.doctorUseCase),
                                    ),
                                  );
                                },
                              ),
                              topHeading(
                                imageAsset: 'images/pill.png',
                                title: 'Medicines',
                                subtitle: 'Order medicine',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          Medicines.create(context, user),
                                    ),
                                  );
                                },
                              ),
                              topHeading(
                                imageAsset: 'images/microscope.png',
                                title: 'Diagnostic',
                                subtitle: 'Book test',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BookTestsOnline.create(context, user),
                                    ),
                                  );
                                },
                              ),
                              topHeading(
                                imageAsset: 'images/microscope.png',
                                title: 'Assist',
                                subtitle: 'Health Assist',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          HealthAssistPage.create(
                                        context,
                                        user,
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
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                      child: CarouselSlider(
                        items: <Widget>[
                          Container(
                            height: 200.0,
                            margin: const EdgeInsets.only(left: 12.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  width: 1.0,
                                  color: Colors.grey.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(16.0),
                              image: DecorationImage(
                                image: AssetImage('images/carousel-1.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            height: 200.0,
                            margin: const EdgeInsets.only(left: 12.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  width: 1.0,
                                  color: Colors.grey.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(16.0),
                              image: DecorationImage(
                                image: AssetImage(
                                  'images/carousel-1.jpg',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            height: 200.0,
                            margin: const EdgeInsets.only(left: 12.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  width: 1.0,
                                  color: Colors.grey.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(16.0),
                              image: DecorationImage(
                                image: AssetImage(
                                  'images/carousel-1.jpg',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          FlatButton(
                            onPressed: () {},
                            child: Text(
                              'Doctors nearly  you ',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).focusColor),
                            ),
                          ),
                          FlatButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DoctorsList.create(
                                      doctorsList,
                                      user,
                                      this.widget.doctorUseCase),
                                ),
                              );
                            },
                            child: Text(
                              'See All',
                              style: TextStyle(
                                fontSize: 12.0,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).accentColor,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      height: 180.0,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: <Widget>[
                          card("images/doctor-1.jpg", doctorsList[0].name,
                              doctorsList[0].qualification, "4.2", context),
                          card("images/doctor-2.jpg", doctorsList[1].name,
                              doctorsList[1].qualification, "3.6", context),
                          card("images/doctor-5.jpg", doctorsList[2].name,
                              doctorsList[2].qualification, "4.3", context),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Center(child: Text(error.getErrorMessage()));
      },
    );
  }

  Column topHeading({
    @required String imageAsset,
    @required String title,
    @required String subtitle,
    @required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        FlatButton(
          padding: EdgeInsets.all(0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(150)),
          onPressed: onPressed,
          child: ball(imageAsset, Theme.of(context).scaffoldBackgroundColor),
        ),
        Column(
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontSize: 12.0,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Theme.of(context).focusColor,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.0,
                fontFamily: 'Poppins',
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget ball(String image, Color color) {
    return Container(
      height: 80,
      width: 80.0,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100.0),
      ),
      child: Center(
        child: Image(
          image: AssetImage(image),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget ballcard(String image, Color color) {
    return Container(
      height: 60,
      width: 60.0,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100.0),
        image: DecorationImage(
          image: AssetImage(image),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget card(String image, String title, String subTitle, String rank,
      BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 30.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  offset: Offset(0, 4),
                  blurRadius: 10)
            ],
          ),
          width: 140.0,
          height: 140.0,
          child: Card(
            elevation: 0.2,
            child: Wrap(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 0.0, vertical: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 10.0),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.star,
                            color: Colors.yellow,
                          ),
                          Text(
                            rank,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 40.0, vertical: 0.0),
          child: ballcard(image, Colors.transparent),
        ),
      ],
    );
  }
}
