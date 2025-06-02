import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

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
    if (_error != null) return Center(child: Text('Error: \\$_error'));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6FBF4),
      appBar: AppBar(
        title: Text('Welcome'),
        backgroundColor: Color(0xFF8AC611),
        elevation: 0,
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
                            Text('WhatsApp: $whatsapp'),
                            SizedBox(height: 8),
                            Text('Email: $email'),
                          ],
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
                SizedBox(height: 24),
                Text('Or',
                    style: TextStyle(fontSize: 16, color: Colors.black54)),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.home, color: Colors.white),
                  label: Text('View Property Listings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8AC611),
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PropertyPublicListing()),
                    );
                  },
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
    return StreamBuilder<QuerySnapshot>(
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
          itemBuilder: (context, i) {
            final prop = properties[i];
            final data = prop.data() as Map<String, dynamic>;
            final photos = (data['photos'] as List?) ?? [];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: photos.isNotEmpty
                    ? SizedBox(
                        width: 64,
                        height: 64,
                        child: Image.network(photos[0], fit: BoxFit.cover),
                      )
                    : Icon(Icons.home, size: 48),
                title: Text(data['name'] ?? 'Property'),
                subtitle: Text(data['location'] ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyDetailsPage(
                        propertyData: data,
                        managerEmail: data['ownerEmail'] ?? '',
                        managerPhone: data['ownerPhone'] ?? '',
                        photos: photos,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class PropertyDetailsPage extends StatelessWidget {
  final Map<String, dynamic> propertyData;
  final String managerEmail;
  final String managerPhone;
  final List photos;
  const PropertyDetailsPage({
    required this.propertyData,
    required this.managerEmail,
    required this.managerPhone,
    required this.photos,
    Key? key,
  }) : super(key: key);

  void _openWhatsApp(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll('+', '').replaceAll(' ', '');
    final phoneUri = Uri.parse('https://wa.me/$cleanPhone');
    await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
  }

  void _showEmailDialog(BuildContext context, String email) async {
    final _formKey = GlobalKey<FormState>();
    TextEditingController subjectController = TextEditingController();
    TextEditingController messageController = TextEditingController();
    bool isSending = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Send Email'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: subjectController,
                  decoration: InputDecoration(labelText: 'Subject'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: messageController,
                  decoration: InputDecoration(labelText: 'Message'),
                  maxLines: 4,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: isSending
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Send'),
              onPressed: isSending
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() => isSending = true);
                        final smtpServer = SmtpServer(
                          'mail.privateemail.com',
                          username: 'admin@grealm.org',
                          password: 'JesusisLORD',
                          port: 465,
                          ssl: true,
                        );
                        final message = Message()
                          ..from = Address('admin@grealm.org', 'G-Realm Studio')
                          ..recipients.add(email)
                          ..subject = subjectController.text.trim()
                          ..text = messageController.text.trim();
                        try {
                          // Remove or use sendReport if not needed
                          await send(message, smtpServer);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Email sent successfully!')),
                          );
                        } catch (e) {
                          setState(() => isSending = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to send email: $e')),
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always show property manager details if available, fallback to owner only if manager is missing
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
    return Scaffold(
      appBar: AppBar(title: Text(propertyData['name'] ?? 'Property Details')),
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
              Text('Phone: $managerPhone'),
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
          if (photos.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Photos:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (context, i) => SizedBox(width: 12),
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(photos[i],
                          fit: BoxFit.cover, width: 300, height: 200),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
