import 'package:flutter/material.dart';

// the ui design
class SignInCard extends StatelessWidget {

  const SignInCard ({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Transform.translate(offset: Offset(0, 100),
            child: Card(
              elevation: 20,
              color: Theme.of(context).colorScheme.onTertiary,
                child: SizedBox(
                  height: 450,
                  width: 300,
                  child: SignIn(),
                ),
            ),
          )
        )
      );
  }
}

class SignIn extends StatefulWidget {
  const SignIn ({super.key});

  @override
  State<SignIn> createState() => SignInState();
}

class SignInState extends State<SignIn> {
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
                padding: EdgeInsets.only(top: 20, left: 40, right: 40, bottom: 10),
                height: 60,
                child: TabBar(
                  
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
            TabBarView(children: [
              Text("log in page", textAlign: TextAlign.center,),
              Text("sign up page", textAlign: TextAlign.center,),
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
    // TODO: implement build
    throw UnimplementedError();
  }
}

class SignUp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}