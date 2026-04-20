import 'package:flutter/material.dart';
import '../models/student_result.dart';
import '../services/data_storage_service.dart';
import '../services/auth_service.dart';
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('DataSnap Vision', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Colors.blue[800],
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Sign Out'),
                  content: Text('Are you sure you want to sign out?'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context); // Close the dialog
                        await AuthService().signOut();
                      },
                      child: Text('Sign Out', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Add Module Banner
          Container(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
            decoration: BoxDecoration(
              color: Colors.blue[800],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 5))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                         BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                    child: TextField(
                      controller: _newModuleController,
                      decoration: InputDecoration(
                        hintText: 'New Module (e.g. Math Midterm)',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.folder_open, color: Colors.blue[300]),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(12),
                     boxShadow: [
                         BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                      ],
                  ),
                  child: IconButton(
                    onPressed: _addModule,
                    icon: Icon(Icons.add, color: Colors.white, size: 28),
                    padding: EdgeInsets.all(12),
                  ),
                )
              ],
            ),
          ),
          
          Expanded(
            child: _moduleData.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.create_new_folder_outlined, size: 80, color: Colors.grey[300]),
                      SizedBox(height: 16),
                      Text('No Modules Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                      SizedBox(height: 8),
                      Text('Create a module above to start scanning', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
              padding: EdgeInsets.only(top: 16, bottom: 24),
              itemCount: _moduleData.length,
              itemBuilder: (context, index) {
                String moduleName = _moduleData.keys.elementAt(index);
                List<StudentResult> results = _moduleData[moduleName]!;
                
                return Card(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                     borderRadius: BorderRadius.circular(16),
                     onTap: () => _openScanner(moduleName),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.folder, color: Colors.blue[700], size: 32),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(moduleName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey[800])),
                                SizedBox(height: 4),
                                Text('${results.length} papers scanned', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                            onPressed: () => _deleteModule(moduleName),
                            tooltip: 'Delete Module',
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey[400]),
                        ],
                      ),
                    ),
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
