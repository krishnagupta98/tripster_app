// lib/models/previous_trip_model.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/trip_model.dart';

class Expense {
  final String description;
  final double amount;
  final IconData icon;

  Expense({required this.description, required this.amount, required this.icon});
}

class TripPhoto {
  final String imageUrl;
  final DateTime date;
  final String location;

  TripPhoto({required this.imageUrl, required this.date, required this.location});
}

class PreviousTrip {
  final Trip baseTrip;
  final List<Expense> expenses;
  final List<TripPhoto> photos;

  PreviousTrip({required this.baseTrip, required this.expenses, required this.photos});

  double get totalExpenses => expenses.fold(0, (sum, item) => sum + item.amount);
}