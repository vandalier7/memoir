import 'dart:isolate';

import 'package:flutter/material.dart';
import 'dart:core';
import 'package:presentation/objects/unfocus_on_tap.dart';
import '../objects/globals.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../processes/auth.dart';

// the ui design
class SignInCard extends StatelessWidget {
  const SignInCard({super.key});
  

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final double logoSize = 75;

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
            Positioned(
              left: (screenWidth * 0.5) - (logoSize * 0.5),
              top: screenHeight * 0.1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: logoSize,
                      width: logoSize,
                      child: Image.asset("assets/logo.png"),
                    )
                  ),
                ],
              )
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment(0, -0.6),
                child: Material(
                    color: Colors.transparent,
                    child: Text("Memoir", textAlign: TextAlign.center, style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ),
              ),
            ),

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

  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpUsernameController = TextEditingController();

  final _logInEmailController = TextEditingController();
  final _logInPasswordController = TextEditingController();
  
  bool _isLoading = false;
  
  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

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
    finishLoading();
  }

  void finishLoading() async {
    await Future.delayed(Duration(milliseconds: 500));
    setState(() {
      toggleLoading(false);
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
                child: IgnorePointer(
                  ignoring: _isLoading,
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
                ),
              )  ,
            ],
          ),
          Expanded(child: 
            TabBarView(
              controller: _tabController,
              physics: _isLoading ? NeverScrollableScrollPhysics() : null,
              children: [
              LogIn(
                formKey: _logInKey, 
                emailController: _logInEmailController, 
                passwordController: _logInPasswordController,
                onLoadingChanged: _setLoading,
              ),
              SignUp(
                formKey: _signUpKey, 
                usernameController: _signUpUsernameController, 
                emailController: _signUpEmailController, 
                passwordController: _signUpPasswordController,
                onLoadingChanged: _setLoading,
              ),
            ])
          )
        ],
      ),
    );
  }
}

class LogIn extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final ValueChanged<bool> onLoadingChanged;

  const LogIn({
    super.key, 
    required this.formKey, 
    required this.emailController, 
    required this.passwordController,
    required this.onLoadingChanged,
  });

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  bool _isLoading = false;
  String? _errorMessage;


  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
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
                controller: widget.emailController,
                enabled: !_isLoading,
                style: TextStyle(
                    fontSize: 14
                ),
                validator: (value) => validateEmail(value),
                
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
                controller: widget.passwordController,
                validator: (value) => validateLength(value, 0, "password"),
                enabled: !_isLoading,
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
          if (_errorMessage != null) 
            Center(
              child: Padding(
              padding: EdgeInsets.all(0.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
            ),
          Center(
            child: Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: (_errorMessage != null ? 12 : 30), bottom: 30),
              height: (_errorMessage != null ? 82 : 100),
              width: 400,
              
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: _isLoading ? [
                      Colors.grey.shade400,
                      Colors.grey.shade400,
                    ] : const [
                      Color(0xFFF75270),
                      Color.fromARGB(255, 250, 132, 154),
                      Color.fromARGB(255, 252, 165, 181),
                      Color.fromARGB(255, 245, 200, 157),
                      Color.fromARGB(255, 248, 217, 174),
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
                  onPressed: _isLoading ? null : () async {
                     setState(() {
                        _errorMessage = null;
                      });
                    if (widget.formKey.currentState!.validate()) {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      widget.onLoadingChanged(true);
                      
                      try {
                        await loginUser(
                          widget.emailController.text.trim(),
                          widget.passwordController.text.trim()
                        );  
                        toggleLoading(true);
                        await Future.delayed(Duration(seconds: 1));
                        if (!context.mounted) return;
                        
                        Navigator.pushNamed(context, '/map');
                        
                      } on FirebaseAuthException catch (e) {
                        // Handle Firebase Auth specific errors
                        if (!context.mounted) return;
                        
                        String errorMessage;
                        if (e.code == 'user-not-found') {
                          errorMessage = 'No account found with this email.';
                        } else if (e.code == 'invalid-credential') {
                          errorMessage = 'Invalid email or password.';
                        } else if (e.code == 'too-many-requests') {
                          errorMessage = 'Too many requests. Try again in a few minutes.';
                        } else if (e.code == 'user-disabled') {
                          errorMessage = 'This account has been disabled.';
                        } else {
                          errorMessage = 'Login failed: ${e.code}';
                        }
                        
                        // Show error using SnackBar
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(
                        //     content: Text(errorMessage),
                        //     backgroundColor: Colors.red,
                        //     duration: Duration(seconds: 4),
                        //   ),
                        // );

                        // Show error through _errorMessage
                        setState(() {
                          _errorMessage = errorMessage;
                        });
                        
                      } catch (e) {
                        // Handle any other errors
                        if (!context.mounted) return;
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('An unexpected error occurred: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                          widget.onLoadingChanged(false);
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero,
                    disabledBackgroundColor: Colors.transparent,
                  ),
                  child: Center(
                    child: _isLoading 
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color.fromARGB(255, 242, 253, 233),
                            ),
                          ),
                        )
                      : Text(
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

class SignUp extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController usernameController;
  final ValueChanged<bool> onLoadingChanged;

  const SignUp({
    super.key, 
    required this.formKey, 
    required this.usernameController, 
    required this.emailController, 
    required this.passwordController,
    required this.onLoadingChanged,
  });

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
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
                controller: widget.usernameController,
                enabled: !_isLoading,
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
                controller: widget.emailController,
                enabled: !_isLoading,
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
                controller: widget.passwordController,
                enabled: !_isLoading,
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
          if (_errorMessage != null) 
            Center(
              child: Padding(
              padding: EdgeInsets.all(0.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
            ),
          Center(
            child: Container(
              padding: EdgeInsets.only(right: 20, left: 20, bottom: 20, top: _errorMessage != null ? 2 : 20),
              height: _errorMessage != null ? 62 : 80,
              width: 400,
              
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: _isLoading ? [
                      Colors.grey.shade400,
                      Colors.grey.shade400,
                    ] : const [
                      Color(0xFFF75270),
                      Color.fromARGB(255, 250, 132, 154),
                      Color.fromARGB(255, 252, 165, 181),
                      Color.fromARGB(255, 245, 200, 157),
                      Color.fromARGB(255, 248, 217, 174),
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
                  onPressed: _isLoading ? null : () async {
                    if (widget.formKey.currentState!.validate()) {
                      setState(() {
                        _isLoading = true;
                      });
                      widget.onLoadingChanged(true);
                      
                      try {
                        await registerUser(
                          widget.usernameController.text.trim(),
                          widget.emailController.text.trim(),
                          widget.passwordController.text.trim()
                        );
                        toggleLoading(true);
                        await Future.delayed(Duration(seconds: 1));
                        if (!context.mounted) return;
                        Navigator.pushNamed(context, '/map');
                      } on FirebaseAuthException catch (e) {
                        // Handle Firebase Auth specific errors
                        if (!context.mounted) return;
                        
                        String errorMessage;
                        if (e.code == 'email-already-in-use') {
                          errorMessage = 'Email already in use.';
                        } else if (e.code == 'invalid-credential') {
                          errorMessage = 'Invalid email or password.';
                        } else if (e.code == 'too-many-requests') {
                          errorMessage = 'Too many requests. Try again in a few minutes.';
                        } else if (e.code == 'user-disabled') {
                          errorMessage = 'This account has been disabled.';
                        } else if (e.code == 'username-taken') {
                          errorMessage = 'This username is already in use.';
                        }else {
                          errorMessage = 'Login failed: ${e.code}';
                        }
                        

                        // Show error through _errorMessage
                        setState(() {
                          _errorMessage = errorMessage;
                          _isLoading = false;
                        });
                        widget.onLoadingChanged(false);
                        
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero,
                    disabledBackgroundColor: Colors.transparent,
                  ),
                  child: Center(
                    child: _isLoading 
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color.fromARGB(255, 242, 253, 233),
                            ),
                          ),
                        )
                      : Text(
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
    return 'Needs a number, uppercase and lowercase letter';
  }
  if (!hasLowercase.hasMatch(value)) {
    return 'Needs a number, uppercase and lowercase letter';
  }
  if (!hasNumber.hasMatch(value)) {
    return 'Needs a number, uppercase and lowercase letter';
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
    return 'Please enter your $fieldName';
  }

  if (value.length < length) {
    return '$fieldName is not long enough lol';
  }

  return null; // ✅ Valid
}