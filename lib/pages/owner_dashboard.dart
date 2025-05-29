import 'package:flutter/material.dart';
import '../auth_service.dart';
import '../main.dart';

class OwnerDashboard extends StatelessWidget {
  final VoidCallback? onLogout;
  const OwnerDashboard({Key? key, this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Property Owner Dashboard'),
        backgroundColor: Color(0xFF8AC611),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
              if (onLogout != null) {
                onLogout!();
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => AuthHomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          _dashboardHeader('Welcome, Owner!',
              'View analytics and revenue for your properties.'),
          const SizedBox(height: 24),
          _dashboardCard(
            context,
            icon: Icons.analytics,
            title: 'Financial Analytics',
            color: const Color(0xFFC65611),
            onTap: () {}, // TODO: Implement
          ),
          _dashboardCard(
            context,
            icon: Icons.bar_chart,
            title: 'Monthly Rent Collected',
            color: const Color(0xFFC65611),
            onTap: () {}, // TODO: Implement
          ),
          _dashboardCard(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Manager Revenue Tracking',
            color: const Color(0xFFC65611),
            onTap: () {}, // TODO: Implement
          ),
          _dashboardCard(
            context,
            icon: Icons.info_outline,
            title: 'Property Performance',
            color: const Color(0xFFC65611),
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
      Color? color,
      required VoidCallback onTap}) {
    final Color iconColor = color ?? const Color(0xFFC65611);
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        trailing: Icon(Icons.arrow_forward_ios, color: iconColor),
        onTap: onTap,
      ),
    );
  }
}
