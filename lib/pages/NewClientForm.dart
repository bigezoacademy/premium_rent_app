// ignore: file_names
import 'package:premium_rent_app/database_insert.dart';
import 'package:flutter/material.dart';
import 'AppLayout.dart';

import 'package:flutter/material.dart';
import 'AppLayout.dart';
import '../propertiesManager.dart'; // Updated import to new file

class NewClientForm extends StatefulWidget {
  @override
  _NewClientFormState createState() => _NewClientFormState();
}

class _NewClientFormState extends State<NewClientForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController roomController = TextEditingController();

  List<Map<String, dynamic>> _properties = [];
  String? _selectedProperty;

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
      if (_properties.isNotEmpty) {
        _selectedProperty = _properties.first['name'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
        body: ListView(
      padding: const EdgeInsets.all(30.0),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Contact',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextFormField(
                style: TextStyle(
                    color: Color.fromARGB(255, 0, 103, 181),
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold),
                controller: nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the client\'s name';
                  }
                  return null;
                },
                decoration: InputDecoration(labelText: 'Client\'s Name'),
              ),
              TextFormField(
                style: TextStyle(
                    color: Color.fromARGB(255, 0, 103, 181),
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold),
                controller: phoneController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the client\'s phone number';
                  }
                  return null;
                },
                decoration: InputDecoration(labelText: 'Phone'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedProperty,
                items: _properties.map((property) {
                  return DropdownMenuItem<String>(
                    value: property['name'],
                    child: Text(property['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProperty = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Apartment'),
                style: TextStyle(
                    color: Color.fromARGB(255, 0, 103, 181),
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold),
              ),
              TextFormField(
                style: TextStyle(
                    color: Color.fromARGB(255, 0, 103, 181),
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold),
                controller: roomController,
                decoration: InputDecoration(labelText: 'Room number'),
              ),
              SizedBox(height: 25),
              Container(
                color: Color.fromARGB(255, 14, 93, 178),
                child: TextButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _addClient(context);
                      }
                    },
                    icon: Icon(
                      Icons.add,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                    label: Text(
                      "Add Client",
                      style:
                          TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                    )),
              )
            ],
          ),
        ),
      ],
    ));
  }

  void _addClient(BuildContext context) async {
    Map<String, dynamic> client = {
      'name': nameController.text,
      'phone': phoneController.text,
      'apartment': _selectedProperty ?? '',
      'room': roomController.text,
    };

    try {
      int clientId = await DatabaseHelperInsert.instance.insertClient(client);

      if (clientId != -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Client added successfully!'),
          ),
        );

        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add client. Please try again.'),
          ),
        );
      }
    } catch (e) {
      print('Error adding client: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred.  $e'),
        ),
      );
    }
  }

  void _resetForm() {
    nameController.clear();
    phoneController.clear();
    roomController.clear();
    setState(() {
      _selectedProperty =
          _properties.isNotEmpty ? _properties.first['name'] : null;
    });
  }
}
