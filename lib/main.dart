

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'my_scaffold.dart';
import 'map_body.dart';



void main(){
  MapLibreMap.useHybridComposition = true;
    runApp(Root());
}

class Root extends StatelessWidget {
    const Root({super.key});

    @override
  Widget build(BuildContext context) {
    pixelRatio = MediaQuery.of(context).devicePixelRatio;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
        title: "Memoir",
        home: MyScaffold(),
    );
  }
}


