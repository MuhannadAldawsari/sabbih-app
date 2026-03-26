import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/theme_controller/theme_controller.dart';
import 'package:sabbh/views/NavigableBottomSheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';


// ---------------- Home View ----------------

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

// ---------------- UI Page ----------------

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, bool>(
      builder: (context, isDarkMode) {
        return Scaffold(
          backgroundColor: isDarkMode 
              ? ColorsManager.primary 
              : ColorsManager.backgroundColor2,
          body: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  pinned: false,
                  elevation: 0,
                  backgroundColor: isDarkMode 
                      ? ColorsManager.primary 
                      : ColorsManager.backgroundColor2,
                  expandedHeight: 120,
                  actions: [
                    // Dark Mode Toggle Button
                    BlocBuilder<ThemeCubit, bool>(
                      builder: (context, isDarkMode) {
                        return IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              isDarkMode ? Icons.light_mode : Icons.dark_mode,
                              key: ValueKey(isDarkMode),
                              color: isDarkMode ? Colors.white : ColorsManager.black,
                            ),
                          ),
                          onPressed: () {
                            context.read<ThemeCubit>().toggleTheme();
                          },
                          tooltip: isDarkMode 
                              ? 'Switch to Light Mode' 
                              : 'Switch to Dark Mode',
                        );
                      },
                    ),
                  ],
                ),
              ];
            },
            body: SizedBox(height: 200,
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? ColorsManager.darkBackgroundColor 
                      : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  //physics: AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Your content goes here
                      textCard('الأذكار',25),
                      const SizedBox(height: 20),
                      // Add more widgets here
                       const customCard(),
                          const SizedBox(height: 30,),
                          textCard("المهام", 25),
                          const SizedBox(height: 25,),
                      TaskCard("أذكار الصباح", isDarkMode? ColorsManager.darkAppbarColor:ColorsManager.backgroundColor2, "5:00 AM"),
                          const SizedBox(height: 15,),
                      TaskCard("أذكار المساء", isDarkMode? ColorsManager.greenWithShade:ColorsManager.chipColor, "4:00 PM"),
                          const SizedBox(height: 15,),
                      TaskCard("أذكار النوم", isDarkMode? ColorsManager.primary:ColorsManager.appbarColor, "12:30 AM"),
                          const SizedBox(height: 500), // Temporary height for testing scroll
                      const Text("Bottom content"),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TaskCard extends StatefulWidget {
  final String text1;
  final Color backgroundColor;
  final String time;

  const TaskCard(this.text1, this.backgroundColor, this.time, {super.key});

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with WidgetsBindingObserver {
  bool isCompleted = false;
  DateTime? completedAt;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTaskState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkIfShouldReset();
    }
  }

  Future<void> _loadTaskState() async {
    final prefs = await SharedPreferences.getInstance();
    final keyPrefix = widget.text1; // unique key based on task text

    final completed = prefs.getBool('${keyPrefix}_completed') ?? false;
    final completedAtMillis = prefs.getInt('${keyPrefix}_completedAt');

    if (completed && completedAtMillis != null) {
      setState(() {
        isCompleted = completed;
        completedAt = DateTime.fromMillisecondsSinceEpoch(completedAtMillis);
      });
      _checkIfShouldReset();
    }
  }

  Future<void> _saveTaskState() async {
    final prefs = await SharedPreferences.getInstance();
    final keyPrefix = widget.text1;

    await prefs.setBool('${keyPrefix}_completed', isCompleted);
    if (completedAt != null) {
      await prefs.setInt('${keyPrefix}_completedAt', completedAt!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('${keyPrefix}_completedAt');
    }
  }

  void _checkIfShouldReset() {
    if (isCompleted && completedAt != null) {
      final now = DateTime.now();
      final difference = now.difference(completedAt!);

      if (difference.inHours >= 22) {
        setState(() {
          isCompleted = false;
          completedAt = null;
        });
        _saveTaskState();
        _resetTimer?.cancel();
      } else {
        final remainingTime = Duration(hours: 22) - difference;
        _resetTimer?.cancel();
        _resetTimer = Timer(remainingTime, () {
          if (mounted) {
            setState(() {
              isCompleted = false;
              completedAt = null;
            });
            _saveTaskState();
          }
        });
      }
    }
  }

  void _toggleCompletion() {
    setState(() {
      if (!isCompleted) {
        isCompleted = true;
        completedAt = DateTime.now();
        _resetTimer?.cancel();
        _resetTimer = Timer(Duration(hours: 22), () {
          if (mounted) {
            setState(() {
              isCompleted = false;
              completedAt = null;
            });
            _saveTaskState();
          }
        });
      } else {
        isCompleted = false;
        completedAt = null;
        _resetTimer?.cancel();
      }
    });
    _saveTaskState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.circle_outlined,
                key: ValueKey(isCompleted),
                color: isCompleted ? Colors.green : null,
                size: 28,
              ),
            ),
            onPressed: _toggleCompletion,
          ),
          Column(
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today),
                  SizedBox(width: 5),
                  Text("اليوم"),
                  SizedBox(width: 30),
                  Icon(Icons.timelapse),
                  SizedBox(width: 5),
                  Text(widget.time),
                ],
              ),
              Text(
                widget.text1,
                style: TextStyle(
                  fontSize: 20,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? Colors.grey : null,
                ),
              ),
            ],
          ),
          Icon(Icons.more_horiz),
        ],
      ),
    );
  }
}

class customCard extends StatelessWidget {
  const customCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, bool>(
      builder: (context, isDarkMode) {
    return Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            card("أذكار المساء",Icons.dark_mode_outlined,isDarkMode? ColorsManager.periwinkleBlueDark : ColorsManager.periwinkleBlue, isDarkMode),
            card("أذكار الصباح",Icons.light_mode_outlined,isDarkMode? ColorsManager.softYellowDark : ColorsManager.softYellow, isDarkMode)],),
          SizedBox(height: 30,),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            card("أذكار بعد الصلاة",Icons.spoke_outlined,isDarkMode? ColorsManager.mintGreenDark : ColorsManager.mintGreen, isDarkMode),
            card("أذكار النوم",Icons.night_shelter_outlined,isDarkMode? ColorsManager.pinkBlushDark : ColorsManager.pinkBlush, isDarkMode)],)
      ],);
      }
    );
  }
}

class card extends StatelessWidget {
  const card(this.text1, this.iconData, this.backgroundColor, this.isDarkMode);

  final String text1;
  final IconData iconData;
  final Color backgroundColor;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Center(
        child: GestureDetector(
          onTap: () {
            if(text1 == "أذكار المساء") {
            _showBottomSheetPopup(context, 1, isDarkMode);} 
            if(text1 == "أذكار الصباح") {
            _showBottomSheetPopup(context, 2, isDarkMode);} 
            if(text1 == "أذكار بعد الصلاة") {
            _showBottomSheetPopup(context, 3, isDarkMode);} 
            if(text1 == "أذكار النوم"){
              _showBottomSheetPopup(context, 4, isDarkMode);}
          },
          child: Container(
            width: 170,
            height: 120,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(15), 
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: EdgeInsets.all(20),
                child: Icon(iconData),),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(text1,style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
                ],)
                
              ],
            ),
          ),
        ),
      );
  }
  void _showBottomSheetPopup(BuildContext context, int number, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return NavigableBottomSheet(number, isDarkMode);
          },
        );
      },
    );
  }
}
