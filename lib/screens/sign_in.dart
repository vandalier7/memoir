import 'package:flutter/material.dart';
import 'package:presentation/objects/unfocus_on_tap.dart';

// the ui design
class SignInCard extends StatelessWidget {
  const SignInCard({super.key});

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    const double baseLift = 100.0; // existing idle lift you had

    // When keyboard appears, we move the card up by keyboardHeight in addition to baseLift.
    final double translateY = baseLift - (keyboardHeight * 0.7);

    return UnfocusOnTap(
      child: Container(
        // outer container stays fixed — background, full screen, etc.
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            // other background/content can go here (will NOT be moved)
            // e.g. Center(child: BackgroundDecorations()),

            // The centered card that we WILL move
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                // transform only affects the card widget
                transform: Matrix4.translationValues(0, translateY, 0),
                // ensure transform origin is center (default)
                child: Card(
                  elevation: 20,
                  color: Theme.of(context).colorScheme.onTertiary,
                  child: const SizedBox(
                    height: 450,
                    width: 325,
                    child: SignIn(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class SignIn extends StatefulWidget {
  const SignIn ({super.key});

  @override
  State<SignIn> createState() => SignInState();
}

class SignInState extends State<SignIn> with SingleTickerProviderStateMixin{
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 👇 When user switches tabs, clear focus
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.only(top: 20, left: 20, right: 20),
            child: Align(
              alignment: AlignmentGeometry.center,
              child: Text("Welcome!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onPrimary
                ),
              ),
            )
          ),
          Container(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: Align(
              alignment: AlignmentGeometry.center,
              child: Text("Join our community to share and explore memorable moments.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color.fromARGB(134, 0, 0, 0)
                ),
              ),
            )
          ),
          Stack(
            children: [
              Container(
                padding: EdgeInsets.only(top: 17, left: 37, right: 37, bottom: 7),
                child: Container(
                  decoration: BoxDecoration(color: const Color.fromARGB(255, 243, 242, 242), borderRadius: BorderRadius.circular(30)),
                  height: 36,
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 20, left: 40, right: 40, bottom: 30),
                height: 80,
                child: TabBar(
                      controller: _tabController,
                        indicator: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(40),
                          
                        ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Theme.of(context).colorScheme.tertiary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: "Log In"), Tab(text: "Sign Up")
                  ],
                ),
              )  ,
            ],
          ),
          Expanded(child: 
            TabBarView(
              controller: _tabController,
              children: [
              LogIn(),
              SignUp(),
            ])
          )
        ],
      ),
    );
  }
}

class LogIn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 23),
            child: Text("Email", textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold),),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 35,
              child: TextFormField(
                style: TextStyle(
                    fontSize: 14
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  prefixIcon: Icon(Icons.email_outlined),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 20,
                  ),

                  iconColor: const Color.fromARGB(255, 146, 146, 146),
                  hintText: "your@email.com",
                  hintStyle: TextStyle(
                    color: const Color.fromARGB(255, 146, 146, 146),
                    fontSize: 14
                  ),
                  
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  floatingLabelStyle: TextStyle(color: Theme.of(context).primaryColor),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 247, 247, 247),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(strokeAlign: BorderSide.strokeAlignOutside, color: Colors.black54),
                  ),

                  
                ),
              ),
            )
          ),
          Container(
            padding: EdgeInsets.only(left: 23, right: 30, top: 20),
            child: Text("Password", textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold),),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 35,
              child: TextFormField(
                obscureText: true,
                style: TextStyle(
                    fontSize: 14
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  prefixIcon: Icon(Icons.lock_outline),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 20,
                  ),
                  
                  iconColor: const Color.fromARGB(255, 146, 146, 146),
                  hintText: "●●●●●●●●●",
                  hintStyle: TextStyle(
                    color: const Color.fromARGB(255, 146, 146, 146),
                    fontSize: 14
                  ),
                  
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  floatingLabelStyle: TextStyle(color: Theme.of(context).primaryColor),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 247, 247, 247),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(strokeAlign: BorderSide.strokeAlignOutside, color: Colors.black54),
                  ),

                  
                ),
              ),
            )
          ),
        ],
      ),
    );
  }
}

class SignUp extends StatelessWidget {
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 23),
            child: Text("Username", textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold),),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 35,
              child: TextFormField(
                style: TextStyle(
                    fontSize: 14
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  prefixIcon: Icon(Icons.email_outlined),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 20,
                  ),

                  iconColor: const Color.fromARGB(255, 146, 146, 146),
                  hintText: "Your Name",
                  hintStyle: TextStyle(
                    color: const Color.fromARGB(255, 146, 146, 146),
                    fontSize: 14
                  ),
                  
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  floatingLabelStyle: TextStyle(color: Theme.of(context).primaryColor),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 247, 247, 247),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(strokeAlign: BorderSide.strokeAlignOutside, color: Colors.black54),
                  ),

                  
                ),
              ),
            )
          ),
          Container(
            padding: EdgeInsets.only(left: 23, right: 30, top: 10),
            child: Text("Email", textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold),),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 35,
              child: TextFormField(
                style: TextStyle(
                    fontSize: 14
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  prefixIcon: Icon(Icons.email_outlined),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 20,
                  ),

                  iconColor: const Color.fromARGB(255, 146, 146, 146),
                  hintText: "your@email.com",
                  hintStyle: TextStyle(
                    color: const Color.fromARGB(255, 146, 146, 146),
                    fontSize: 14
                  ),
                  
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  floatingLabelStyle: TextStyle(color: Theme.of(context).primaryColor),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 247, 247, 247),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(strokeAlign: BorderSide.strokeAlignOutside, color: Colors.black54),
                  ),

                  
                ),
              ),
            )
          ),
          Container(
            padding: EdgeInsets.only(left: 23, right: 30, top: 10),
            child: Text("Password", textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold),),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 35,
              child: TextFormField(
                obscureText: true,
                style: TextStyle(
                    fontSize: 14
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  prefixIcon: Icon(Icons.lock_outline),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 20,
                  ),
                  
                  iconColor: const Color.fromARGB(255, 146, 146, 146),
                  hintText: "●●●●●●●●●",
                  hintStyle: TextStyle(
                    color: const Color.fromARGB(255, 146, 146, 146),
                    fontSize: 14
                  ),
                  
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  floatingLabelStyle: TextStyle(color: Theme.of(context).primaryColor),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 247, 247, 247),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(strokeAlign: BorderSide.strokeAlignOutside, color: Colors.black54),
                  ),

                  
                ),
              ),
            )
          ),
        ],
      ),
    );
  }
}