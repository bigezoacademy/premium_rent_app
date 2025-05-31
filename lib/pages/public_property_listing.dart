import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicPropertyListingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text('Available Properties'),
        backgroundColor: Color(0xFF3B6939),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('properties').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading properties'));
          }
          final properties = snapshot.data?.docs ?? [];
          if (properties.isEmpty) {
            return Center(child: Text('No properties available.'));
          }
          return ListView.builder(
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final doc = properties[index];
              final data = doc.data() as Map<String, dynamic>;
              final photos = (data['photos'] as List?)?.cast<String>() ?? [];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
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
    );
  }
}
