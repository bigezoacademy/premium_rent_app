import 'package:flutter/material.dart';
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
  String? selectedProperty;
  List<String> properties = [
    'Sunset Apartments',
    'Greenview Villas',
    'Downtown Lofts',
  ]; // TODO: Replace with Firestore fetch

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
              child: selectedProperty == null
                  ? _propertySelectionStep(context)
                  : _propertyDashboard(context, selectedProperty!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _propertySelectionStep(BuildContext context) {
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
          onPressed: () async {
            String? property = await showDialog<String>(
              context: context,
              builder: (context) => SimpleDialog(
                title: Text('Select Property'),
                children: properties
                    .map((prop) => SimpleDialogOption(
                          child: Text(prop),
                          onPressed: () => Navigator.pop(context, prop),
                        ))
                    .toList(),
              ),
            );
            if (property != null) {
              setState(() {
                selectedProperty = property;
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
            TextEditingController locationController = TextEditingController();
            TextEditingController ownerEmailController =
                TextEditingController();
            TextEditingController ownerNameController = TextEditingController();
            TextEditingController ownerPhoneController =
                TextEditingController();
            String? newProperty = await showDialog<String>(
              context: context,
              builder: (context) {
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
                            decoration:
                                InputDecoration(hintText: 'Property Name'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: locationController,
                            decoration: InputDecoration(hintText: 'Location'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: ownerNameController,
                            decoration: InputDecoration(hintText: 'Owner Name'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: ownerEmailController,
                            decoration:
                                InputDecoration(hintText: 'Owner Email'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: ownerPhoneController,
                            decoration:
                                InputDecoration(hintText: 'Owner Phone'),
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.trim().isEmpty
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
                      child: Text('Add'),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // You can collect all fields here for Firestore
                          Navigator.pop(context, nameController.text);
                        }
                      },
                    ),
                  ],
                );
              },
            );
            if (newProperty != null && newProperty.trim().isNotEmpty) {
              setState(() {
                properties.add(newProperty.trim());
                selectedProperty = newProperty.trim();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _propertyDashboard(BuildContext context, String property) {
    return ListView(
      children: [
        _dashboardHeader(
            'Managing: $property', 'Oversee property, billing, and analytics.'),
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
              selectedProperty = null;
            });
          },
        ),
      ],
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
