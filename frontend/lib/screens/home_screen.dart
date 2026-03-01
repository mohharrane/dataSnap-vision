import 'package:flutter/material.dart';
import '../models/student_result.dart';
import '../services/data_storage_service.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // A master map holding Module Names as keys, and their list of scanned results as values
  Map<String, List<StudentResult>> _moduleData = {};
  TextEditingController _newModuleController = TextEditingController();
  final DataStorageService _storageService = DataStorageService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _storageService.loadModuleData();
    setState(() {
      _moduleData = data;
    });
  }

  void _addModule() async {
    String newModule = _newModuleController.text.trim();
    if (newModule.isEmpty) return;
    
    if (_moduleData.containsKey(newModule)) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Module already exists!')));
       return;
    }

    setState(() {
      _moduleData[newModule] = [];
      _newModuleController.clear();
    });
    
    await _storageService.saveModuleData(_moduleData);
  }

  void _openScanner(String moduleName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerScreen(
          moduleName: moduleName, 
          initialResults: _moduleData[moduleName] ?? [],
          onDataChanged: (updatedList) async {
            _moduleData[moduleName] = updatedList;
            await _storageService.saveModuleData(_moduleData);
          },
        ),
      ),
    ).then((_) {
      // Refresh HomeScreen counts when returning from scanner
      setState(() {});
    });
  }

  void _deleteModule(String moduleName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Module?'),
        content: Text('Are you sure you want to delete $moduleName and all its scanned exams? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Cancel')
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              setState(() {
                _moduleData.remove(moduleName);
              });
              await _storageService.saveModuleData(_moduleData);
              Navigator.pop(context);
            }, 
            child: Text('Delete')
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DataSnap Vision'),
      ),
      body: Column(
        children: [
          // Add Module Banner
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newModuleController,
                    decoration: InputDecoration(
                      hintText: 'New Module (e.g. Math Midterm)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addModule,
                  child: Icon(Icons.add),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                )
              ],
            ),
          ),
          
          Expanded(
            child: _moduleData.isEmpty 
              ? Center(child: Text('Create a Module to start scanning.', style: TextStyle(color: Colors.grey, fontSize: 16)))
              : ListView.builder(
              itemCount: _moduleData.length,
              itemBuilder: (context, index) {
                String moduleName = _moduleData.keys.elementAt(index);
                List<StudentResult> results = _moduleData[moduleName]!;
                
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(Icons.folder, color: Colors.blue[800]),
                    ),
                    title: Text(moduleName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('${results.length} papers scanned'),
                    trailing:Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red[300]),
                          onPressed: () => _deleteModule(moduleName),
                        ),
                        Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                    onTap: () => _openScanner(moduleName),
                  ),
                );
              },
            )
          )
        ],
      ),
    );
  }
}
