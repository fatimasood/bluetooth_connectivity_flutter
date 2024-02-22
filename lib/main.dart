import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BluetoothScreen(),
    );
  }
}

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  List<BluetoothDevice> _devices = [];
  late BluetoothConnection _connection;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    // Ensure Bluetooth is enabled
    bool? isEnabled = await _bluetooth.isEnabled;
    if (isEnabled != null && !isEnabled) {
      await _bluetooth.requestEnable();
    }
  }

  void _startDiscovery() async {
    try {
      print("Starting discovery...");
      _bluetooth
          .startDiscovery()
          .listen((BluetoothDiscoveryResult result) async {
        print(
            'Discovered ${result.device.address}: ${result.device.name ?? 'Unknown Device'}');
        print('Bonded: ${result.device.isBonded}');

        if (!result.device.isBonded) {
          await _bondDevice(result.device);
        }

        _devices.add(result.device);
        setState(() {});
      });
    } catch (error) {
      print('Error during discovery: $error');
    }
  }

  Future<void> _bondDevice(BluetoothDevice device) async {
    try {
      print(
          'Bonding with ${device.name ?? 'Unknown Device'} at ${device.address}...');

      final List<BluetoothDevice> bondedDevices =
          await FlutterBluetoothSerial.instance.getBondedDevices();

      if (!bondedDevices.contains(device)) {
        await FlutterBluetoothSerial.instance
            .bondDeviceAtAddress(device.address);
      }

      print('Bonded successfully with ${device.name ?? 'Unknown Device'}');
    } catch (error) {
      print('Error bonding with ${device.name ?? 'Unknown Device'}: $error');
      // Handle the error, possibly display a user-friendly message.
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      print(
          'Connecting to ${device.name ?? 'Unknown Device'} at ${device.address}...');
      _connection = await BluetoothConnection.toAddress(device.address);
      print('Connected to ${device.name ?? 'Unknown Device'}');
    } catch (error) {
      print('Error connecting to ${device.name ?? 'Unknown Device'}: $error');
      // Handle the error here, and possibly display a user-friendly message.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Devices'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              print("Button pressed. Initiating device scan...");
              _startDiscovery();
            },
            child: Text('Scan Devices'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = _devices[index];
                return ListTile(
                  title: Text(device.name ?? 'Unknown Device'),
                  subtitle: Text(device.address),
                  onTap: () {
                    print(
                        'Device selected: ${device.name ?? 'Unknown Device'}');
                    _connectToDevice(device);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print('Disposing resources...');
    _bluetooth.cancelDiscovery();
    _connection?.close();
    super.dispose();
  }
}
