import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/student_result.dart';

class ApiService {
  // Use http://10.0.2.2:8000 for Android Emulator, http://127.0.0.1:8000 for iOS Simulator/Web
  // For physical devices, use the IP address of the machine running the backend (e.g. http://192.168.1.100:8000)
  static const String baseUrl = 'http://192.168.1.104:8000';

  Future<StudentResult?> scanPaper(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/scan'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        
        // Basic mapping logic based on backend output
        // backend returns: {"status": "success", "qr_data": {"student_info": {"name": "...", "group": "..."}}, "mark_data": {"mark": 15.5}}
        
        String name = 'Unknown';
        String group = 'Unknown';
        
        var qrData = jsonResponse['qr_data'];
        if (qrData != null && qrData['student_info'] != null) {
           var info = qrData['student_info'];
           if (info is Map) {
             String firstName = info['name']?.toString() ?? '';
             String lastName = info['surname']?.toString() ?? '';
             name = '$firstName $lastName'.trim();
             if (name.isEmpty) name = 'Unknown';
             
             group = info['group']?.toString() ?? 'Unknown';
           } else {
             // fallback if it's just raw text
             name = info.toString();
           }
        }
        
        double mark = 0.0;
        var markData = jsonResponse['mark_data'];
        if (markData != null && markData['mark'] != null) {
            mark = (markData['mark'] as num).toDouble();
        }

        return StudentResult(
          name: name,
          group: group,
          moduleName: '', // Left blank to be caught by ScannerScreen
          mark: mark,
        );
      } else {
        throw Exception('Failed to scan paper: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error calling backend: $e');
    }
  }

  Future<List<int>> exportResults(List<StudentResult> results) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/export'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(results.map((r) => r.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to export: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error exporting from backend: $e');
    }
  }
}
