import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import 'home_screen.dart';

class ActivationScreen extends StatefulWidget {
  @override
  _ActivationScreenState createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _codeController = TextEditingController();
  final  _subService = SubscriptionService();
  bool _isLoading = false;
  String _message = '';
  bool _isSuccess = false;

  Future<void> _verifyCode() async {
    String code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _message = '';
    });

    String result = await _subService.applyActivationCode(code);

    setState(() {
      _isLoading = false;
      if (result == "SUCCESS") {
         _isSuccess = true;
         _message = "Thank you! Your account is now Premium!";
      } else {
         _isSuccess = false;
         _message = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Serial Key")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.vpn_key, size: 64, color: Colors.amber),
            const SizedBox(height: 24),
            const Text(
               "Paste the Serial Key you received from Support below:",
               textAlign: TextAlign.center,
               style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _message, 
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _isSuccess ? Colors.green : Colors.red, fontWeight: FontWeight.bold)
                ),
              ),
            if (!_isSuccess) ...[
               TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: "XXXX-XXXX-XXXX",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator())
                    : const Text("Unlock Premium", style: TextStyle(fontSize: 18)),
              ),
            ] else ...[
               ElevatedButton(
                onPressed: () {
                   Navigator.pushAndRemoveUntil(
                     context, 
                     MaterialPageRoute(builder: (_) => HomeScreen()),
                     (route) => false
                   );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Go to Home", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
