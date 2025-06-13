import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../auth_service.dart';
import '../main.dart';

class TenantDashboard extends StatefulWidget {
  final VoidCallback? onLogout;
  final String? userId;
  final String? userEmail;
  const TenantDashboard({Key? key, this.onLogout, this.userId, this.userEmail})
      : super(key: key);

  @override
  State<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends State<TenantDashboard> {
  String? selectedFacilityId;
  Map<String, dynamic>? selectedFacility;
  Map<String, dynamic>? selectedProperty;

  @override
  Widget build(BuildContext context) {
    print(
        '[DEBUG] TenantDashboard build: userId=[32m[1m[4m[7m${widget.userId}[0m, userEmail=${widget.userEmail}');
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = widget.userId ?? currentUser?.uid;
    final email = widget.userEmail ?? currentUser?.email;
    if (uid == null && email == null) {
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(),
          title: Text('Tenant Dashboard'),
          backgroundColor: Colors.black,
        ),
        body: Center(child: Text('No user found. Please log in again.')),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BackButton(),
        title: Text('Tenant Dashboard'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().signOut();
              if (widget.onLogout != null) {
                widget.onLogout!();
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
      body: selectedFacilityId == null
          ? _buildFacilityList(context, uid ?? '', email)
          : _buildTenantFacilityDashboard(context),
    );
  }

  Widget _buildFacilityList(BuildContext context, String uid, String? email) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('properties').get(),
      builder: (context, propSnap) {
        if (propSnap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (propSnap.hasError) {
          return Center(child: Text('Error loading properties'));
        }
        final properties = propSnap.data?.docs ?? [];
        List<Map<String, dynamic>> myFacilities = [];
        for (final prop in properties) {
          final propData = prop.data() as Map<String, dynamic>;
          final propId = prop.id;
          // Removed unused tenantsSnap variable
          myFacilities.add({
            'propertyId': propId,
            'propertyName': propData['name'] ?? '',
            'propertyManagerPhone':
                propData['ownerPhone'] ?? propData['managerPhone'] ?? '',
            'propertyManagerEmail':
                propData['ownerEmail'] ?? propData['managerEmail'] ?? '',
            'propertyManagerName':
                propData['ownerName'] ?? propData['managerName'] ?? '',
            'propertyDoc': prop,
          });
        }
        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            Text('Your Facilities',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            SizedBox(height: 16),
            ...properties.map((prop) {
              final propData = prop.data() as Map<String, dynamic>;
              return FutureBuilder<QuerySnapshot>(
                future: prop.reference
                    .collection('tenants')
                    .where('email', isEqualTo: email)
                    .get(),
                builder: (context, tenantSnap) {
                  if (tenantSnap.connectionState == ConnectionState.waiting) {
                    return SizedBox();
                  }
                  final tenants = tenantSnap.data?.docs ?? [];
                  if (tenants.isEmpty) return SizedBox();
                  return Column(
                    children: tenants.map((tenantDoc) {
                      final tenantData =
                          tenantDoc.data() as Map<String, dynamic>;
                      final facilityNumber = tenantData['facilityNumber'] ?? '';
                      return Card(
                        color: Colors.green[50],
                        child: ListTile(
                          leading:
                              Icon(Icons.meeting_room, color: Colors.green),
                          title: Text('Room $facilityNumber',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(propData['name'] ?? '',
                              style: TextStyle(color: Colors.black)),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Manage'),
                            onPressed: () {
                              setState(() {
                                selectedFacilityId = tenantDoc.id;
                                selectedFacility = tenantData;
                                selectedProperty = propData;
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              selectedFacilityId = tenantDoc.id;
                              selectedFacility = tenantData;
                              selectedProperty = propData;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildTenantFacilityDashboard(BuildContext context) {
    final facility = selectedFacility ?? {};
    final property = selectedProperty ?? {};
    final managerPhone =
        property['ownerPhone'] ?? property['managerPhone'] ?? '';
    final managerEmail =
        property['ownerEmail'] ?? property['managerEmail'] ?? '';
    final managerName = property['ownerName'] ?? property['managerName'] ?? '';
    final facilityNumber =
        facility['facilityNumber'] ?? facility['number'] ?? '';
    final facilityId = selectedFacilityId;
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.black,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(),
              },
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Facility/Room',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20.0, top: 8.0, bottom: 8.0),
                      child: Text(
                        '$facilityNumber',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 85, 195, 123),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Monthly Rent',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20.0, top: 8.0, bottom: 8.0),
                      child: Text(
                        'UGX ${_formatAmount(facility['rent'])}',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 85, 195, 123),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Property',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20.0, top: 8.0, bottom: 8.0),
                      child: Text(
                        property['name'] ?? '',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 85, 195, 123),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Manager',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20.0, top: 8.0, bottom: 8.0),
                      child: Text(
                        managerName,
                        style: TextStyle(
                          color: const Color.fromARGB(255, 85, 195, 123),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Phone',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20.0, top: 8.0, bottom: 8.0),
                      child: Text(
                        managerPhone,
                        style: TextStyle(
                          color: const Color.fromARGB(255, 85, 195, 123),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Email',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20.0, top: 8.0, bottom: 8.0),
                      child: Text(
                        managerEmail,
                        style: TextStyle(
                          color: const Color.fromARGB(255, 85, 195, 123),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.payment, color: Colors.white),
              label: Text('Pay Rent', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                // TODO: Implement rent payment logic
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Rent payment coming soon!')),
                );
              },
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.history, color: Colors.white),
              label: Text('Payment History',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                // TODO: Implement payment history logic
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment history coming soon!')),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 24),
        Text('Contact Manager',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 18)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(FontAwesomeIcons.whatsapp,
                  color: Colors.green, size: 32),
              tooltip: 'WhatsApp',
              onPressed: () async {
                if (managerPhone.isNotEmpty) {
                  String cleanPhone = managerPhone.trim();
                  if (cleanPhone.startsWith('0')) {
                    cleanPhone = '+256' + cleanPhone.substring(1);
                  } else if (!cleanPhone.startsWith('+256')) {
                    cleanPhone =
                        '+256' + cleanPhone.replaceAll(RegExp(r'^\+?'), '');
                  }
                  cleanPhone =
                      cleanPhone.replaceAll('+', '').replaceAll(' ', '');
                  final url = 'https://wa.me/$cleanPhone';
                  if (await canLaunch(url)) {
                    await launch(url);
                  }
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.email, color: Colors.green, size: 32),
              tooltip: 'Email',
              onPressed: () async {
                if (managerEmail.isNotEmpty) {
                  final url = 'mailto:$managerEmail';
                  if (await canLaunch(url)) {
                    await launch(url);
                  }
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.phone, color: Colors.green, size: 32),
              tooltip: 'Call',
              onPressed: () async {
                if (managerPhone.isNotEmpty) {
                  final url = 'tel:$managerPhone';
                  if (await canLaunch(url)) {
                    await launch(url);
                  }
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.sms, color: Colors.green, size: 32),
              tooltip: 'SMS',
              onPressed: () async {
                if (managerPhone.isNotEmpty) {
                  final url = 'sms:$managerPhone';
                  if (await canLaunch(url)) {
                    await launch(url);
                  }
                }
              },
            ),
          ],
        ),
        SizedBox(height: 24),
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('payments')
              .where('facilityId', isEqualTo: facilityId)
              .get(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error loading stats'));
            }
            final payments = snap.data?.docs ?? [];
            double totalPaid = 0;
            double totalUnpaid = 0;
            for (final p in payments) {
              final d = p.data() as Map<String, dynamic>;
              totalPaid += double.tryParse(d['amount']?.toString() ?? '0') ?? 0;
            }
            // For demo, assume rent is in facility['rent']
            final rent =
                double.tryParse(facility['rent']?.toString() ?? '0') ?? 0;
            totalUnpaid = rent > 0 ? (rent - totalPaid) : 0;
            return Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Statistics',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 18)),
                    SizedBox(height: 8),
                    Text('Total Paid: UGX ${totalPaid.toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.black)),
                    Text('Total Unpaid: UGX ${totalUnpaid.toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(height: 24),
        TextButton(
          child:
              Text('Back to Facilities', style: TextStyle(color: Colors.green)),
          onPressed: () {
            setState(() {
              selectedFacilityId = null;
              selectedFacility = null;
              selectedProperty = null;
            });
          },
        ),
      ],
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return 'N/A';
    try {
      final num value =
          amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
      return NumberFormat('#,##0').format(value);
    } catch (e) {
      return amount.toString();
    }
  }
}

class TenantPropertyDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot propertyDoc;
  final String? tenantEmail;
  const TenantPropertyDetailPage(
      {Key? key, required this.propertyDoc, this.tenantEmail})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = propertyDoc.data() as Map<String, dynamic>;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text(data['name'] ?? 'Property Details'),
        backgroundColor: Color.fromARGB(255, 66, 170, 25),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${data['location'] ?? ''}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Category: ${data['category'] ?? ''}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Manager: ${data['managerName'] ?? ''}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Manager Email: ${data['managerEmail'] ?? ''}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Manager Phone: ${data['managerPhone'] ?? ''}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 24),
            Divider(),
            Text('Tenant Dashboard',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.payment),
                  label: Text('Pay Rent'),
                  onPressed: () {
                    // TODO: Implement rent payment logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Rent payment coming soon!')),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.email),
                  label: Text('Contact Manager'),
                  onPressed: () {
                    // TODO: Implement email launch
                    final emailUri = Uri(
                      scheme: 'mailto',
                      path: data['managerEmail'] ?? '',
                      query:
                          'subject=Tenant Inquiry&body=Hello, I am your tenant.',
                    );
                    launchUrl(emailUri);
                  },
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.description),
                  label: Text('View Lease'),
                  onPressed: () {
                    // TODO: Implement lease viewing
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lease viewing coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
