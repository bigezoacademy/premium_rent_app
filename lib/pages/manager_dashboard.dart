import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth_service.dart';
import '../../main.dart';

class ManagerDashboard extends StatefulWidget {
  final VoidCallback? onLogout;
  const ManagerDashboard(
      {Key? key, this.onLogout, this.userName, this.userEmail})
      : super(key: key);
  final String? userName;
  final String? userEmail;
  @override
  _ManagerDashboardState createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  String? selectedPropertyId;
  String? selectedPropertyName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Property Manager Dashboard'),
        backgroundColor: Color(0xFF8AC611),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Color(0xFFC65611)),
            onPressed: widget.onLogout ??
                () async {
                  await AuthService().signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => AuthHomeScreen()),
                    (route) => false,
                  );
                },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.userName != null && widget.userEmail != null) ...[
              Text('Welcome, ${widget.userName}!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8AC611))),
              SizedBox(height: 4),
              Text(widget.userEmail!,
                  style: TextStyle(fontSize: 16, color: Colors.black54)),
              SizedBox(height: 24),
            ],
            Expanded(
              child: selectedPropertyId == null
                  ? _propertySelectionStep(context)
                  : _propertyDashboard(context, selectedPropertyName ?? ''),
            ),
          ],
        ),
      ),
    );
  }

  Widget _propertySelectionStep(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('properties')
          .orderBy('name', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading properties'));
        }
        final properties = snapshot.data?.docs ?? [];
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Manage a Property',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8AC611))),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8AC611),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                elevation: 0,
              ),
              child: Text('Choose Property'),
              onPressed: properties.isEmpty
                  ? null
                  : () async {
                      final property = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (context) => SimpleDialog(
                          title: Text('Select Property'),
                          children: properties
                              .map((doc) => SimpleDialogOption(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                            child:
                                                Text(doc['name'] ?? 'Unnamed')),
                                        IconButton(
                                          icon: Icon(Icons.edit,
                                              color: Color(0xFF8AC611)),
                                          tooltip: 'Edit',
                                          onPressed: () async {
                                            Navigator.pop(
                                                context); // Close dialog
                                            await _editPropertyDialog(
                                                context, doc);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.red),
                                          tooltip: 'Delete',
                                          onPressed: () async {
                                            Navigator.pop(
                                                context); // Close dialog
                                            await _deleteProperty(
                                                context, doc.id, doc['name']);
                                          },
                                        ),
                                      ],
                                    ),
                                    onPressed: () => Navigator.pop(context, {
                                      'id': doc.id,
                                      'name': doc['name'],
                                    }),
                                  ))
                              .toList(),
                        ),
                      );
                      if (property != null) {
                        setState(() {
                          selectedPropertyId = property['id'];
                          selectedPropertyName = property['name'];
                        });
                      }
                    },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFC65611),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                elevation: 0,
              ),
              child: Text('Add New Property'),
              onPressed: () async {
                final _formKey = GlobalKey<FormState>();
                TextEditingController nameController = TextEditingController();
                TextEditingController locationController =
                    TextEditingController();
                TextEditingController ownerEmailController =
                    TextEditingController();
                TextEditingController ownerNameController =
                    TextEditingController();
                TextEditingController ownerPhoneController =
                    TextEditingController();
                bool isLoading = false;
                await showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setStateDialog) {
                        return AlertDialog(
                          title: Text('Add New Property'),
                          content: Form(
                            key: _formKey,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                    controller: nameController,
                                    decoration: InputDecoration(
                                        hintText: 'Property Name'),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Required'
                                            : null,
                                  ),
                                  SizedBox(height: 8),
                                  TextFormField(
                                    controller: locationController,
                                    decoration:
                                        InputDecoration(hintText: 'Location'),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Required'
                                            : null,
                                  ),
                                  SizedBox(height: 8),
                                  TextFormField(
                                    controller: ownerNameController,
                                    decoration:
                                        InputDecoration(hintText: 'Owner Name'),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Required'
                                            : null,
                                  ),
                                  SizedBox(height: 8),
                                  TextFormField(
                                    controller: ownerEmailController,
                                    decoration: InputDecoration(
                                        hintText: 'Owner Email'),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Required'
                                            : null,
                                  ),
                                  SizedBox(height: 8),
                                  TextFormField(
                                    controller: ownerPhoneController,
                                    decoration: InputDecoration(
                                        hintText: 'Owner Phone'),
                                    keyboardType: TextInputType.phone,
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Required'
                                            : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text('Cancel'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            ElevatedButton(
                              child: isLoading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Text('Add'),
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      if (_formKey.currentState!.validate()) {
                                        setStateDialog(() => isLoading = true);
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('properties')
                                              .add({
                                            'name': nameController.text.trim(),
                                            'location':
                                                locationController.text.trim(),
                                            'ownerName':
                                                ownerNameController.text.trim(),
                                            'ownerEmail': ownerEmailController
                                                .text
                                                .trim(),
                                            'ownerPhone': ownerPhoneController
                                                .text
                                                .trim(),
                                            'createdAt':
                                                FieldValue.serverTimestamp(),
                                          });
                                          Navigator.pop(context);
                                        } catch (e) {
                                          setStateDialog(
                                              () => isLoading = false);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Failed to add property: $e')),
                                          );
                                        }
                                      }
                                    },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _editPropertyDialog(
      BuildContext context, QueryDocumentSnapshot doc) async {
    final _formKey = GlobalKey<FormState>();
    TextEditingController nameController =
        TextEditingController(text: doc['name']);
    TextEditingController locationController =
        TextEditingController(text: doc['location']);
    TextEditingController ownerNameController =
        TextEditingController(text: doc['ownerName']);
    TextEditingController ownerEmailController =
        TextEditingController(text: doc['ownerEmail']);
    TextEditingController ownerPhoneController =
        TextEditingController(text: doc['ownerPhone']);
    bool isLoading = false;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Edit Property'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(hintText: 'Property Name'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: locationController,
                        decoration: InputDecoration(hintText: 'Location'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: ownerNameController,
                        decoration: InputDecoration(hintText: 'Owner Name'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: ownerEmailController,
                        decoration: InputDecoration(hintText: 'Owner Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: ownerPhoneController,
                        decoration: InputDecoration(hintText: 'Owner Phone'),
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Save'),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setStateDialog(() => isLoading = true);
                            try {
                              await FirebaseFirestore.instance
                                  .collection('properties')
                                  .doc(doc.id)
                                  .update({
                                'name': nameController.text.trim(),
                                'location': locationController.text.trim(),
                                'ownerName': ownerNameController.text.trim(),
                                'ownerEmail': ownerEmailController.text.trim(),
                                'ownerPhone': ownerPhoneController.text.trim(),
                              });
                              Navigator.pop(context);
                            } catch (e) {
                              setStateDialog(() => isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Failed to update property: $e')),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteProperty(
      BuildContext context, String docId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Property'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('properties')
            .doc(docId)
            .delete();
        if (selectedPropertyId == docId) {
          setState(() {
            selectedPropertyId = null;
            selectedPropertyName = null;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete property: $e')),
        );
      }
    }
  }

  Widget _propertyDashboard(BuildContext context, String propertyName) {
    return StreamBuilder<DocumentSnapshot>(
      stream: selectedPropertyId == null
          ? null
          : FirebaseFirestore.instance
              .collection('properties')
              .doc(selectedPropertyId)
              .snapshots(),
      builder: (context, snapshot) {
        if (selectedPropertyId == null) {
          return Center(child: Text('No property selected'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('Error loading property details'));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final location = data?['location'] ?? '';
        final ownerName = data?['ownerName'] ?? '';
        final ownerEmail = data?['ownerEmail'] ?? '';
        final ownerPhone = data?['ownerPhone'] ?? '';
        return ListView(
          children: [
            _dashboardHeader(
                'Managing: $propertyName',
                (location.isNotEmpty ? 'Location: $location\n' : '') +
                    (ownerName.isNotEmpty ? 'Owner: $ownerName\n' : '') +
                    (ownerEmail.isNotEmpty ? 'Email: $ownerEmail\n' : '') +
                    (ownerPhone.isNotEmpty ? 'Phone: $ownerPhone\n' : '') +
                    'Oversee property, billing, and analytics.'),
            SizedBox(height: 24),
            _dashboardCard(
              context,
              icon: Icons.apartment,
              title: 'Manage Units',
              onTap: () {}, // TODO: Implement
            ),
            _dashboardCard(
              context,
              icon: Icons.category,
              title: 'Rental Categories',
              onTap: () {}, // TODO: Implement
            ),
            _dashboardCard(
              context,
              icon: Icons.attach_money,
              title: 'Set Rent & Discounts',
              onTap: () {}, // TODO: Implement
            ),
            _dashboardCard(
              context,
              icon: Icons.receipt_long,
              title: 'Payments & Receipts',
              onTap: () {}, // TODO: Implement
            ),
            _dashboardCard(
              context,
              icon: Icons.analytics,
              title: 'Financial Analytics',
              onTap: () {}, // TODO: Implement
            ),
            _dashboardCard(
              context,
              icon: Icons.email,
              title: 'Email & SMS Alerts',
              onTap: () {}, // TODO: Implement
            ),
            _dashboardCard(
              context,
              icon: Icons.storage,
              title: 'Lease Agreements',
              onTap: () {}, // TODO: Implement
            ),
            _dashboardCard(
              context,
              icon: Icons.warning,
              title: 'Overdue Reminders',
              onTap: () {}, // TODO: Implement
            ),
            SizedBox(height: 24),
            TextButton(
              child: Text('Back to Property Selection',
                  style: TextStyle(fontFamily: 'Trebuchet MS')),
              onPressed: () {
                setState(() {
                  selectedPropertyId = null;
                  selectedPropertyName = null;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _dashboardHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8AC611))),
        SizedBox(height: 8),
        Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.black54)),
      ],
    );
  }

  Widget _dashboardCard(BuildContext context,
      {required IconData icon,
      required String title,
      Color? color,
      required VoidCallback onTap}) {
    final Color iconColor = color ?? Color(0xFFC65611);
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        trailing: Icon(Icons.arrow_forward_ios, color: iconColor),
        onTap: onTap,
      ),
    );
  }
}
