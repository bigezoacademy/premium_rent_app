import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:intl/intl.dart';

class TenantPropertySelector extends StatefulWidget {
  final String userEmail;
  final String userPhone;
  final String displayName;
  const TenantPropertySelector({
    required this.userEmail,
    required this.userPhone,
    required this.displayName,
    Key? key,
  }) : super(key: key);

  @override
  State<TenantPropertySelector> createState() => _TenantPropertySelectorState();
}

class _TenantPropertySelectorState extends State<TenantPropertySelector> {
  List<QueryDocumentSnapshot> _properties = [];
  bool _loading = true;
  String? _error;
  String? _debugInfo;

  @override
  void initState() {
    super.initState();
    _fetchTenantProperties();
  }

  Future<void> _fetchTenantProperties() async {
    setState(() {
      _loading = true;
      _error = null;
      _debugInfo = null;
    });
    try {
      final propsSnap =
          await FirebaseFirestore.instance.collection('properties').get();
      final List<QueryDocumentSnapshot> result = [];
      final String userEmail = widget.userEmail.trim().toLowerCase();
      final String userPhone = widget.userPhone.trim();
      String debug = '';
      for (final prop in propsSnap.docs) {
        final tenantsSnap = await prop.reference.collection('tenants').get();
        for (final tenant in tenantsSnap.docs) {
          final data = tenant.data() as Map<String, dynamic>;
          final tEmail = (data['email'] ?? '').toString().trim().toLowerCase();
          final tPhone = (data['phone'] ?? '').toString().trim();
          debug += '\nProperty: ${prop['name']}, Tenant: $tEmail / $tPhone';
          if ((tEmail.isNotEmpty && tEmail == userEmail) ||
              (tPhone.isNotEmpty && tPhone == userPhone)) {
            result.add(prop);
            break;
          }
        }
      }
      setState(() {
        _properties = result;
        _loading = false;
        if (result.isEmpty) _debugInfo = debug;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_properties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No properties assigned to you yet.'),
            if (_debugInfo != null) ...[
              SizedBox(height: 12),
              Text('Debug info:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Text(_debugInfo!, style: TextStyle(fontSize: 10)),
              ),
            ],
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Select Your Property')),
      body: ListView.builder(
        itemCount: _properties.length,
        itemBuilder: (context, i) {
          final prop = _properties[i];
          final data = prop.data() as Map<String, dynamic>;
          final photos = (data['photos'] as List?) ?? [];
          return Card(
            child: ListTile(
              leading: photos.isNotEmpty
                  ? Image.network(photos[0],
                      width: 56, height: 56, fit: BoxFit.cover)
                  : Icon(Icons.home, size: 56),
              title: Text(data['name'] ?? 'Property'),
              subtitle: Text(data['location'] ?? ''),
              onTap: () {
                setState(() {});
                // TODO: Navigate to tenant dashboard for this property
              },
            ),
          );
        },
      ),
    );
  }
}

class NewUserLandingPage extends StatelessWidget {
  final String whatsapp = '+256773913902';
  final String email = 'admin@grealm.org';
  const NewUserLandingPage({Key? key}) : super(key: key);

  void _openWhatsApp(BuildContext context, String phone) async {
    String cleanPhone = phone.trim();
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '+256' + cleanPhone.substring(1);
    }
    cleanPhone = cleanPhone.replaceAll('+', '').replaceAll(' ', '');
    final phoneUri = Uri.parse('https://wa.me/$cleanPhone');
    await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    String displayWhatsapp = whatsapp;
    if (displayWhatsapp.trim().startsWith('0')) {
      displayWhatsapp = '+256' + displayWhatsapp.trim().substring(1);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome'),
        backgroundColor: Color.fromARGB(255, 66, 170, 25),
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 16),
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  child:
                      Image.asset('assets/bigezo.png', width: 64, height: 64),
                ),
                SizedBox(height: 24),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text('Welcome to Premium Rent App!',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3B6939))),
                        SizedBox(height: 12),
                        Text(
                          'To create a Property Manager account, contact G-Realm Studio or view available property listings.',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: Icon(Icons.business, color: Colors.white),
                  label: Text('Create a Property Manager account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B6939),
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Contact G-Realm Studio'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('WhatsApp: $displayWhatsapp'),
                            SizedBox(height: 8),
                            Text('Email: $email'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            child: Text('Close'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: Text('Chat on WhatsApp'),
                            onPressed: () =>
                                _openWhatsApp(context, displayWhatsapp),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 24),
                Text('Or',
                    style: TextStyle(fontSize: 16, color: Colors.black54)),
                SizedBox(height: 16),
                ElevatedButtonTheme(
                  data: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.home, color: Colors.white),
                    label: Text('View Property Listings'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PropertyPublicListing()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PropertyPublicListing extends StatelessWidget {
  const PropertyPublicListing({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Properties',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 66, 170, 25),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Color(0xFFF6FBF4),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('properties').snapshots(),
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
            return ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              itemCount: properties.length,
              separatorBuilder: (context, i) => SizedBox(height: 24),
              itemBuilder: (context, i) {
                final prop = properties[i];
                final data = prop.data() as Map<String, dynamic>;
                final photos = (data['photos'] as List?) ?? [];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PropertyDetailsPage(
                          propertyData: data,
                          propertyId: prop.id, // <-- pass the Firestore doc ID
                          managerEmail: data['ownerEmail'] ?? '',
                          managerPhone: data['ownerPhone'] ?? '',
                          photos: photos,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: photos.isNotEmpty
                              ? Image.network(
                                  photos[0],
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 140,
                                  height: 140,
                                  color: Color(0xFFE0E0E0),
                                  child: Icon(Icons.home,
                                      size: 60, color: Colors.grey[600]),
                                ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? 'Property',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3B6939),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  data['location'] ?? '',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black87),
                                ),
                                if (data['rent'] != null) ...[
                                  SizedBox(height: 8),
                                  Text(
                                    'Rent: UGX ${formatAmount(data['rent'])}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFC65611),
                                    ),
                                  ),
                                ],
                                if (data['amenities'] != null &&
                                    data['amenities']
                                        .toString()
                                        .trim()
                                        .isNotEmpty) ...[
                                  SizedBox(height: 8),
                                  Text(
                                    'Amenities:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Color.fromARGB(255, 66, 170, 25)),
                                  ),
                                  Text(
                                    data['amenities'].toString(),
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.black54),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class PropertyDetailsPage extends StatefulWidget {
  final Map<String, dynamic> propertyData;
  final String propertyId;
  final String managerEmail;
  final String managerPhone;
  final List photos;
  const PropertyDetailsPage({
    required this.propertyData,
    required this.propertyId,
    required this.managerEmail,
    required this.managerPhone,
    required this.photos,
    Key? key,
  }) : super(key: key);

  @override
  _PropertyDetailsPageState createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> {
  List<Map<String, dynamic>> _facilities = [];
  bool _loadingFacilities = true;

  @override
  void initState() {
    super.initState();
    _fetchFacilities();
  }

  Future<void> _fetchFacilities() async {
    try {
      final propertyId = widget.propertyId;
      if (propertyId.isEmpty) {
        setState(() {
          _facilities = [];
          _loadingFacilities = false;
        });
        return;
      }
      final facilitiesSnapshot = await FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .collection('facilities')
          .get();
      setState(() {
        _facilities = facilitiesSnapshot.docs.map((doc) => doc.data()).toList();
        _loadingFacilities = false;
      });
    } catch (e) {
      print('Error fetching facilities: $e');
      setState(() {
        _facilities = [];
        _loadingFacilities = false;
      });
    }
  }

  void _showFacilityDetails(Map<String, dynamic> facility) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(facility['name'] ?? 'Facility Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: facility.entries
                .where((entry) =>
                    entry.key != 'name' &&
                    entry.key != 'rent' &&
                    entry.key != 'createdAt' &&
                    entry.key != 'propertyId')
                .map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.key}: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(entry.value.toString())),
                  ],
                ),
              );
            }).toList(),
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
  }

  void _showEmailDialog(BuildContext context, String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    await launchUrl(emailLaunchUri);
  }

  void _openWhatsApp(BuildContext context, String phone) async {
    String cleanPhone = phone.trim();
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '+256' + cleanPhone.substring(1);
    }
    cleanPhone = cleanPhone.replaceAll('+', '').replaceAll(' ', '');
    final phoneUri = Uri.parse('https://wa.me/$cleanPhone');
    await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final propertyData = widget.propertyData;
    final managerName = propertyData['managerName'] ??
        propertyData['manager'] ??
        propertyData['ownerName'] ??
        'Property Manager';
    final managerEmail = propertyData['managerEmail'] ??
        propertyData['manager_email'] ??
        propertyData['ownerEmail'] ??
        '';
    final managerPhone = propertyData['managerPhone'] ??
        propertyData['manager_phone'] ??
        propertyData['ownerPhone'] ??
        '';
    String displayWhatsapp = managerPhone;
    if (displayWhatsapp.trim().startsWith('0')) {
      displayWhatsapp = '+256' + displayWhatsapp.trim().substring(1);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(propertyData['name'] ?? 'Property Details',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 66, 170, 25),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Property details at the top
          Text(propertyData['name'] ?? '',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(propertyData['location'] ?? ''),
          SizedBox(height: 16),
          if (propertyData['amenities'] != null &&
              propertyData['amenities'].toString().trim().isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amenities:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(propertyData['amenities'].toString()),
                SizedBox(height: 16),
              ],
            ),
          Text('Contact Property Manager:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Row(
            children: [
              Text('Name: $managerName'),
            ],
          ),
          Row(
            children: [
              Text('Email: $managerEmail'),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.email, color: Colors.blue),
                tooltip: 'Send Email',
                onPressed: () => _showEmailDialog(context, managerEmail),
              ),
            ],
          ),
          Row(
            children: [
              Text('Phone: $displayWhatsapp'),
              SizedBox(width: 8),
              IconButton(
                icon:
                    FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366)),
                tooltip: 'Chat on WhatsApp',
                onPressed: () => _openWhatsApp(context, managerPhone),
              ),
            ],
          ),
          SizedBox(height: 24),
          // All property photos below details
          if (widget.photos.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Photos:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.photos.length,
                    separatorBuilder: (context, i) => SizedBox(width: 12),
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(widget.photos[i],
                          fit: BoxFit.cover, width: 300, height: 200),
                    ),
                  ),
                ),
              ],
            ),
          SizedBox(height: 24),
          // Facilities section (only unoccupied)
          if (_loadingFacilities)
            Center(child: CircularProgressIndicator())
          else
            (() {
              // Filter only unoccupied facilities
              final unoccupied = _facilities.where((facility) {
                // Consider unoccupied if 'occupied' is false or null, or 'tenant' is null/empty
                final occupied = facility['occupied'];
                final tenant = facility['tenant'];
                return (occupied == null || occupied == false) &&
                    (tenant == null ||
                        (tenant is String && tenant.trim().isEmpty));
              }).toList();

              // Only show facilities whose "status" is exactly "unoccupied"
              final unoccupiedFacilities = unoccupied.where((facility) {
                final status =
                    (facility['status'] ?? '').toString().toLowerCase();
                return status == 'unoccupied';
              }).toList();

              if (unoccupiedFacilities.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Un-occupied Facilities:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: const Color.fromARGB(255, 8, 113, 199),
                      ),
                    ),
                    SizedBox(height: 12),
                    Table(
                      columnWidths: {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                      },
                      border: TableBorder.all(color: Colors.grey[300]!),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Color(0xFFF6FBF4)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Facility/Room',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Rent',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                          ],
                        ),
                        ...unoccupiedFacilities.map((facility) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Text(
                                      facility['number'] ?? 'Facility',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Color.fromARGB(255, 66, 170, 25),
                                        foregroundColor: Colors.white,
                                        minimumSize: Size(60, 32),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 0),
                                        textStyle: TextStyle(fontSize: 13),
                                      ),
                                      child: Text('Details'),
                                      onPressed: () =>
                                          _showFacilityDetails(facility),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  facility['rent'] != null
                                      ? 'UGX ' +
                                          NumberFormat('#,##0')
                                              .format(facility['rent'])
                                      : '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown[800],
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                    SizedBox(height: 24),
                  ],
                );
              } else {
                return Builder(
                  builder: (context) {
                    print(
                        'No unoccupied facilities/rooms listed for this property.');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'No unoccupied facilities/rooms listed for this property.',
                            style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 24),
                      ],
                    );
                  },
                );
              }
            })(),
        ],
      ),
    );
  }
}

String formatAmount(dynamic amount) {
  if (amount == null) return '';
  try {
    final num value = amount is num ? amount : num.parse(amount.toString());
    return NumberFormat('#,##0').format(value);
  } catch (_) {
    return amount.toString();
  }
}
