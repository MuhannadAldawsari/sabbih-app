import 'package:flutter/material.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/core/resources/strings.dart';

class NavigableBottomSheet extends StatefulWidget {
  final int number;
  final bool isDarkMode;
  const NavigableBottomSheet(this.number, this.isDarkMode, {super.key});
  @override
  // ignore: library_private_types_in_public_api, no_logic_in_create_state
  _NavigableBottomSheetState createState() => _NavigableBottomSheetState(number, isDarkMode);
}

class _NavigableBottomSheetState extends State<NavigableBottomSheet> 
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  int number;
  final bool isDarkMode;
  int currentCounter = 0; // Added counter variable
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  List dkr = almsaa;
  List fadhel = fadhelAlmsaa;
  List fadhelShort = fadhelAlmsaaShort;
  List dkrCounter = almsaaCounter;
  
  _NavigableBottomSheetState(this.number, this.isDarkMode){
  
  if(number == 2){
    dkr = alsabah;
    fadhel = fadhelAlsabah;
    fadhelShort = fadhelAlsabahShort;
    dkrCounter = alsabahCounter;
  }
  if(number == 3){
    dkr = alsalah;
    fadhel = fadheAlsalah;
    fadhelShort = fadhelAlsalahShort;
    dkrCounter = alsalahCounter;
  }
  if(number == 4){
    dkr = alnoum;
    fadhel = fadhelalnoum;
    fadhelShort = fadhelAlnoumShort;
    dkrCounter = alnoumCounter;
  }
  }

  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
     _scrollController = ScrollController();

    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
      _animationController.dispose();
      _scrollController.dispose();
      super.dispose();
    }

  void _animatePageTransition({bool isNext = true}) {
    // Set animation direction
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(isNext ? -0.3 : 0.3, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward().then((_) {
      // Reset animation for fade in
      _slideAnimation = Tween<Offset>(
        begin: Offset(isNext ? 0.3 : -0.3, 0),
        end: Offset(0, 0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      
      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));

      _animationController.reset();
      _animationController.forward();
    });
  }
  
  
  void goToPrevious() {
  if (currentIndex > 0) {
    _animatePageTransition(isNext: false);
    setState(() {
      currentIndex--;
      currentCounter = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(0);
    });
  }
}

  void goToNext() {
  if (currentIndex < dkr.length - 1) {
    _animatePageTransition(isNext: true);
    setState(() {
      currentIndex++;
      currentCounter = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(0);
    });
  }
}

  void incrementCounter() {
  setState(() {
    currentCounter++;
    if (currentCounter >= dkrCounter[currentIndex]) {
      if (currentIndex < dkr.length - 1) {
        _animatePageTransition(isNext: true);
        currentIndex++;
        currentCounter = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(0);
        });
      } else {
        if (currentCounter >= dkrCounter[currentIndex]) {
          currentCounter = dkrCounter[currentIndex];
        }
      }
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: BoxDecoration(
            color: isDarkMode ? ColorsManager.darkCard : ColorsManager.lightCard,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              // Header with navigation
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Arrow Button
                    IconButton(
                      onPressed: currentIndex > 0 ? goToPrevious : null,
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: currentIndex > 0 ? (isDarkMode ? ColorsManager.darkAccent : ColorsManager.lightAccent) : ColorsManager.grey,
                      ),
                      iconSize: 30,
                    ),
                    
                    // Page Indicator
                    Text(
                      '${currentIndex + 1} / ${dkr.length}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    // Right Arrow Button
                    IconButton(
                      onPressed: currentIndex < dkr.length - 1 ? goToNext : null,
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: currentIndex < dkr.length - 1 ? (isDarkMode ? ColorsManager.darkAccent : ColorsManager.lightAccent) : ColorsManager.grey,
                      ),
                      iconSize: 30,
                    ),
                  ],
                ),
              ),
              
              // Scrollable Content Area
              Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < 0) {
                      // Swipe Left → Next
                      goToNext();
                    } else if (details.primaryVelocity! > 0) {
                      // Swipe Right → Previous
                      goToPrevious();
                    }
                  }
                },
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              SizedBox(height: 20),
                              dkrCard(dkr, currentIndex, isDarkMode),
                              SizedBox(height: 30),
                              textCard('الفضل',0),
                              SizedBox(height: 10),
                              dkrCard(fadhelShort, currentIndex, isDarkMode),
                              SizedBox(height: 30),
                              textCard('الدليل',0),
                              SizedBox(height: 10),
                              dkrCard(fadhel, currentIndex, isDarkMode),
                              SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
              
              // Counter Button
              GestureDetector(
                onTap: () {
                  incrementCounter();
                },
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: incrementCounter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? ColorsManager.darkAccent : ColorsManager.lightAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 80, vertical: 10),
                    ),
                    child: Text(
                      '$currentCounter / ${dkrCounter[currentIndex]}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Small X close button in bottom left corner
        Positioned(
          bottom: 20,
          left: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
              iconSize: 35,
            ),
          ),
        ),
      ],
    );
  }
}

Container dkrCard(List dkr, int currentIndex, bool isDarkMode){
  return Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: isDarkMode ? ColorsManager.darkCardAlt : ColorsManager.lightCardAlt,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(
      color: isDarkMode ? ColorsManager.darkDivider : ColorsManager.lightDivider,
    ),
  ),
  child: Text(
    dkr[currentIndex],
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.start,
    style: TextStyle(
      fontSize: 16,
      height: 1.6,
      color: isDarkMode ? ColorsManager.darkTextPrimary : ColorsManager.lightTextPrimary,
    ),
  ),
);
}

Container textCard(String text, double font){
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 20),
    width: double.infinity,
    child: Text( text, 
    textAlign: TextAlign.right,
    style: TextStyle(
      fontSize: font==0? 20 : font,
      height: 1.6, // Line height for better readability
    ),),
  );

}