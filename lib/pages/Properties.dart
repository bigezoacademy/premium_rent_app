import 'package:flutter/material.dart';
import 'AppLayout.dart';
import '../propertiesManager.dart'; // Import your properties manager

class Properties extends StatefulWidget {
  @override
  _PropertiesState createState() => _PropertiesState();
}

class _PropertiesState extends State<Properties> {
  List<Map<String, dynamic>> _properties = [];
  bool _isAddingNewProperty =
      false; // Track whether to show the new property form
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    List<Map<String, dynamic>> properties =
        await PropertiesManager.instance.getProperties();
    setState(() {
      _properties = properties;
    });
  }

  Future<void> _deleteProperty(int id) async {
    await PropertiesManager.instance.deleteProperty(id);
    _loadProperties(); // Refresh the list after deletion
  }

  Future<void> _addProperty() async {
    final name = _nameController.text;
    final location = _locationController.text;

    if (name.isNotEmpty && location.isNotEmpty) {
      await PropertiesManager.instance.insertProperty({
        'name': name,
        'location': location,
      });
      _nameController.clear();
      _locationController.clear();
      setState(() {
        _isAddingNewProperty = false; // Hide form after submission
      });
      _loadProperties(); // Refresh the list after adding
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill out both fields.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isAddingNewProperty =
                      !_isAddingNewProperty; // Toggle between adding new property and showing properties list
                });
              },
              child: Text(
                  _isAddingNewProperty ? 'Show Properties' : 'New Property'),
            ),
            SizedBox(height: 20),
            if (_isAddingNewProperty) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Property Name'),
                    ),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(labelText: 'Location'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _addProperty,
                      child: Text('Submit'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Expanded(
                child: ListView.builder(
                  itemCount: _properties.length,
                  itemBuilder: (context, index) {
                    final property = _properties[index];
                    return ListTile(
                      title: Text(property['name']),
                      subtitle: Text(property['location']),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteProperty(property['id']);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
