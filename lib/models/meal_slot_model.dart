import 'package:flutter/material.dart';

// ignore_for_file: prefer_typing_uninitialized_variables
enum Colours { green, amber, brown, purple, orange, pink }

class MealSlot {
  final String? name;
  final Color? colour;

  const MealSlot({
    this.name,
    this.colour,
  });

  factory MealSlot.fromJson(Map<String, dynamic> json) =>
      MealSlot(name: json['name'], colour: json['colour']);

  Map<String, dynamic> toJson() => {
        'name': name,
        'colour': colour,
      };
}
