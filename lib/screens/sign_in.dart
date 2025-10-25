import 'package:flutter/material.dart';
import 'dart:core';
import 'package:maplibre_gl/maplibre_gl.dart';
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
                    height: 465,
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
  final _logInKey = GlobalKey<FormState>();
  final _signUpKey = GlobalKey<FormState>();

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
                padding: EdgeInsets.only(top: 20, left: 40, right: 40, bottom: 20),
                height: 70,
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
              LogIn(formKey: _logInKey,),
              SignUp(formKey: _signUpKey,),
            ])
          )
        ],
      ),
    );
  }
}

class LogIn extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const LogIn({super.key, required this.formKey});


  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(left: 23, top: 10),
            child: Text("Email", textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold),),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 55,
              child: TextFormField(
                style: TextStyle(
                    fontSize: 14
                ),
                validator: (value) => validateEmail(value),
                // forceErrorText: "Test error",
                
                decoration: InputDecoration(
                  errorStyle: TextStyle(fontSize: 10),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 7),
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
                  // errorBorder: OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(5),
                  //   borderSide: BorderSide.none,
                  // ),
                  // focusedErrorBorder: OutlineInputBorder(
                  //   borderRadius: BorderRadius.circular(5),
                  //   borderSide: BorderSide.none,
                  // ),

                  
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
              height: 55,
              child: TextFormField(
                
                validator:(value) => validatePassword(value),
                obscureText: true,
                style: TextStyle(
                    fontSize: 14
                ),
                decoration: InputDecoration(
                  errorStyle: TextStyle(fontSize: 10, overflow: TextOverflow.fade),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 7),
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
          Center(
            child: Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 30, bottom: 30),
              height: 100,
              width: 400,
              
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF75270), // deep pink
                      Color.fromARGB(255, 250, 132, 154), // deep pink
                      Color.fromARGB(255, 252, 165, 181), // deep pink
                      Color.fromARGB(255, 245, 200, 157), // beige tint
                      Color.fromARGB(255, 248, 217, 174), // beige tint
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      // all fields are valid — proceed with sign-in/up
                    }

                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, // make button background transparent
                    shadowColor: Colors.transparent, // prevent double shadows
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero, // let gradient fill perfectly
                  ),
                  child: const Center(
                    child: Text(
                      "Log In",
                      style: TextStyle(
                        color: Color.fromARGB(255, 242, 253, 233),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
            )
          ),
          Center(
            child: Text("Forgot password?", style: TextStyle(fontSize: 12, color: Colors.grey),),
          )
        ],
      ),
    );
  }
}

class SignUp extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const SignUp({super.key, required this.formKey});


  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
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
              height: 53,
              child: TextFormField(
                validator: (value) => validateLength(value, 0, "username"),
                style: TextStyle(
                    fontSize: 14
                ),
                decoration: InputDecoration(
                  isDense: true,
                  errorStyle: TextStyle(fontSize: 10),
                  contentPadding: EdgeInsets.symmetric(vertical: 7),
                  prefixIcon: Icon(Icons.person_outline),
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
            padding: EdgeInsets.only(left: 23, right: 30),
            child: Text("Email", textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold),),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 53,
              child: TextFormField(
                validator: (value) => validateEmail(value),
                style: TextStyle(
                    fontSize: 14
                ),
                decoration: InputDecoration(
                  isDense: true,
                  errorStyle: TextStyle(fontSize: 10),
                  contentPadding: EdgeInsets.symmetric(vertical: 7),
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
            padding: EdgeInsets.only(left: 23, right: 30),
            child: Text("Password", textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.bold),),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 53,
              child: TextFormField(
                validator: (value) => validatePassword(value),
                obscureText: true,
                style: TextStyle(
                    fontSize: 14
                ),
                decoration: InputDecoration(

                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 7),
                  errorStyle: TextStyle(fontSize: 10),
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
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 80,
              width: 400,
              
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF75270), // deep pink
                      Color.fromARGB(255, 250, 132, 154), // deep pink
                      Color.fromARGB(255, 252, 165, 181), // deep pink
                      Color.fromARGB(255, 245, 200, 157), // beige tint
                      Color.fromARGB(255, 248, 217, 174), // beige tint
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      // all fields are valid — proceed with sign-in/up
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, // make button background transparent
                    shadowColor: Colors.transparent, // prevent double shadows
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero, // let gradient fill perfectly
                  ),
                  child: const Center(
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Color.fromARGB(255, 242, 253, 233),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
            )

          )
        ],
      ),
    );
  }
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your password';
  }

  if (value.length < 8) {
    return 'Password must be at least 8 characters long';
  }

  final hasUppercase = RegExp(r'[A-Z]');
  final hasLowercase = RegExp(r'[a-z]');
  final hasNumber = RegExp(r'\d');

  if (!hasUppercase.hasMatch(value)) {
    return 'Password must contain at least one uppercase letter';
  }
  if (!hasLowercase.hasMatch(value)) {
    return 'Password must contain at least one lowercase letter';
  }
  if (!hasNumber.hasMatch(value)) {
    return 'Password must contain at least one number';
  }

  return null; // ✅ Valid
}

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your email';
  }

  // Basic RFC 5322 compliant pattern
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value)) {
    return 'Please enter a valid email address';
  }

  return null; // ✅ Valid
}

String? validateLength(String? value, int length, String fieldName) {
  if (value == null || value.isEmpty) {
    return 'Please enter your ' + fieldName;
  }

  if (value.length < length) {
    return fieldName + ' is not long enough lol';
  }

  return null; // ✅ Valid
}