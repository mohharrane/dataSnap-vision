import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_result.dart';

class DataStorageService {
  static const String _storageKey = 'datasnap_modules';

  // Save the entire map of modules and students to device memory
  Future<void> saveModuleData(Map<String, List<StudentResult>> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert the Map into a giant JSON string
    Map<String, dynamic> jsonMap = {};
    data.forEach((moduleName, students) {
      jsonMap[moduleName] = students.map((s) => s.toJson()).toList();
    });

    String jsonString = json.encode(jsonMap);
    await prefs.setString(_storageKey, jsonString);
  }

  // Load the map of modules and students from device memory
  Future<Map<String, List<StudentResult>>> loadModuleData() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return {}; // Return empty map if nothing is saved yet
    }

    try {
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      Map<String, List<StudentResult>> loadedData = {};

      jsonMap.forEach((moduleName, studentListJson) {
        List<dynamic> list = studentListJson;
        loadedData[moduleName] = list.map((item) => StudentResult.fromJson(item)).toList();
      });

      return loadedData;
    } catch (e) {
      print("Error loading data: $e");
      return {};
    }
  }
}
