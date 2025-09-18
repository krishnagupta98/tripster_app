// lib/widgets/add_trip_form.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddTripForm extends StatefulWidget {
  const AddTripForm({super.key});

  @override
  State<AddTripForm> createState() => _AddTripFormState();
}

class _AddTripFormState extends State<AddTripForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _locationSearchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _suggestions = [];
  latlong2.LatLng? _selectedCoordinates;
  bool _isSearching = false;

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _searchLocations(String query) async {
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
      });
      return;
    }
    setState(() {
      _isSearching = true;
    });
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1'),
        headers: {'User-Agent': 'TripsterApp/1.0'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _suggestions = data.map((item) => {
            'display_name': item['display_name'],
            'lat': double.parse(item['lat']),
            'lon': double.parse(item['lon']),
          }).toList();
          _isSearching = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search failed. Please try again.')),
        );
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search error: $e. Check your internet connection.')),
      );
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
    }
  }

  void _selectLocation(Map<String, dynamic> suggestion) {
    setState(() {
      _destinationController.text = suggestion['display_name'];
      _selectedCoordinates = latlong2.LatLng(suggestion['lat'], suggestion['lon']);
      _suggestions = [];
    });
  }

  Future<void> _showLocationMap() async {
    latlong2.LatLng? tempCoords;
    final result = await showDialog<latlong2.LatLng?>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          height: 400,
          width: 300,
          child: Column(
            children: [
              const Text('Tap to select location'),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _selectedCoordinates ?? latlong2.LatLng(37.7749, -122.4194),
                    initialZoom: _selectedCoordinates != null ? 10 : 2,
                    onTap: (tapPosition, point) {
                      setState(() {
                        tempCoords = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        if (tempCoords != null)
                          Marker(
                            point: tempCoords!,
                            child: const Icon(Icons.location_pin, color: Colors.red),
                          ),
                        if (_selectedCoordinates != null)
                          Marker(
                            point: _selectedCoordinates!,
                            child: const Icon(Icons.location_pin, color: Colors.blue),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, tempCoords),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedCoordinates = result;
        _getAddressFromCoordinates(result);
      });
    }
  }

  Future<void> _getAddressFromCoordinates(latlong2.LatLng coords) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${coords.latitude}&lon=${coords.longitude}&addressdetails=1'),
        headers: {'User-Agent': 'TripsterApp/1.0'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _destinationController.text = data['display_name'] ?? '${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}';
        });
      } else {
        setState(() {
          _destinationController.text = '${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reverse geocoding error: $e. Using coordinates.')),
      );
      setState(() {
        _destinationController.text = '${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}';
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both a start and end date.')),
        );
        return;
      }
      if (_destinationController.text.isEmpty || _selectedCoordinates == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a destination.')),
        );
        return;
      }
      
      final newTrip = Trip(
        name: _nameController.text,
        location: _destinationController.text,
        latitude: _selectedCoordinates!.latitude,
        longitude: _selectedCoordinates!.longitude,
        plannedDate: _startDate!,
        endDate: _endDate!,
        imageUrl: 'https://images.unsplash.com/photo-1473625247510-8ceb1760943f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2069&q=80',
        notes: "Your notes will appear here.",
        activities: ["Activity 1", "Activity 2"],
      );
      
      Navigator.of(context).pop(newTrip); // Return the new trip
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _locationSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Plan a New Trip", style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name of the Trip (e.g., Summer Vacation)'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _locationSearchController,
                    decoration: InputDecoration(
                      labelText: 'Search Destination',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _searchLocations(_locationSearchController.text),
                      ),
                    ),
                    onChanged: _searchLocations,
                  ),
                  if (_isSearching) const CircularProgressIndicator(),
                  if (_suggestions.isNotEmpty)
                    Container(
                      height: 150,
                      child: ListView.builder(
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return ListTile(
                            title: Text(suggestion['display_name']),
                            onTap: () => _selectLocation(suggestion),
                          );
                        },
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _showLocationMap,
                    icon: const Icon(Icons.map),
                    label: const Text('Select on Map'),
                  ),
                  if (_selectedCoordinates != null)
                    Text('Selected: ${_destinationController.text} (${_selectedCoordinates!.latitude.toStringAsFixed(4)}, ${_selectedCoordinates!.longitude.toStringAsFixed(4)})'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Start Date'),
                        child: Text(_startDate == null ? 'Select Date' : DateFormat.yMd().format(_startDate!)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'End Date'),
                        child: Text(_endDate == null ? 'Select Date' : DateFormat.yMd().format(_endDate!)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Save Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}