import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_result.dart';

class DataStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Save the entire map of modules and students to Firestore
  Future<void> saveModuleData(Map<String, List<StudentResult>> data) async {
    if (_userId == null) return;

    // Convert the Map into JSON
    Map<String, dynamic> jsonMap = {};
    data.forEach((moduleName, students) {
      jsonMap[moduleName] = students.map((s) => s.toJson()).toList();
    });

    // Save as a single document for simplicity, maintaining same structure as local storage
    await _firestore.collection('users').doc(_userId).set({
      'modules': jsonMap,
    }, SetOptions(merge: true));
  }

  // Load the map of modules and students from Firestore
  Future<Map<String, List<StudentResult>>> loadModuleData() async {
    if (_userId == null) return {};

    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(_userId).get();
      
      if (!doc.exists || doc.data() == null) return {};
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (!data.containsKey('modules')) return {};

      Map<String, dynamic> jsonMap = data['modules'] as Map<String, dynamic>;
      Map<String, List<StudentResult>> loadedData = {};

      jsonMap.forEach((moduleName, studentListJson) {
        List<dynamic> list = studentListJson;
        loadedData[moduleName] = list.map((item) => StudentResult.fromJson(item as Map<String, dynamic>)).toList();
      });

      return loadedData;
    } catch (e) {
      print("Error loading data from Firestore: $e");
      return {};
    }
  }
}
