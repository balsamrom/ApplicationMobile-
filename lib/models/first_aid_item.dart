import 'package:flutter/material.dart';

enum Priority { critique, urgent, modere }

class FirstAidItem {
  final String title;
  final Priority priority;
  final String timeToAction;
  final String description;
  final List<String> materials;
  final List<String> steps;

  const FirstAidItem({
    required this.title,
    required this.priority,
    required this.timeToAction,
    required this.description,
    required this.materials,
    required this.steps,
  });

  Color get priorityColor {
    switch (priority) {
      case Priority.critique:
        return Colors.red;
      case Priority.urgent:
        return Colors.orange;
      case Priority.modere:
        return Colors.yellow;
    }
  }
}
