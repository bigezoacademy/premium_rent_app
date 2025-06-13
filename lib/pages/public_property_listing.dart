import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicPropertyListingPage extends StatefulWidget {
  @override
  _PublicPropertyListingPageState createState() =>
      _PublicPropertyListingPageState();
}

class _PublicPropertyListingPageState extends State<PublicPropertyListingPage> {
  String? selectedCategory;
  String searchQuery = '';
  final List<String> propertyTypes = [
    'All',
    'Rental Apartments',
    'Residential Rentals',
    'Shop Rentals',
    'Residential Apartments',
    'Mall Commercial Spaces',
    // Add more as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text('Available Properties'),
        backgroundColor: Color.fromARGB(255, 21, 136, 54),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Filter icon and dropdown
                Container(
                  width: 48,
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.filter_list,
                        color: Color.fromARGB(255, 21, 136, 54)),
                    tooltip: 'Filter by property type',
                    onSelected: (val) {
                      setState(
                          () => selectedCategory = val == 'All' ? null : val);
                    },
                    itemBuilder: (context) => propertyTypes
                        .map((type) => PopupMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                  ),
                ),
                SizedBox(width: 8),
                // Search field
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by location or property name',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Color(0xFF002366), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Color(0xFF002366), width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Color(0xFF002366), width: 2),
                      ),
                    ),
                    onChanged: (val) =>
                        setState(() => searchQuery = val.trim().toLowerCase()),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('properties')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading properties'));
                }
                final properties = snapshot.data?.docs ?? [];
                final filtered = properties.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final location =
                      (data['location'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? '').toString();
                  final matchesCategory =
                      selectedCategory == null || category == selectedCategory;
                  final matchesSearch = searchQuery.isEmpty ||
                      name.contains(searchQuery) ||
                      location.contains(searchQuery);
                  return matchesCategory && matchesSearch;
                }).toList();
                if (filtered.isEmpty) {
                  return Center(child: Text('No properties available.'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final photos =
                        (data['photos'] as List?)?.cast<String>() ?? [];
                    return Card(
                      margin:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: photos.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  photos[0],
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey[300],
                                child: Icon(Icons.home,
                                    size: 40, color: Colors.grey[600]),
                              ),
                        title: Text(data['name'] ?? 'Unnamed',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data['location'] != null)
                              Text('Location: ${data['location']}'),
                            if (data['category'] != null)
                              Text('Category: ${data['category']}'),
                            if (data['managerName'] != null)
                              Text('Manager: ${data['managerName']}'),
                            if (data['managerEmail'] != null)
                              Text('Email: ${data['managerEmail']}'),
                            if (data['managerPhone'] != null)
                              Text('Phone: ${data['managerPhone']}'),
                          ],
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(data['name'] ?? 'Property Details'),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (photos.isNotEmpty)
                                      SizedBox(
                                        height: 180,
                                        child: PageView.builder(
                                          itemCount: photos.length,
                                          itemBuilder: (context, i) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                photos[i],
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: 180,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    SizedBox(height: 8),
                                    if (data['location'] != null)
                                      Text('Location: ${data['location']}'),
                                    if (data['category'] != null)
                                      Text('Category: ${data['category']}'),
                                    if (data['managerName'] != null)
                                      Text('Manager: ${data['managerName']}'),
                                    if (data['managerEmail'] != null)
                                      Text('Email: ${data['managerEmail']}'),
                                    if (data['managerPhone'] != null)
                                      Text('Phone: ${data['managerPhone']}'),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  child: Text('Close'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
