import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';




// pk.2e56aa59169aa53b63093b78aff0e291

class LocationIQService {
  final String apiKey;

  LocationIQService(this.apiKey);

  Future<String?> reverseGeocode(double lat, double lon) async {
    final url = Uri.parse(
      'https://us1.locationiq.com/v1/reverse?key=$apiKey&lat=$lat&lon=$lon&format=json',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['display_name']; // full address string
    } else {
      print('Error: ${response.statusCode}');
      print(response.body);
      return null;
    }
  }
}

Future<String> getAddressFromLocation(LatLng pos, LocationIQService locIQ) async {
  final address = await locIQ.reverseGeocode(pos.latitude, pos.longitude);
  if (address != null) {
    return address;
  } else {
    return "null";
  }
}