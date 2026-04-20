import 'package:flutter/material.dart';
import 'activation_screen.dart';

class PaywallScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900], // Dark premium theme
      appBar: AppBar(
        title: const Text("Upgrade to Premium"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.diamond, size: 100, color: Colors.amber),
              const SizedBox(height: 24),
              const Text(
                "Unlock Unlimited Scans!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                "You have used all 5 of your free scans. To continue using DataSnap Vision forever, please purchase a premium serial key.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.blue[100]),
              ),
              const SizedBox(height: 48),
              
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text("How to pay?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text("1. Send payment via BaridiMob or CCP to:", textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text("RIP: 00799999000000000000", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[800])),
                      Text("CCP: 0000000000 Clé 00", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[800])),
                      const SizedBox(height: 16),
                      const Text("2. Contact us on WhatsApp with the receipt to get your Activation Code:", textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      const Text("+213 555 55 55 55", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              ElevatedButton.icon(
                icon: const Icon(Icons.key),
                label: const Text("I have an Activation Code", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ActivationScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
