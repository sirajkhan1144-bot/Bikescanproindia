import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'database_helper.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  runApp(BikeScanApp());
}

class BikeScanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BikeScan Pro India',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BluetoothConnection? connection;
  bool isConnected = false;
  String rpm = '--';
  String speed = '--';
  String coolantTemp = '--';

  void connectToDevice() async {
    try {
      BluetoothDevice? device = await FlutterBluetoothSerial.instance
          .getBondedDevices()
          .then((devices) => devices.firstWhere((d) => d.name!.contains('OBD')));
      
      connection = await BluetoothConnection.toAddress(device.address);
      setState(() => isConnected = true);
      
      connection!.input!.listen((Uint8List data) {
        String response = ascii.decode(data);
        parseOBDResponse(response);
      });
      
      sendCommand('ATZ');
      Future.delayed(Duration(seconds: 1), () => sendCommand('010C'));
    } catch (e) {
      print('Error: $e');
    }
  }

  void sendCommand(String cmd) {
    if (connection != null && connection!.isConnected) {
      connection!.output.add(Uint8List.fromList(ascii.encode(cmd + '\r')));
    }
  }

  void parseOBDResponse(String response) {
    if (response.contains('41 0C')) {
      var parts = response.split(' ');
      int a = int.parse(parts[2], radix: 16);
      int b = int.parse(parts[3], radix: 16);
      setState(() => rpm = ((a * 256 + b) / 4).toStringAsFixed(0));
    }
    if (response.contains('41 0D')) {
      var parts = response.split(' ');
      int speedVal = int.parse(parts[2], radix: 16);
      setState(() => speed = speedVal.toString());
    }
    if (response.contains('41 05')) {
      var parts = response.split(' ');
      int temp = int.parse(parts[2], radix: 16) - 40;
      setState(() => coolantTemp = temp.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('BikeScan Pro India')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: connectToDevice,
              child: Text(isConnected ? 'Connected' : 'Connect OBD'),
            ),
            SizedBox(height: 20),
            Text('RPM: $rpm', style: TextStyle(fontSize: 24)),
            Text('Speed: $speed km/h', style: TextStyle(fontSize: 24)),
            Text('Temp: $coolantTemp°C', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
