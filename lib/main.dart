import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pipemantra/state_injector.dart';
import 'SplashScreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: StateInjector.blocProviders,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Pipemantra",
        theme: ThemeData(
          visualDensity: VisualDensity.adaptivePlatformDensity,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          scaffoldBackgroundColor: Color(0xff001B36),
          // dialogBackgroundColor is set via dialogTheme below
          cardColor: Colors.white,
          searchBarTheme: const SearchBarThemeData(),
          tabBarTheme: const TabBarThemeData(),
          dialogTheme: const DialogThemeData(
            shadowColor: Colors.white,
            surfaceTintColor: Colors.white,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0)),
            ),
          ),
          buttonTheme: const ButtonThemeData(),
          popupMenuTheme: const PopupMenuThemeData(
            color: Colors.white,
            shadowColor: Colors.white,
          ),
          appBarTheme: const AppBarTheme(surfaceTintColor: Colors.white),
          cardTheme: const CardThemeData(
            shadowColor: Colors.white,
            surfaceTintColor: Colors.white,
            color: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
              // overlayColor: MaterialStateProperty.all(Colors.white),
            ),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            surfaceTintColor: Colors.white,
            backgroundColor: Colors.white,
          ),
          colorScheme: const ColorScheme.light(
            surface: Colors.white,
          ),
        ),
        home: Splash(),
      ),
    );
  }
}
