import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/student_result.dart';
import '../services/api_service.dart';

class ScannerScreen extends StatefulWidget {
  final String moduleName;
  final List<StudentResult> initialResults;
  final Function(List<StudentResult>) onDataChanged;

  ScannerScreen({required this.moduleName, required this.initialResults, required this.onDataChanged});

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  
  late List<StudentResult> _results;
  bool _isLoading = false;
  bool _isBatchMode = false;

  @override
  void initState() {
    super.initState();
    // Start with the list passed in from the HomeScreen
    _results = List.from(widget.initialResults);
  }

  Future<void> _scanDocument() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50, // Compress the huge physical phone photos to speed up the network
      );
      if (photo == null) return;

      setState(() {
        _isLoading = true;
      });

      File imageFile = File(photo.path);
      StudentResult? result = await _apiService.scanPaper(imageFile);

      if (result != null) {
        await _showConfirmationDialog(result);
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showConfirmationDialog(StudentResult result) async {
    TextEditingController nameController = TextEditingController(text: result.name);
    TextEditingController groupController = TextEditingController(text: result.group);
    TextEditingController markController = TextEditingController(text: result.mark.toString());

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Student Name'),
              ),
              TextField(
                controller: groupController,
                decoration: InputDecoration(labelText: 'Group'),
              ),
              TextField(
                controller: markController,
                decoration: InputDecoration(labelText: 'Mark (Handwritten)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String newName = nameController.text.trim();
                bool isDuplicate = _results.any((res) => res.name.trim().toLowerCase() == newName.toLowerCase());
                
                if (isDuplicate) {
                  Navigator.pop(context); 
                  _showErrorSnackBar('Student "$newName" already has a grade recorded!');
                  return; // prevent save
                }

                setState(() {
                  result.name = newName;
                  result.group = groupController.text;
                  result.moduleName = widget.moduleName; // Overwrite the '' from the API
                  result.mark = double.tryParse(markController.text) ?? 0.0;
                  _results.add(result);
                });
                widget.onDataChanged(_results);
                Navigator.pop(context);
              },
              child: Text('Confirm & Save'),
            ),
          ],
        );
      },
    );

    if (_isBatchMode) {
      await Future.delayed(Duration(milliseconds: 300));
      _scanDocument();
    }
  }

  Future<void> _exportData() async {
    if (_results.isEmpty) {
      _showErrorSnackBar('No results to export.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<int> excelBytes = await _apiService.exportResults(_results);
      
      final directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/Exam_Results.xlsx';
      final File file = File(filePath);
      await file.writeAsBytes(excelBytes);

      await Share.shareXFiles([XFile(filePath)], text: 'Here are the exam results.');
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
       setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    int totalScanned = _results.length;
    double averageMark = 0.0;
    double highestMark = 0.0;
    
    if (totalScanned > 0) {
      double sum = 0;
      for (var r in _results) {
        sum += r.mark;
        if (r.mark > highestMark) highestMark = r.mark;
      }
      averageMark = sum / totalScanned;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Scanning: ${widget.moduleName}'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Row(
            children: [
              Text('Batch Mode', style: TextStyle(fontSize: 12, color: Colors.white)),
              Switch(
                value: _isBatchMode,
                onChanged: (val) {
                  setState(() {
                    _isBatchMode = val;
                  });
                },
                activeColor: Colors.white,
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _isLoading ? null : _exportData,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', totalScanned.toString()),
                _buildStatItem('Average', averageMark.toStringAsFixed(1)),
                _buildStatItem('Highest', highestMark.toStringAsFixed(1)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator())
              : _results.isEmpty 
                ? Center(child: Text('No papers scanned yet. Tap the camera icon to start.'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final res = _results[index];
                      return Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20.0),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Confirm Delete"),
                                content: Text("Are you sure you want to delete ${res.name} from this module?"),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text("CANCEL"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text(
                                      "DELETE",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          setState(() {
                            _results.removeAt(index);
                          });
                          widget.onDataChanged(_results);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${res.name} deleted'), 
                              duration: Duration(seconds: 2),
                            )
                          );
                        },
                        child: ListTile(
                          leading: CircleAvatar(child: Text((index + 1).toString())),
                          title: Text('${res.name} (Group: ${res.group})'),
                          trailing: Text(
                            res.mark.toString(),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      );
                    },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _scanDocument,
        child: Icon(Icons.camera_alt),
        tooltip: 'Scan Paper',
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}
