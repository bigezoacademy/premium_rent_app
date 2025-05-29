import 'package:flutter/material.dart';

class ManagerDashboard extends StatelessWidget {
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
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          _dashboardHeader('Welcome, Manager!',
              'Oversee properties, billing, and analytics.'),
          SizedBox(height: 24),
          _dashboardCard(
            context,
            icon: Icons.apartment,
            title: 'Manage Properties',
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
        ],
      ),
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
