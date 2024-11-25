import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class BleDevicePage extends StatefulWidget {
  const BleDevicePage({super.key});

  @override
  _BleDevicePageState createState() => _BleDevicePageState();
}

class _BleDevicePageState extends State<BleDevicePage> {
  final FlutterBlue _flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> _devicesList = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;
  List<BluetoothService> _services = [];
  double _progress = 0.0; // For progress bar
  bool _isUploading = false; // To show/hide progress bar

  void _scanForDevices() {
    if (!_isScanning) {
      setState(() {
        _isScanning = true;
        _devicesList.clear();
      });

      _flutterBlue.scan(timeout: Duration(seconds: 4)).listen((scanResult) {
        setState(() {
          if (!_devicesList.contains(scanResult.device)) {
            _devicesList.add(scanResult.device);
          }
        });
      }, onDone: () {
        setState(() {
          _isScanning = false;
        });
      });
    }
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _devicesList = [device];
      });

      List<BluetoothService> services = await device.discoverServices();
      setState(() {
        _services = services;
      });
    } catch (e) {
      print("Connection failed: $e");
    }
  }

  void _checkFirmware() async {
    if (_connectedDevice == null || _services.isEmpty) {
      print("No device connected or no services discovered.");
      return;
    }

    for (BluetoothService service in _services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          try {
            await characteristic.write(Uint8List.fromList("hello".codeUnits));
            print("Message 'hello' sent to the device.");
            return;
          } catch (e) {
            print("Failed to send message: $e");
            return;
          }
        }
      }
    }
    print("No writable characteristic found.");
  }

  void _updateFirmWare() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      print("File picked: ${file.path}");

      int fileSize = await file.length();
      print("File size: $fileSize bytes");

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Firmware Update"),
            content:
                Text("File size: $fileSize bytes. Do you want to upload it?"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _sendFirmware(file, fileSize);
                },
                child: Text("Accept"),
              ),
            ],
          );
        },
      );
    } else {
      print("No file selected by the user.");
    }
  }

  void _sendFirmware(File file, int fileSize) async {
    if (_connectedDevice == null || _services.isEmpty) {
      print("No device connected or no services discovered.");
      return;
    }

    setState(() {
      _isUploading = true;
      _progress = 0.0;
    });

    for (BluetoothService service in _services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          try {
            String startMessage = "start $fileSize";
            await characteristic
                .write(Uint8List.fromList(startMessage.codeUnits));
            print("Sent start message: $startMessage");

            List<int> fileBytes = await file.readAsBytes();
            int chunkSize = 512;
            int totalChunks = (fileBytes.length / chunkSize).ceil();

            for (int i = 0; i < totalChunks; i++) {
              int start = i * chunkSize;
              int end = (i + 1) * chunkSize;
              List<int> chunk = fileBytes.sublist(
                  start, end > fileBytes.length ? fileBytes.length : end);
              await characteristic.write(Uint8List.fromList(chunk));

              setState(() {
                _progress = (i + 1) / totalChunks;
              });
            }

            String endMessage = "end";
            await characteristic
                .write(Uint8List.fromList(endMessage.codeUnits));
            print("Sent end message.");

            setState(() {
              _isUploading = false;
            });

            return;
          } catch (e) {
            print("Failed to send firmware: $e");
            setState(() {
              _isUploading = false;
            });
            return;
          }
        }
      }
    }
    print("No writable characteristic found.");
    setState(() {
      _isUploading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    if (_connectedDevice != null) {
      _connectedDevice!.disconnect();
    }
    _flutterBlue.stopScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan BLE Devices"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isScanning ? null : _scanForDevices,
              child: Text(_isScanning ? "Scanning..." : "Scan for Devices"),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devicesList.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = _devicesList[index];
                return ListTile(
                  title: Text(
                    device.name.isEmpty ? "No Name" : device.name,
                  ),
                  subtitle: Text(device.id.toString()),
                  trailing: _isConnected && _connectedDevice == device
                      ? ElevatedButton(
                          onPressed: () {
                            _connectedDevice!.disconnect();
                            setState(() {
                              _isConnected = false;
                              _connectedDevice = null;
                              _services.clear();
                            });
                          },
                          child: Text("Disconnect"),
                        )
                      : ElevatedButton(
                          onPressed: _isScanning
                              ? null
                              : () => _connectToDevice(device),
                          child: Text("Connect"),
                        ),
                );
              },
            ),
          ),
          if (_isConnected) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _checkFirmware,
                    child: Text("Check Firmware"),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _updateFirmWare,
                    child: Text("Update Firmware"),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ],
          if (_isUploading) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    "Uploading Firmware...",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _progress,
                    minHeight: 10,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "${(_progress * 100).toStringAsFixed(1)}%",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
