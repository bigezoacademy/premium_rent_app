import 'package:flutter/material.dart';

class ManagerDashboard extends StatefulWidget {
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
            icon: Icon(Icons.logout),
            onPressed: () {}, // TODO: Implement logout
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: selectedProperty == null
            ? _propertySelectionStep(context)
            : _propertyDashboard(context, selectedProperty!),
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
            String? newProperty = await showDialog<String>(
              context: context,
              builder: (context) {
                TextEditingController controller = TextEditingController();
                return AlertDialog(
                  title: Text('Add New Property'),
                  content: TextField(
                    controller: controller,
                    decoration: InputDecoration(hintText: 'Property Name'),
                  ),
                  actions: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      child: Text('Add'),
                      onPressed: () => Navigator.pop(context, controller.text),
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
          color: Color(0xFF8AC611),
          onTap: () {}, // TODO: Implement
        ),
        _dashboardCard(
          context,
          icon: Icons.category,
          title: 'Rental Categories',
          color: Color(0xFFC65611),
          onTap: () {}, // TODO: Implement
        ),
        _dashboardCard(
          context,
          icon: Icons.attach_money,
          title: 'Set Rent & Discounts',
          color: Colors.black,
          onTap: () {}, // TODO: Implement
        ),
        _dashboardCard(
          context,
          icon: Icons.receipt_long,
          title: 'Payments & Receipts',
          color: Color(0xFF8AC611),
          onTap: () {}, // TODO: Implement
        ),
        _dashboardCard(
          context,
          icon: Icons.analytics,
          title: 'Financial Analytics',
          color: Color(0xFFC65611),
          onTap: () {}, // TODO: Implement
        ),
        _dashboardCard(
          context,
          icon: Icons.email,
          title: 'Email & SMS Alerts',
          color: Colors.black,
          onTap: () {}, // TODO: Implement
        ),
        _dashboardCard(
          context,
          icon: Icons.storage,
          title: 'Lease Agreements',
          color: Color(0xFF8AC611),
          onTap: () {}, // TODO: Implement
        ),
        _dashboardCard(
          context,
          icon: Icons.warning,
          title: 'Overdue Reminders',
          color: Color(0xFFC65611),
          onTap: () {}, // TODO: Implement
        ),
        SizedBox(height: 24),
        TextButton(
          child: Text('Back to Property Selection'),
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
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        trailing: Icon(Icons.arrow_forward_ios, color: color),
        onTap: onTap,
      ),
    );
  }
}
