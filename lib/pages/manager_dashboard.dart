import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'SendSms.dart';
// import 'package:send_sms/send_sms.dart';
// import 'send_sms_page.dart';
import '../../auth_service.dart';
import '../../main.dart';

// Custom Material 3 color palette with #3b6939 as main color
const Color m3Primary = Color.fromARGB(255, 34, 157, 30); // Main green
const Color m3OnPrimary = Color(0xFFFFFFFF); // On Primary
const Color m3Secondary =
    Color.fromARGB(255, 94, 94, 94); // Harmonized green secondary
const Color m3OnSecondary = Color(0xFFFFFFFF); // On Secondary
const Color m3Background = Color(0xFFF6FBF4); // Light green-tinted background
const Color m3Surface = Color(0xFFF6FBF4); // Surface
const Color m3OnSurface = Color(0xFF1C1B1F); // On Surface
const Color m3Error = Color(0xFFB3261E); // Error
const Color m3OnError = Color(0xFFFFFFFF); // On Error
const Color m3Outline =
    Color.fromARGB(255, 205, 160, 64); // Muted green outline
const Color m3Grey = Color.fromARGB(255, 75, 75, 75); // Shadow color

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
  bool showTenantDatabase = false;
  List<Map<String, dynamic>> _propertyCache = [];

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
                icon: Icon(Icons.logout, color: m3Secondary), // light green
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
                      style: TextStyle(fontSize: 16, color: m3Grey)),
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

  // Email sending logic using Namecheap privateemail SMTP
  Future<void> sendEmail({
    required String toEmail,
    required String subject,
    required String body,
  }) async {
    final smtpServer = SmtpServer(
      'mail.privateemail.com',
      port: 465,
      ssl: true,
      username: 'admin@grealm.org',
      password: 'JesusisLORD',
    );
    final message = Message()
      ..from = Address('admin@grealm.org', 'G-Realm Studio')
      ..recipients.add(toEmail)
      ..subject = subject
      ..text = body;
    try {
      final sendReport = await send(message, smtpServer);
      print('Email sent: ' + sendReport.toString());
    } catch (e) {
      print('Email send error: $e');
      rethrow;
    }
  }

  Widget _propertySelectionStep(BuildContext context) {
    final userEmail = widget.userEmail;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('properties')
          .where('managerEmail', isEqualTo: userEmail)
          .orderBy('name', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          print('[ManagerDashboard] Error loading properties:');
          print(snapshot.error);
          if (snapshot.stackTrace != null) print(snapshot.stackTrace);
          // Show UI with disabled dropdown and enabled Add Property button
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
              DropdownButton<String>(
                value: null,
                hint: Text('Choose Property'),
                items: [],
                onChanged: null, // Disabled
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFC65611),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  // TODO: Implement add property dialog or navigation
                },
                child: Text('Add New Property'),
              ),
              SizedBox(height: 16),
              Center(
                  child: Text('Error loading properties',
                      style: TextStyle(color: Colors.red))),
            ],
          );
        }
        final properties = snapshot.data?.docs ?? [];
        // Update local cache for dashboard property lookup
        _propertyCache = properties.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your Properties',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: m3Primary)),
            SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: properties.length,
                separatorBuilder: (_, __) => SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final doc = properties[idx];
                  final data = doc.data() as Map<String, dynamic>;
                  return buildPropertyCard(
                    data,
                    () {
                      setState(() {
                        selectedPropertyId = doc.id;
                        selectedPropertyName = data['name'] ?? '';
                      });
                    },
                    () {
                      _editPropertyDialog(context, doc);
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.add, color: Colors.white),
              label: Text('Add New Property'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFC65611),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                elevation: 0,
              ),
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
                bool isLoading = false;
                List<XFile> selectedImages = [];
                int uploadProgress = 0;
                await showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setState) {
                        Future<void> pickImages() async {
                          final ImagePicker picker = ImagePicker();
                          final List<XFile> images =
                              await picker.pickMultiImage();
                          if (images.length > 5) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'You can only select up to 5 images.')),
                            );
                            setState(() {
                              selectedImages = images.sublist(0, 5);
                            });
                          } else {
                            setState(() {
                              selectedImages = images;
                            });
                          }
                        }

                        Future<List<String>> uploadImages(
                            List<XFile> images) async {
                          List<String> urls = [];
                          int completed = 0;
                          for (var img in images) {
                            final ref = FirebaseStorage.instance.ref(
                              'property_photos/${DateTime.now().millisecondsSinceEpoch}_${img.name}',
                            );
                            final uploadTask =
                                ref.putData(await img.readAsBytes());
                            uploadTask.snapshotEvents.listen((event) {
                              setState(() {
                                uploadProgress = ((completed +
                                            event.bytesTransferred /
                                                (event.totalBytes > 0
                                                    ? event.totalBytes
                                                    : 1)) /
                                        images.length *
                                        100)
                                    .toInt();
                              });
                            });
                            await uploadTask;
                            final url = await ref.getDownloadURL();
                            urls.add(url);
                            completed++;
                            setState(() {
                              uploadProgress =
                                  ((completed / images.length) * 100).toInt();
                            });
                          }
                          return urls;
                        }

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
                                          value: 'Residential Apartments',
                                          child:
                                              Text('Residential Apartments')),
                                      DropdownMenuItem(
                                          value: 'Shop Rentals',
                                          child: Text('Shop Rentals')),
                                      DropdownMenuItem(
                                          value: 'Mall Commercial Spaces',
                                          child:
                                              Text('Mall Commercial Spaces')),
                                    ],
                                    onChanged: (val) =>
                                        setState(() => categoryValue = val),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                  SizedBox(height: 8),
                                  if (categoryValue == 'Residential Rentals' ||
                                      categoryValue == 'Residential Apartments')
                                    DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                          hintText: 'Has Kitchen'),
                                      value: null,
                                      items: [
                                        DropdownMenuItem(
                                            value: 'Yes', child: Text('Yes')),
                                        DropdownMenuItem(
                                            value: 'No', child: Text('No')),
                                      ],
                                      onChanged: (val) => setState(() {}),
                                      validator: (v) => v == null || v.isEmpty
                                          ? 'Required'
                                          : null,
                                    ),
                                  SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text('Property Photos (max 5):'),
                                  ),
                                  SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      ...selectedImages.map((img) =>
                                          Image.network(img.path,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover)),
                                      if (selectedImages.length < 5)
                                        GestureDetector(
                                          onTap: pickImages,
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border:
                                                  Border.all(color: m3Primary),
                                            ),
                                            child: Icon(Icons.add_a_photo,
                                                color: m3Primary),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (isLoading)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Column(
                                        children: [
                                          LinearProgressIndicator(
                                              value: uploadProgress / 100),
                                          SizedBox(height: 4),
                                          Text('Uploading... $uploadProgress%'),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: m3Primary,
                                foregroundColor: m3OnPrimary,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() => isLoading = true);
                                        _showBusy(true);
                                        try {
                                          List<String> photoUrls = [];
                                          if (selectedImages.isNotEmpty) {
                                            photoUrls = await uploadImages(
                                                selectedImages);
                                          }
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
                                                ? null
                                                : null,
                                            'managerEmail': widget.userEmail,
                                            'photos': photoUrls,
                                            'createdAt':
                                                FieldValue.serverTimestamp(),
                                          });
                                          Navigator.pop(context);
                                        } catch (e) {
                                          setState(() => isLoading = false);
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
                              child: Text('Add'),
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
    bool isLoading = false;
    List<String> currentPhotoUrls = List<String>.from(doc['photos'] ?? []);
    List<XFile> selectedImages = [];
    List<String> uploadedPhotoUrls = List<String>.from(currentPhotoUrls);
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickImages() async {
              final ImagePicker picker = ImagePicker();
              final List<XFile> images = await picker.pickMultiImage();
              if (images.length + uploadedPhotoUrls.length > 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('You can only select up to 5 images in total.')),
                );
                setState(() {
                  selectedImages =
                      images.sublist(0, 5 - uploadedPhotoUrls.length);
                });
              } else {
                setState(() {
                  selectedImages = images;
                });
              }
            }

            Future<List<String>> uploadImages(List<XFile> images) async {
              List<String> urls = [];
              for (var img in images) {
                final ref = FirebaseStorage.instance.ref(
                    'property_photos/${DateTime.now().millisecondsSinceEpoch}_${img.name}');
                await ref.putData(await img.readAsBytes());
                final url = await ref.getDownloadURL();
                urls.add(url);
              }
              return urls;
            }

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
                          setState(() {
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
                          value: null,
                          items: [
                            DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                            DropdownMenuItem(value: 'No', child: Text('No')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              // kitchenController.text = val ?? '';
                            });
                          },
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Property Photos (max 5):'),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ...uploadedPhotoUrls.map((url) => Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Image.network(url,
                                      width: 60, height: 60, fit: BoxFit.cover),
                                  IconButton(
                                    icon: Icon(Icons.cancel,
                                        color: Colors.red, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    onPressed: () {
                                      setState(() {
                                        uploadedPhotoUrls.remove(url);
                                      });
                                    },
                                  ),
                                ],
                              )),
                          ...selectedImages.map((img) => Image.network(img.path,
                              width: 60, height: 60, fit: BoxFit.cover)),
                          if (uploadedPhotoUrls.length + selectedImages.length <
                              5)
                            IconButton(
                              icon: Icon(Icons.add_a_photo, color: m3Primary),
                              onPressed: pickImages,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: m3Primary,
                    foregroundColor: m3OnPrimary,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => isLoading = true);
                            try {
                              // Remove facility update logic from here
                              // Only update property fields and photos
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
                                    ? null
                                    : null,
                                'photos': uploadedPhotoUrls,
                              });
                              Navigator.pop(context);
                            } catch (e) {
                              setState(() => isLoading = false);
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
                  child: Text('Save'),
                ),
                TextButton(
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    // Confirm delete
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Property'),
                        content: Text(
                            'Are you sure you want to delete this property? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                          TextButton(
                            child: Text('Delete',
                                style: TextStyle(color: Colors.red)),
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      // ...existing delete logic...
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Property'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(docId)
          .delete();
      setState(() {
        selectedPropertyId = null;
        selectedPropertyName = null;
      });
    }
  }

  // Property Dashboard (fix: use correct property details)
  Widget _propertyDashboard(BuildContext context, String propertyName) {
    final property = _getSelectedProperty();
    final location = property?['location'] ?? '';
    final category = property?['category'] ?? '';
    final ownerName = property?['ownerName'] ?? '';
    final ownerEmail = property?['ownerEmail'] ?? '';
    final ownerPhone = property?['ownerPhone'] ?? '';
    final subtitle = (location.isNotEmpty ? 'Location: $location\n' : '') +
        (category.isNotEmpty ? 'Category: $category\n' : '') +
        (ownerName.isNotEmpty ? 'Owner: $ownerName\n' : '') +
        (ownerEmail.isNotEmpty ? 'Email: $ownerEmail\n' : '') +
        (ownerPhone.isNotEmpty ? 'Phone: $ownerPhone\n' : '') +
        'Oversee property, billing, and analytics.';
    return ListView(
      children: [
        Card(
          color: Colors.black, // Changed from brownish to black
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(propertyName,
                    style: TextStyle(
                        color: Color(0xFF8AC611), // Light green
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(subtitle,
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        Row(
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.people, color: Colors.white),
              label: Text('Tenant Database'),
              style: ElevatedButton.styleFrom(
                backgroundColor: m3Primary,
                foregroundColor: m3OnPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TenantDatabasePage(
                      propertyId: selectedPropertyId!,
                      propertyName: selectedPropertyName ?? '',
                      onAddTenant: () => _addTenantDialog(
                          context, selectedPropertyId!,
                          propertyName: selectedPropertyName ?? ''),
                    ),
                  ),
                );
              },
            ),
            Spacer(),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.person_add, color: Colors.white),
              label: Text('Add Tenant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: m3Primary,
                foregroundColor: m3OnPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () {
                _addTenantDialog(context, selectedPropertyId!,
                    propertyName: selectedPropertyName ?? '');
              },
            ),
            Spacer(),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _dashboardCard(
                context,
                icon: Icons.meeting_room,
                title: 'Facilities/Rooms',
                color: m3Secondary,
                onTap: () {
                  if (selectedPropertyId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FacilitiesPage(
                          propertyId: selectedPropertyId!,
                          propertyName: selectedPropertyName ?? '',
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
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
          onTap: () async {
            if (selectedPropertyId == null) return;
            _showBusy(true);
            try {
              final propertyDoc = await FirebaseFirestore.instance
                  .collection('properties')
                  .doc(selectedPropertyId)
                  .get();
              final propertyData = propertyDoc.data() as Map<String, dynamic>?;
              if (propertyData == null) {
                _showBusy(false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No property data found.')),
                );
                return;
              }
              // Fetch tenants from nested collection
              final tenantsSnap = await FirebaseFirestore.instance
                  .collection('properties')
                  .doc(selectedPropertyId)
                  .collection('tenants')
                  .get();
              int tenantCount = tenantsSnap.docs.length;
              int male =
                  tenantsSnap.docs.where((t) => t['gender'] == 'Male').length;
              int female =
                  tenantsSnap.docs.where((t) => t['gender'] == 'Female').length;
              // Fetch payments for this property (if needed, adjust collection path)
              final paymentsSnap = await FirebaseFirestore.instance
                  .collection('payments')
                  .where('propertyId', isEqualTo: selectedPropertyId)
                  .get();
              double totalRent = 0;
              double totalPaid = 0;
              for (var doc in paymentsSnap.docs) {
                final data = doc.data() as Map<String, dynamic>;
                totalPaid +=
                    double.tryParse(data['amount']?.toString() ?? '0') ?? 0;
              }
              totalRent = tenantCount *
                  (double.tryParse(propertyData['rent']?.toString() ?? '0') ??
                      0);
              double outstanding = totalRent - totalPaid;
              _showBusy(false);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Financial Analytics'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Tenants: $tenantCount'),
                      Text('Male: $male'),
                      Text('Female: $female'),
                      SizedBox(height: 8),
                      Text(
                          'Total Rent Due: UGX${totalRent.toStringAsFixed(2)}'),
                      SizedBox(height: 8),
                      Text('Total Paid: UGX${totalPaid.toStringAsFixed(2)}'),
                      SizedBox(height: 8),
                      Text('Outstanding: UGX${outstanding.toStringAsFixed(2)}'),
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
            } catch (e) {
              _showBusy(false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to load analytics: $e')),
              );
            }
          },
        ),
        _dashboardCard(
          context,
          icon: Icons.email,
          title: 'Email & SMS Alerts',
          color: m3Secondary,
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
              showTenantDatabase = false;
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
          builder: (context, setState) {
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
                            labelText: 'Base Rent Amount (/month)'),
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
                          DropdownMenuItem(
                              value: 'Percentage', child: Text('Percentage')),
                          DropdownMenuItem(
                              value: 'Fixed', child: Text('Fixed Amount')),
                        ],
                        onChanged: (val) => setState(() => discountType = val),
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
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Has Kitchen'),
                        value: kitchen,
                        items: [
                          DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                          DropdownMenuItem(value: 'No', child: Text('No')),
                        ],
                        onChanged: (val) => setState(() => kitchen = val),
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
                        onChanged: (val) => setState(() => furnished = val),
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
                        onChanged: (val) => setState(() => parking = val),
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
                        onChanged: (val) => setState(() => utilities = val),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Balcony'),
                        value: balcony,
                        items: [
                          DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                          DropdownMenuItem(value: 'No', child: Text('No'))
                        ],
                        onChanged: (val) => setState(() => balcony = val),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: amenitiesController,
                        decoration: InputDecoration(
                            labelText: 'Amenities (comma separated)'),
                      ),
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
                            DropdownMenuItem(value: 'No', child: Text('No')),
                          ],
                          onChanged: (val) => setState(() => powerBackup = val),
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
                            DropdownMenuItem(value: 'No', child: Text('No')),
                          ],
                          onChanged: (val) =>
                              setState(() => anchorProximity = val),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: footTrafficController,
                          decoration: InputDecoration(
                              labelText: 'Foot Traffic Estimate'),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: m3Primary,
                    foregroundColor: m3OnPrimary,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => isLoading = true);
                            _showBusy(true);
                            try {
                              await FirebaseFirestore.instance
                                  .collection('properties')
                                  .doc(propertyId)
                                  .update({
                                'rent': rentController.text.trim(),
                                'deposit': depositController.text.trim(),
                                'leaseDuration':
                                    leaseDurationController.text.trim(),
                                'discountType': discountType,
                                'discountValue':
                                    discountValueController.text.trim(),
                                'serviceCharge':
                                    serviceChargeController.text.trim(),
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
                                'anchorProximity': anchorProximity,
                                'footTraffic':
                                    footTrafficController.text.trim(),
                              });
                              await FirebaseFirestore.instance
                                  .collection('properties')
                                  .doc(propertyId)
                                  .collection('spaces')
                                  .doc(
                                      propertyId) // Assuming space doc ID is same as property ID
                                  .set({
                                'propertyId': propertyId,
                                'propertyName': selectedPropertyName,
                                'rent': rentController.text.trim(),
                                'deposit': depositController.text.trim(),
                                'leaseDuration':
                                    leaseDurationController.text.trim(),
                                'discountType': discountType,
                                'discountValue':
                                    discountValueController.text.trim(),
                                'serviceCharge':
                                    serviceChargeController.text.trim(),
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
                                'anchorProximity': anchorProximity,
                                'footTraffic':
                                    footTrafficController.text.trim(),
                              }, SetOptions(merge: true));
                              Navigator.pop(context);
                            } catch (e) {
                              isLoading = false;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Failed to save rent details: $e')),
                              );
                            } finally {
                              _showBusy(false);
                            }
                          }
                        },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addTenantDialog(BuildContext context, String propertyId,
      {String propertyName = '',
      Map<String, dynamic>? tenantDoc,
      String? tenantId}) async {
    final _formKey = GlobalKey<FormState>();
    TextEditingController nameController =
        TextEditingController(text: tenantDoc?['name'] ?? '');
    TextEditingController phoneController =
        TextEditingController(text: tenantDoc?['phone'] ?? '');
    TextEditingController emailController =
        TextEditingController(text: tenantDoc?['email'] ?? '');
    TextEditingController ageController =
        TextEditingController(text: tenantDoc?['age']?.toString() ?? '');
    String? gender = tenantDoc?['gender'] ?? null;
    bool isLoading = false;
    String? errorMsg;

    // Fetch facilities for this property
    final facilitiesSnap = await FirebaseFirestore.instance
        .collection('properties')
        .doc(propertyId)
        .collection('facilities')
        .get();
    final facilities = facilitiesSnap.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
    List<DropdownMenuItem<String>> facilityItems = facilities.map((f) {
      final rent = f['rent'];
      String formattedRent = '';
      if (rent != null) {
        try {
          final num rentNum = num.parse(rent.toString());
          formattedRent = rentNum.toStringAsFixed(0).replaceAllMapped(
                RegExp(r'\B(?=(\d{3})+(?!\d))'),
                (match) => ',',
              );
        } catch (_) {
          formattedRent = rent.toString();
        }
      }
      return DropdownMenuItem<String>(
        value: f['id'],
        child: Text('${f['number']} - UGX $formattedRent'),
      );
    }).toList();
    String? selectedFacilityId = tenantDoc?['facilityId'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(tenantId == null ? 'Add Tenant' : 'Edit Tenant'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(hintText: 'Name'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(hintText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(hintText: 'Phone'),
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: ageController,
                        decoration: InputDecoration(hintText: 'Age'),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: gender,
                        decoration: InputDecoration(hintText: 'Gender'),
                        items: [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                              value: 'Female', child: Text('Female')),
                        ],
                        onChanged: (val) => setState(() => gender = val),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedFacilityId,
                        decoration: InputDecoration(labelText: 'Facility/Room'),
                        items: facilityItems,
                        onChanged: (val) =>
                            setState(() => selectedFacilityId = val),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      if (errorMsg != null) ...[
                        SizedBox(height: 8),
                        Text(errorMsg!, style: TextStyle(color: Colors.red)),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                if (tenantId != null)
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Delete Tenant'),
                                content: Text(
                                    'Are you sure you want to delete this tenant?'),
                                actions: [
                                  TextButton(
                                    child: Text('Cancel'),
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              setState(() => isLoading = true);
                              await FirebaseFirestore.instance
                                  .collection('properties')
                                  .doc(propertyId)
                                  .collection('tenants')
                                  .doc(tenantId)
                                  .delete();
                              Navigator.pop(context); // Close edit dialog
                            }
                          },
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: m3Primary,
                    foregroundColor: m3OnPrimary,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => isLoading = true);
                            try {
                              final selectedFacility = facilities.firstWhere(
                                  (f) => f['id'] == selectedFacilityId);
                              final tenantData = {
                                'name': nameController.text.trim(),
                                'displayName': nameController.text.trim(),
                                'email':
                                    emailController.text.trim().toLowerCase(),
                                'phone': phoneController.text.trim(),
                                'age': int.tryParse(ageController.text.trim()),
                                'gender': gender,
                                'role': 'tenant',
                                'createdAt': FieldValue.serverTimestamp(),
                                'propertyId': propertyId,
                                'propertyName': propertyName,
                                'facilityId': selectedFacilityId,
                                'facilityNumber': selectedFacility['number'],
                                'facilityRent': selectedFacility['rent'],
                              };
                              final tenantsRef = FirebaseFirestore.instance
                                  .collection('properties')
                                  .doc(propertyId)
                                  .collection('tenants');
                              if (tenantId == null) {
                                await tenantsRef.add(tenantData);
                              } else {
                                await tenantsRef
                                    .doc(tenantId)
                                    .update(tenantData);
                              }
                              // Optionally, also add/update in global users collection
                              final usersRef = FirebaseFirestore.instance
                                  .collection('users');
                              final userDocs = await usersRef
                                  .where('email',
                                      isEqualTo: emailController.text
                                          .trim()
                                          .toLowerCase())
                                  .get();
                              if (userDocs.docs.isEmpty) {
                                await usersRef.add({
                                  'name': nameController.text.trim(),
                                  'email':
                                      emailController.text.trim().toLowerCase(),
                                  'phone': phoneController.text.trim(),
                                  'role': 'tenant',
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                              } else {
                                // If user exists but role is undefined/null/empty, update to 'tenant'
                                final userDoc = userDocs.docs.first;
                                final userData =
                                    userDoc.data() as Map<String, dynamic>;
                                final currentRole = (userData['role'] ?? '')
                                    .toString()
                                    .trim()
                                    .toLowerCase();
                                if (currentRole.isEmpty ||
                                    currentRole == 'undefined' ||
                                    currentRole == 'null') {
                                  await usersRef
                                      .doc(userDoc.id)
                                      .update({'role': 'tenant'});
                                }
                              }
                              Navigator.pop(context);
                            } catch (e) {
                              setState(() {
                                isLoading = false;
                                errorMsg = 'Failed to save tenant: $e';
                              });
                            }
                          }
                        },
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(tenantId == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Map<String, dynamic>? _getSelectedProperty() {
    if (selectedPropertyId == null) return null;
    final property = _propertyCache.firstWhere(
      (prop) => prop['id'] == selectedPropertyId,
      orElse: () => {},
    );
    return property.isEmpty ? null : property;
  }

  Widget buildPropertyCard(
    Map<String, dynamic> data,
    VoidCallback onTap,
    VoidCallback onEdit,
  ) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(data['name'] ?? '',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(data['location'] ?? ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.orange),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: m3Primary),
              onPressed: onTap,
              tooltip: 'Select',
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class TenantDatabasePage extends StatefulWidget {
  final String propertyId;
  final String propertyName;
  final Future<void> Function()? onAddTenant;
  const TenantDatabasePage({
    Key? key,
    required this.propertyId,
    required this.propertyName,
    this.onAddTenant,
  }) : super(key: key);
  @override
  State<TenantDatabasePage> createState() => _TenantDatabasePageState();
}

class _TenantDatabasePageState extends State<TenantDatabasePage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenants - ${widget.propertyName}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name, email or phone',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    ),
                    onChanged: (val) =>
                        setState(() => searchQuery = val.trim().toLowerCase()),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.person_add),
                  label: Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showAddOrEditTenantDialog(),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Tenant count row
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('properties')
                  .doc(widget.propertyId)
                  .collection('tenants')
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return SizedBox();
                final total = snapshot.data!.docs.length;
                return Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                  child: Text('Total tenants: $total',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('properties')
                    .doc(widget.propertyId)
                    .collection('tenants')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading tenants'));
                  }
                  final tenants = snapshot.data?.docs ?? [];
                  final filtered = tenants.where((t) {
                    final data = t.data() as Map<String, dynamic>;
                    if (searchQuery.isEmpty) return true;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final email =
                        (data['email'] ?? '').toString().toLowerCase();
                    final phone =
                        (data['phone'] ?? '').toString().toLowerCase();
                    return name.contains(searchQuery) ||
                        email.contains(searchQuery) ||
                        phone.contains(searchQuery);
                  }).toList();
                  if (filtered.isEmpty) {
                    return Center(child: Text('No tenants found.'));
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final doc = filtered[idx];
                      final data = doc.data() as Map<String, dynamic>;
                      final phone = data['phone'] ?? '';
                      // Format phone for WhatsApp (Uganda)
                      String waPhone = phone.toString().trim();
                      if (waPhone.startsWith('0')) {
                        waPhone = '+256' + waPhone.substring(1);
                      }
                      if (!waPhone.startsWith('+256')) {
                        waPhone =
                            '+256' + waPhone.replaceAll(RegExp(r'^\+?'), '');
                      }
                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.person, color: Colors.green),
                          title: Text(data['name'] ?? '',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${data['email'] ?? ''}\n${data['phone'] ?? ''}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.sms_outlined,
                                    color: Colors.blue),
                                tooltip: 'SMS',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SendSmsPage(
                                        phone: phone,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: FaIcon(FontAwesomeIcons.whatsapp,
                                    color: Colors.green),
                                tooltip: 'WhatsApp',
                                onPressed: () async {
                                  final waUri = Uri.parse(
                                      'https://wa.me/${waPhone.replaceAll('+', '')}');
                                  await launchUrl(waUri);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.orange),
                                tooltip: 'Edit',
                                onPressed: () => _showAddOrEditTenantDialog(
                                  tenantDoc: data,
                                  tenantId: doc.id,
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
          ],
        ),
      ),
    );
  }

  Future<void> _showAddOrEditTenantDialog(
      {Map<String, dynamic>? tenantDoc, String? tenantId}) async {
    final _formKey = GlobalKey<FormState>();
    TextEditingController nameController =
        TextEditingController(text: tenantDoc?['name'] ?? '');
    TextEditingController phoneController =
        TextEditingController(text: tenantDoc?['phone'] ?? '');
    TextEditingController emailController =
        TextEditingController(text: tenantDoc?['email'] ?? '');
    TextEditingController ageController =
        TextEditingController(text: tenantDoc?['age']?.toString() ?? '');
    String? gender = tenantDoc?['gender'] ?? null;
    bool isLoading = false;
    String? errorMsg;
    // Fetch facilities for this property
    final facilitiesSnap = await FirebaseFirestore.instance
        .collection('properties')
        .doc(widget.propertyId)
        .collection('facilities')
        .get();
    final facilities = facilitiesSnap.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
    List<DropdownMenuItem<String>> facilityItems = facilities.map((f) {
      final rent = f['rent'];
      String formattedRent = '';
      if (rent != null) {
        try {
          final num rentNum = num.parse(rent.toString());
          formattedRent = rentNum.toStringAsFixed(0).replaceAllMapped(
                RegExp(r'\B(?=(\d{3})+(?!\d))'),
                (match) => ',',
              );
        } catch (_) {
          formattedRent = rent.toString();
        }
      }
      return DropdownMenuItem<String>(
        value: f['id'],
        child: Text('${f['number']} - UGX $formattedRent'),
      );
    }).toList();
    String? selectedFacilityId = tenantDoc?['facilityId'];
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(tenantId == null ? 'Add Tenant' : 'Edit Tenant'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(hintText: 'Name'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(hintText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(hintText: 'Phone'),
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: ageController,
                        decoration: InputDecoration(hintText: 'Age'),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: gender,
                        decoration: InputDecoration(hintText: 'Gender'),
                        items: [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                              value: 'Female', child: Text('Female')),
                        ],
                        onChanged: (val) => setState(() => gender = val),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedFacilityId,
                        decoration: InputDecoration(labelText: 'Facility/Room'),
                        items: facilityItems,
                        onChanged: (val) =>
                            setState(() => selectedFacilityId = val),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      if (errorMsg != null) ...[
                        SizedBox(height: 8),
                        Text(errorMsg!, style: TextStyle(color: Colors.red)),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                if (tenantId != null)
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Delete Tenant'),
                                content: Text(
                                    'Are you sure you want to delete this tenant?'),
                                actions: [
                                  TextButton(
                                    child: Text('Cancel'),
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              setState(() => isLoading = true);
                              await FirebaseFirestore.instance
                                  .collection('properties')
                                  .doc(widget.propertyId)
                                  .collection('tenants')
                                  .doc(tenantId)
                                  .delete();
                              Navigator.pop(context); // Close edit dialog
                            }
                          },
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: m3Primary,
                    foregroundColor: m3OnPrimary,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => isLoading = true);
                            try {
                              final selectedFacility = facilities.firstWhere(
                                  (f) => f['id'] == selectedFacilityId);
                              final tenantData = {
                                'name': nameController.text.trim(),
                                'displayName': nameController.text.trim(),
                                'email':
                                    emailController.text.trim().toLowerCase(),
                                'phone': phoneController.text.trim(),
                                'age': int.tryParse(ageController.text.trim()),
                                'gender': gender,
                                'role': 'tenant',
                                'createdAt': FieldValue.serverTimestamp(),
                                'propertyId': widget.propertyId,
                                'propertyName': widget.propertyName,
                                'facilityId': selectedFacilityId,
                                'facilityNumber': selectedFacility['number'],
                                'facilityRent': selectedFacility['rent'],
                              };
                              final tenantsRef = FirebaseFirestore.instance
                                  .collection('properties')
                                  .doc(widget.propertyId)
                                  .collection('tenants');
                              if (tenantId == null) {
                                await tenantsRef.add(tenantData);
                              } else {
                                await tenantsRef
                                    .doc(tenantId)
                                    .update(tenantData);
                              }
                              Navigator.pop(context);
                            } catch (e) {
                              setState(() {
                                isLoading = false;
                                errorMsg = 'Failed to save tenant: $e';
                              });
                            }
                          }
                        },
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(tenantId == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class FacilitiesPage extends StatefulWidget {
  final String propertyId;
  final String propertyName;
  const FacilitiesPage(
      {Key? key, required this.propertyId, required this.propertyName})
      : super(key: key);
  @override
  State<FacilitiesPage> createState() => _FacilitiesPageState();
}

class _FacilitiesPageState extends State<FacilitiesPage> {
  String searchQuery = '';

  Future<void> _showAddOrEditFacilityDialog(
      {Map<String, dynamic>? facilityDoc, String? facilityId}) async {
    final _formKey = GlobalKey<FormState>();
    TextEditingController numberController =
        TextEditingController(text: facilityDoc?['number'] ?? '');
    TextEditingController rentController =
        TextEditingController(text: facilityDoc?['rent']?.toString() ?? '');
    TextEditingController bedroomsController =
        TextEditingController(text: facilityDoc?['bedrooms']?.toString() ?? '');
    TextEditingController bathroomsController = TextEditingController(
        text: facilityDoc?['bathrooms']?.toString() ?? '');
    TextEditingController kitchenDescController =
        TextEditingController(text: facilityDoc?['kitchenDesc'] ?? '');
    String? facilityType = facilityDoc?['type'];
    bool isLoading = false;

    // Fetch property type for this property
    DocumentSnapshot propertyDoc = await FirebaseFirestore.instance
        .collection('properties')
        .doc(widget.propertyId)
        .get();
    String propertyType =
        (propertyDoc.data() as Map<String, dynamic>?)?['category'] ?? '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(facilityId == null
                  ? 'New Facility/Room'
                  : 'Edit Facility/Room'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: numberController,
                        decoration:
                            InputDecoration(labelText: 'Facility/Room Number'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: rentController,
                        decoration:
                            InputDecoration(labelText: 'Rent Amount (UGX)'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 8),
                      if (propertyType == 'Residential Rentals' ||
                          propertyType == 'Residential Apartments') ...[
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
                        TextFormField(
                          controller: kitchenDescController,
                          decoration: InputDecoration(
                            labelText: 'More features',
                          ),
                        ),
                      ],
                      if (propertyType == 'Shop Rentals' ||
                          propertyType == 'Mall Commercial Spaces') ...[
                        DropdownButtonFormField<String>(
                          value: facilityType,
                          decoration:
                              InputDecoration(labelText: 'Facility Type'),
                          items: [
                            DropdownMenuItem(
                                value: 'Shop', child: Text('Shop')),
                            DropdownMenuItem(
                                value: 'Office', child: Text('Office')),
                            DropdownMenuItem(
                                value: 'Kiosk', child: Text('Kiosk')),
                            DropdownMenuItem(
                                value: 'Stall', child: Text('Stall')),
                          ],
                          onChanged: (val) =>
                              setState(() => facilityType = val),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: m3Primary,
                    foregroundColor: m3OnPrimary,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => isLoading = true);
                            try {
                              final data = {
                                'number': numberController.text.trim(),
                                'rent':
                                    int.tryParse(rentController.text.trim()) ??
                                        0,
                                'propertyId': widget.propertyId,
                                'createdAt': FieldValue.serverTimestamp(),
                                if (propertyType == 'Residential Rentals' ||
                                    propertyType ==
                                        'Residential Apartments') ...{
                                  'bedrooms': int.tryParse(
                                          bedroomsController.text.trim()) ??
                                      0,
                                  'bathrooms': int.tryParse(
                                          bathroomsController.text.trim()) ??
                                      0,
                                  'kitchenDesc':
                                      kitchenDescController.text.trim(),
                                },
                                if (propertyType == 'Shop Rentals' ||
                                    propertyType ==
                                        'Mall Commercial Spaces') ...{
                                  'type': facilityType,
                                },
                              };
                              final ref = FirebaseFirestore.instance
                                  .collection('properties')
                                  .doc(widget.propertyId)
                                  .collection('facilities');
                              if (facilityId == null) {
                                await ref.add(data);
                              } else {
                                await ref.doc(facilityId).update(data);
                              }
                              Navigator.pop(context);
                            } catch (e) {
                              setState(() => isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e')),
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(facilityId == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Facilities/Rooms - ${widget.propertyName}'),
        backgroundColor: m3Primary,
        foregroundColor: m3OnPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('New Facility/Room'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: m3Primary,
                    foregroundColor: m3OnPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () => _showAddOrEditFacilityDialog(),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by facility/room number',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    ),
                    onChanged: (val) =>
                        setState(() => searchQuery = val.trim().toLowerCase()),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('properties')
                    .doc(widget.propertyId)
                    .collection('facilities')
                    .orderBy('number')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading facilities'));
                  }
                  final facilities = snapshot.data?.docs ?? [];
                  final filtered = facilities.where((f) {
                    final data = f.data() as Map<String, dynamic>;
                    if (searchQuery.isEmpty) return true;
                    final number =
                        (data['number'] ?? '').toString().toLowerCase();
                    return number.contains(searchQuery);
                  }).toList();

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final f = filtered[index];
                      final data = f.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: Icon(Icons.meeting_room, color: m3Primary),
                        title: Text('Room ${data['number'] ?? ''}'),
                        subtitle: Text('Rent: UGX ${data['rent'] ?? ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: m3Primary),
                              tooltip: 'Edit',
                              onPressed: () => _showAddOrEditFacilityDialog(
                                  facilityDoc: data, facilityId: f.id),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Delete Facility/Room'),
                                    content: Text(
                                        'Are you sure you want to delete this facility/room?'),
                                    actions: [
                                      TextButton(
                                          child: Text('Cancel'),
                                          onPressed: () =>
                                              Navigator.pop(context, false)),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await FirebaseFirestore.instance
                                      .collection('properties')
                                      .doc(widget.propertyId)
                                      .collection('facilities')
                                      .doc(f.id)
                                      .delete();
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add SendSmsPage widget at the bottom of the file
class SendSmsPage extends StatefulWidget {
  final String phone;
  final String? tenantName;
  const SendSmsPage({Key? key, required this.phone, this.tenantName})
      : super(key: key);
  @override
  State<SendSmsPage> createState() => _SendSmsPageState();
}

class _SendSmsPageState extends State<SendSmsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  String? _error;

  String get formattedPhone {
    String phone = widget.phone.trim();
    if (phone.startsWith('0')) {
      phone = '256' + phone.substring(1);
    } else if (phone.startsWith('+256')) {
      phone = phone.substring(1);
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send SMS'),
        backgroundColor: m3Primary,
        foregroundColor: m3OnPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.tenantName != null &&
                  widget.tenantName!.isNotEmpty) ...[
                Text(widget.tenantName!,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 2),
              ],
              Text('To:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(formattedPhone, style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Message',
                  filled: true,
                  fillColor: Color(0xFFF5F5F5), // very faint grey
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a message' : null,
              ),
              SizedBox(height: 24),
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: Colors.red)),
                SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: m3Primary,
                    foregroundColor: m3OnPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: _isSending
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isSending = true;
                              _error = null;
                            });
                            try {
                              await SendSMS().sendSms(
                                phone: formattedPhone,
                                msg: _messageController.text.trim(),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('SMS sent!')),
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              setState(() {
                                _error = 'Failed to send SMS: ' + e.toString();
                                _isSending = false;
                              });
                            }
                          }
                        },
                  child: _isSending
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Send'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
