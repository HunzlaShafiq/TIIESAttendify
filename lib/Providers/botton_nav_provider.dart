import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tiies_attendance_app/screens/Home/HomePage.dart';
import 'package:tiies_attendance_app/screens/Home/checkOutScreen.dart';
import 'package:tiies_attendance_app/screens/MyRequest/my_request.dart';
import 'package:tiies_attendance_app/screens/Profile/profile.dart';
import 'package:tiies_attendance_app/screens/TakeBreak/active_break_screen.dart';
import 'package:tiies_attendance_app/screens/TakeBreak/take_break.dart';
import 'package:tiies_attendance_app/screens/team/team_screen.dart';

class BottomNavProvider with ChangeNotifier{

  int _index = 0;
  int get index => _index;


   List<Widget> _pages = [
    Homepage(),
    MyRequest(),
    TeamScreen(),
    TakeBreak(),
    Profile()
  ];

  List<Widget> get pages => _pages;


  void updateIndex(int newIndex){
    _index = newIndex;
    notifyListeners();

  }

  void pageCheckIn(){
    _pages[0]=CheckOutScreen();
    notifyListeners();

  }
  void pageCheckOut(){
    _pages[0]=Homepage();
    notifyListeners();

  }

  void yesOnBreak(breakData){
    _pages[3]=ActiveBreakScreen(breakData: breakData);
    notifyListeners();

  }
  void noOnBreak(){
    _pages[3]=TakeBreak();
    notifyListeners();

  }






}