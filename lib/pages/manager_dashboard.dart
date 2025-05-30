import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth_service.dart';
import '../../main.dart';

// Custom Material 3 color palette with #3b6939 as main color
const Color m3Primary = Color(0xFF3B6939); // Main green
const Color m3OnPrimary = Color(0xFFFFFFFF); // On Primary
const Color m3Secondary =
    Color.fromARGB(255, 80, 255, 129); // Harmonized green secondary
const Color m3OnSecondary = Color(0xFFFFFFFF); // On Secondary
const Color m3Background = Color(0xFFF6FBF4); // Light green-tinted background
const Color m3Surface = Color(0xFFF6FBF4); // Surface
const Color m3OnSurface = Color(0xFF1C1B1F); // On Surface
const Color m3Error = Color(0xFFB3261E); // Error
const Color m3OnError = Color(0xFFFFFFFF); // On Error
const Color m3Outline = Color(0xFFB5C9B8); // Muted green outline

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
  bool _isBusy = false; // For global progress overlay

  void _showBusy([bool value = true]) {
    setState(() => _isBusy = value);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: m3Background,
          appBar: AppBar(
            title: Text('Property Manager Dashboard'),
            backgroundColor: m3Primary,
            foregroundColor: m3OnPrimary,
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: m3Error),
                onPressed: widget.onLogout ??
                    () async {
                      await AuthService().signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AuthHomeScreen()),
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
                          color: m3Primary)),
                  SizedBox(height: 4),
                  Text(widget.userEmail!,
                      style: TextStyle(fontSize: 16, color: m3Secondary)),
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
        ),
        if (_isBusy)
          ModalBarrier(
              dismissible: false, color: Colors.black.withOpacity(0.2)),
        if (_isBusy)
          Center(
            child: Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(blurRadius: 16, color: Colors.black12)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: m3Primary),
                  SizedBox(height: 16),
                  Text('Please wait...', style: TextStyle(color: m3Primary)),
                ],
              ),
            ),
          ),
      ],
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
                    color: m3Primary)),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: m3Primary,
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
                                              color: m3Primary),
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
                String? categoryValue;
                String? kitchenValue;
                bool isLoading = false;
                await showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setStateDialog) {
                        return AlertDialog(
                          backgroundColor: m3Surface,
                          titleTextStyle: TextStyle(
                              color: m3Primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
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
                                  SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    decoration:
                                        InputDecoration(hintText: 'Category'),
                                    value: categoryValue,
                                    items: [
                                      DropdownMenuItem(
                                          value: 'Residential Rentals',
                                          child: Text('Residential Rentals')),
                                      DropdownMenuItem(
                                          value: 'Shop Rentals',
                                          child: Text('Shop Rentals')),
                                      DropdownMenuItem(
                                          value: 'Residential Apartments',
                                          child:
                                              Text('Residential Apartments')),
                                      DropdownMenuItem(
                                          value: 'Mall Commercial Spaces',
                                          child:
                                              Text('Mall Commercial Spaces')),
                                    ],
                                    onChanged: (val) {
                                      setStateDialog(() {
                                        categoryValue = val;
                                        // Reset kitchen value if category changes
                                        if (categoryValue !=
                                                'Residential Rentals' &&
                                            categoryValue !=
                                                'Residential Apartments') {
                                          kitchenValue = null;
                                        }
                                      });
                                    },
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                  SizedBox(height: 8),
                                  if (categoryValue == 'Residential Rentals' ||
                                      categoryValue == 'Residential Apartments')
                                    DropdownButtonFormField<String>(
                                      decoration:
                                          InputDecoration(hintText: 'Kitchen'),
                                      value: kitchenValue,
                                      items: [
                                        DropdownMenuItem(
                                            value: 'Yes', child: Text('Yes')),
                                        DropdownMenuItem(
                                            value: 'No', child: Text('No')),
                                      ],
                                      onChanged: (val) {
                                        setStateDialog(() {
                                          kitchenValue = val;
                                        });
                                      },
                                      validator: (v) => v == null || v.isEmpty
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: m3Primary,
                                foregroundColor: m3OnPrimary,
                              ),
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
                                        _showBusy(true);
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
                                            'category': categoryValue,
                                            'kitchen': (categoryValue ==
                                                        'Residential Rentals' ||
                                                    categoryValue ==
                                                        'Residential Apartments')
                                                ? kitchenValue
                                                : null,
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
                                        } finally {
                                          _showBusy(false);
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
    TextEditingController categoryController =
        TextEditingController(text: doc['category'] ?? '');
    TextEditingController kitchenController =
        TextEditingController(text: doc['kitchen'] ?? '');
    bool isLoading = false;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: m3Surface,
              titleTextStyle: TextStyle(
                  color: m3Primary, fontWeight: FontWeight.bold, fontSize: 20),
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
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(hintText: 'Category'),
                        value: doc['category'],
                        items: [
                          DropdownMenuItem(
                              value: 'Residential Rentals',
                              child: Text('Residential Rentals')),
                          DropdownMenuItem(
                              value: 'Shop Rentals',
                              child: Text('Shop Rentals')),
                          DropdownMenuItem(
                              value: 'Residential Apartments',
                              child: Text('Residential Apartments')),
                          DropdownMenuItem(
                              value: 'Mall Commercial Spaces',
                              child: Text('Mall Commercial Spaces')),
                        ],
                        onChanged: (val) {
                          setStateDialog(() {
                            categoryController.text = val ?? '';
                          });
                        },
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      if (categoryController.text == 'Residential Rentals' ||
                          categoryController.text == 'Residential Apartments')
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(hintText: 'Kitchen'),
                          value: kitchenController.text.isNotEmpty
                              ? kitchenController.text
                              : null,
                          items: [
                            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                            DropdownMenuItem(value: 'No', child: Text('No')),
                          ],
                          onChanged: (val) {
                            setStateDialog(() {
                              kitchenController.text = val ?? '';
                            });
                          },
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: m3Primary,
                    foregroundColor: m3OnPrimary,
                  ),
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
                            _showBusy(true);
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
                                'category': categoryController.text,
                                'kitchen': (categoryController.text ==
                                            'Residential Rentals' ||
                                        categoryController.text ==
                                            'Residential Apartments')
                                    ? kitchenController.text
                                    : null,
                              });
                              Navigator.pop(context);
                            } catch (e) {
                              setStateDialog(() => isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Failed to update property: $e')),
                              );
                            } finally {
                              _showBusy(false);
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
        final category = data?['category'] ?? '';
        final ownerName = data?['ownerName'] ?? '';
        final ownerEmail = data?['ownerEmail'] ?? '';
        final ownerPhone = data?['ownerPhone'] ?? '';
        // final kitchen = data?['kitchen'] ?? '';
        return ListView(
          children: [
            _dashboardHeader(
                'Managing: $propertyName',
                (location.isNotEmpty ? 'Location: $location\n' : '') +
                    (category.isNotEmpty ? 'Category: $category\n' : '') +
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
              onTap: () {
                if (selectedPropertyId != null) {
                  FirebaseFirestore.instance
                      .collection('properties')
                      .doc(selectedPropertyId)
                      .get()
                      .then((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    final category = data?['category'] ?? '';
                    if (category.isNotEmpty) {
                      _showSetRentAndDiscountsDialog(
                          context, selectedPropertyId!, category);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Property category missing...')),
                      );
                    }
                  });
                }
              },
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
                fontSize: 28, fontWeight: FontWeight.bold, color: m3Primary)),
        SizedBox(height: 8),
        Text(subtitle, style: TextStyle(fontSize: 16, color: m3Secondary)),
      ],
    );
  }

  Widget _dashboardCard(BuildContext context,
      {required IconData icon,
      required String title,
      Color? color,
      required VoidCallback onTap}) {
    final Color iconColor = color ?? m3Secondary;
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 12),
      color: m3Surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: m3OnSurface)),
        trailing: Icon(Icons.arrow_forward_ios, color: iconColor),
        onTap: onTap,
      ),
    );
  }

  void _showSetRentAndDiscountsDialog(
      BuildContext context, String propertyId, String category) async {
    final _formKey = GlobalKey<FormState>();
    // Controllers for all possible fields
    TextEditingController rentController = TextEditingController();
    TextEditingController depositController = TextEditingController();
    TextEditingController leaseDurationController = TextEditingController();
    TextEditingController discountValueController = TextEditingController();
    TextEditingController serviceChargeController = TextEditingController();
    TextEditingController sizeController = TextEditingController();
    TextEditingController bedroomsController = TextEditingController();
    TextEditingController bathroomsController = TextEditingController();
    TextEditingController amenitiesController = TextEditingController();
    TextEditingController floorLevelController = TextEditingController();
    TextEditingController visibilityController = TextEditingController();
    TextEditingController footTrafficController = TextEditingController();
    String? discountType;
    String? kitchen;
    String? furnished;
    String? parking;
    String? utilities;
    String? balcony;
    String? powerBackup;
    String? anchorProximity;
    bool isLoading = false;
    // Load existing data
    final doc = await FirebaseFirestore.instance
        .collection('properties')
        .doc(propertyId)
        .get();
    final data = doc.data() ?? {};
    rentController.text = data['rent']?.toString() ?? '';
    depositController.text = data['deposit']?.toString() ?? '';
    leaseDurationController.text = data['leaseDuration']?.toString() ?? '';
    discountType = data['discountType'];
    discountValueController.text = data['discountValue']?.toString() ?? '';
    serviceChargeController.text = data['serviceCharge']?.toString() ?? '';
    sizeController.text = data['size']?.toString() ?? '';
    bedroomsController.text = data['bedrooms']?.toString() ?? '';
    bathroomsController.text = data['bathrooms']?.toString() ?? '';
    kitchen = data['kitchen'];
    furnished = data['furnished'];
    parking = data['parking'];
    utilities = data['utilities'];
    balcony = data['balcony'];
    amenitiesController.text = data['amenities'] ?? '';
    floorLevelController.text = data['floorLevel'] ?? '';
    visibilityController.text = data['visibility'] ?? '';
    powerBackup = data['powerBackup'];
    anchorProximity = data['anchorProximity'];
    footTrafficController.text = data['footTraffic']?.toString() ?? '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Set Rent & Discounts'),
              titleTextStyle: TextStyle(
                  color: m3Primary, fontWeight: FontWeight.bold, fontSize: 20),
              backgroundColor: m3Surface,
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: rentController,
                        decoration: InputDecoration(
                            labelText: 'Base Rent Amount (per month)'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: depositController,
                        decoration:
                            InputDecoration(labelText: 'Security Deposit'),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: leaseDurationController,
                        decoration: InputDecoration(
                            labelText: 'Lease Duration (months)'),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Discount Type'),
                        value: discountType,
                        items: [
                          DropdownMenuItem(value: 'None', child: Text('None')),
                          DropdownMenuItem(
                              value: 'Percentage', child: Text('Percentage')),
                          DropdownMenuItem(
                              value: 'Fixed', child: Text('Fixed Amount')),
                        ],
                        onChanged: (val) =>
                            setStateDialog(() => discountType = val),
                      ),
                      SizedBox(height: 8),
                      if (discountType != null && discountType != 'None')
                        TextFormField(
                          controller: discountValueController,
                          decoration:
                              InputDecoration(labelText: 'Discount Value'),
                          keyboardType: TextInputType.number,
                        ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: serviceChargeController,
                        decoration:
                            InputDecoration(labelText: 'Service Charge'),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 8),
                      if (category == 'Residential Rentals' ||
                          category == 'Residential Apartments') ...[
                        TextFormField(
                          controller: bedroomsController,
                          decoration:
                              InputDecoration(labelText: 'Number of Bedrooms'),
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: bathroomsController,
                          decoration:
                              InputDecoration(labelText: 'Number of Bathrooms'),
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(labelText: 'Has Kitchen'),
                          value: kitchen,
                          items: [
                            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                            DropdownMenuItem(value: 'No', child: Text('No')),
                          ],
                          onChanged: (val) =>
                              setStateDialog(() => kitchen = val),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(labelText: 'Furnished'),
                          value: furnished,
                          items: [
                            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                            DropdownMenuItem(value: 'No', child: Text('No'))
                          ],
                          onChanged: (val) =>
                              setStateDialog(() => furnished = val),
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration:
                              InputDecoration(labelText: 'Parking Included'),
                          value: parking,
                          items: [
                            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                            DropdownMenuItem(value: 'No', child: Text('No'))
                          ],
                          onChanged: (val) =>
                              setStateDialog(() => parking = val),
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration:
                              InputDecoration(labelText: 'Utilities Included'),
                          value: utilities,
                          items: [
                            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                            DropdownMenuItem(value: 'No', child: Text('No'))
                          ],
                          onChanged: (val) =>
                              setStateDialog(() => utilities = val),
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(labelText: 'Balcony'),
                          value: balcony,
                          items: [
                            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                            DropdownMenuItem(value: 'No', child: Text('No'))
                          ],
                          onChanged: (val) =>
                              setStateDialog(() => balcony = val),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: amenitiesController,
                          decoration: InputDecoration(
                              labelText: 'Amenities (comma separated)'),
                        ),
                      ],
                      if (category == 'Shop Rentals') ...[
                        TextFormField(
                          controller: sizeController,
                          decoration: InputDecoration(
                              labelText: 'Shop Size (sq. meters)'),
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: floorLevelController,
                          decoration: InputDecoration(labelText: 'Floor Level'),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: visibilityController,
                          decoration: InputDecoration(labelText: 'Visibility'),
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration:
                              InputDecoration(labelText: 'Power Backup'),
                          value: powerBackup,
                          items: [
                            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                            DropdownMenuItem(value: 'No', child: Text('No'))
                          ],
                          onChanged: (val) =>
                              setStateDialog(() => powerBackup = val),
                        ),
                      ],
                      if (category == 'Mall Commercial Spaces') ...[
                        TextFormField(
                          controller: sizeController,
                          decoration: InputDecoration(
                              labelText: 'Unit Size (sq. meters)'),
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: floorLevelController,
                          decoration: InputDecoration(labelText: 'Floor Level'),
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                              labelText: 'Anchor Tenant Proximity'),
                          value: anchorProximity,
                          items: [
                            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                            DropdownMenuItem(value: 'No', child: Text('No'))
                          ],
                          onChanged: (val) =>
                              setStateDialog(() => anchorProximity = val),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: footTrafficController,
                          decoration: InputDecoration(
                              labelText: 'Foot Traffic Estimate'),
                          keyboardType: TextInputType.number,
                        ),
                      ],
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: m3Primary,
                    foregroundColor: m3OnPrimary,
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Save'),
                  onPressed: () async {
                    if (isLoading) return;
                    if (_formKey.currentState!.validate()) {
                      try {
                        isLoading = true;
                        _showBusy(true);
                        await FirebaseFirestore.instance
                            .collection('properties')
                            .doc(propertyId)
                            .update({
                          'rent': rentController.text.trim(),
                          'deposit': depositController.text.trim(),
                          'leaseDuration': leaseDurationController.text.trim(),
                          'discountType': discountType,
                          'discountValue': discountValueController.text.trim(),
                          'serviceCharge': serviceChargeController.text.trim(),
                          // Category-specific
                          'bedrooms': bedroomsController.text.trim(),
                          'bathrooms': bathroomsController.text.trim(),
                          'kitchen': (category == 'Residential Rentals' ||
                                  category == 'Residential Apartments')
                              ? kitchen
                              : null,
                          'furnished': furnished,
                          'parking': parking,
                          'utilities': utilities,
                          'balcony': balcony,
                          'amenities': amenitiesController.text.trim(),
                          'size': sizeController.text.trim(),
                          'floorLevel': floorLevelController.text.trim(),
                          'visibility': visibilityController.text.trim(),
                          'powerBackup': powerBackup,
                          'anchorProximity': anchorProximity,
                          'footTraffic': footTrafficController.text.trim(),
                        });
                        Navigator.pop(context);
                      } catch (e) {
                        isLoading = false;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Failed to save rent details: $e')),
                        );
                      } finally {
                        _showBusy(false);
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
}
