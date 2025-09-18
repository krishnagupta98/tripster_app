// lib/screens/explore_screen.dart
import 'package:flutter/material.dart';
import '../widgets/explore_map_view.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ExploreMapView(),
    );
  }
}