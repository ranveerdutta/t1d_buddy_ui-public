import 'dart:io';

import 'package:flutter/material.dart';
import 'package:t1d_buddy_ui/screens/google_sign_in.dart';
import 'package:t1d_buddy_ui/services/device_info_service.dart';
import 'package:t1d_buddy_ui/utils/authentication.dart';
import 'package:t1d_buddy_ui/utils/environment.dart';
import 'package:t1d_buddy_ui/utils/shared_preference_util.dart';

void main() async {
  const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: Environment.DEV,
  );

  //initialize environment
  Environment().initConfig(environment);

  //initialize shared pref
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefUtil.initSharedPref();

  HttpOverrides.global = new MyHttpOverrides();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'T1D-Buddy',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'T1D-Buddy'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".MyHomePage

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  void initState(){
    super.initState();
    DeviceInfoService.addDeviceInfoToSharedPref();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of screens.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is addUserToSharedPrefalso a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to the T1D-Buddy',
              style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.blue),
            ),
            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(height: 30.0),
                FutureBuilder(
                  future: Authentication.initializeFirebase(context: context),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error initializing Firebase');
                    } else if (snapshot.connectionState == ConnectionState.done) {
                      return GoogleSignInButton();
                    }
                    return CircularProgressIndicator(
                    );
                  },
                ),
              ],
            )
            ,
            SizedBox(height: 50),
            /*Text(
              'New user?',
              style: Theme.of(context).textTheme.headline6!.copyWith(color: Colors.blue),
            ),
            ElevatedButton(
              onPressed: (){
                Navigator.push(
                    context,
                    MaterialPageRoute(builder:(context) => Registration()));
              },
              child: Text('Register'),
            ),*/
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}
