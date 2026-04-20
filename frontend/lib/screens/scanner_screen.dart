import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/student_result.dart';
import '../services/api_service.dart';
import '../services/subscription_service.dart';
import 'paywall_screen.dart';

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
  final SubscriptionService _subService = SubscriptionService();
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
      bool canScan = await _subService.canScan();
      if (!canScan) {
        if (mounted) {
           Navigator.push(context, MaterialPageRoute(builder: (_) => PaywallScreen()));
        }
        return;
      }

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
                _subService.incrementScanCount();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalScanned = _results.length;
    double highestMark = 0.0;
    
    if (totalScanned > 0) {
      for (var r in _results) {
        if (r.mark > highestMark) highestMark = r.mark;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Scanning: ${widget.moduleName}', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Colors.blue[800],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Row(
             mainAxisSize: MainAxisSize.min,
            children: [
              Text('Batch', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
              Switch(
                value: _isBatchMode,
                onChanged: (val) {
                  setState(() {
                    _isBatchMode = val;
                  });
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.blue[300],
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _isLoading ? null : _exportData,
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[800]!, Colors.blue[600]!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 5))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('Total Scanned', totalScanned.toString(), Icons.fact_check_outlined),
                    Container(height: 40, width: 1, color: Colors.white.withOpacity(0.3)),
                    _buildStatItem('Highest Mark', highestMark.toStringAsFixed(1), Icons.emoji_events_outlined),
                  ],
                ),
              ),
              Expanded(
                child: _results.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.document_scanner_outlined, size: 80, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No papers scanned yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap the camera button to start',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final res = _results[index];
                        return Dismissible(
                          key: UniqueKey(),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20.0),
                            child: Icon(Icons.delete_outline, color: Colors.white, size: 28),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                                      SizedBox(width: 8),
                                      Text("Confirm Delete"),
                                    ],
                                  ),
                                  content: Text("Are you sure you want to delete ${res.name}'s result?"),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text("CANCEL", style: TextStyle(color: Colors.grey[700])),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: Text("DELETE", style: TextStyle(color: Colors.white)),
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
                                behavior: SnackBarBehavior.floating,
                              )
                            );
                          },
                          child: Card(
                            elevation: 2,
                            shadowColor: Colors.black12,
                            margin: EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[50],
                                child: Text((index + 1).toString(), style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                              ),
                              title: Text(res.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text('Group: ${res.group}', style: TextStyle(color: Colors.grey[600])),
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: res.mark >= 10 ? Colors.green[50] : Colors.red[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  res.mark.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 18, 
                                    color: res.mark >= 10 ? Colors.green[800] : Colors.red[800]
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                  ),
              ),
            ],
          ),
          
          // Full-screen Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)
                    ]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                      ),
                      SizedBox(height: 20),
                      Text('Processing Image...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                       SizedBox(height: 8),
                      Text('This might take a few seconds', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _scanDocument,
        icon: Icon(Icons.document_scanner),
         label: Text('Scan Paper'),
        tooltip: 'Scan Paper',
        backgroundColor: _isLoading ? Colors.grey : Colors.blue[700],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.blue[100], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
