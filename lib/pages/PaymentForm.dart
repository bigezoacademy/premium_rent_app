import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:premium_rent_app/pages/AppLayout.dart';
import 'package:premium_rent_app/pages/MyDatabase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path/path.dart' as path;
import '../receiptNumberHelper.dart';
import 'package:http/http.dart' as http;
import 'SendSms.dart';

class PaymentForm extends StatefulWidget {
  final Map<String, dynamic> paymentDetails;
  // final int receiptNumber = 1;

  // Add a default value for the paymentDetails parameter
  const PaymentForm({Key? key, this.paymentDetails = const {}})
      : super(key: key);

  @override
  _PaymentFormState createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController amountInWordsController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController payerPhoneController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();
  final TextEditingController receiptNumberController = TextEditingController();
  final TextEditingController nextDateController = TextEditingController();

  int receiptNumber = 1;

  @override
  Future<void> initState() async {
    super.initState();
    payerPhoneController.text = widget.paymentDetails['phone'];
    reasonController.text =
        'Rent for ' + widget.paymentDetails['selectedMonth'];
    try {
      await _loadCurrentReceiptNumber();
    } catch (e) {}
  }

  bool _isSubmitting = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      body: ListView(
        children: [
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(25.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.print,
                      size: 30.0,
                      color: Color.fromARGB(255, 31, 96, 157),
                    ),
                    SizedBox(width: 30.0),
                    Text(
                      "CREATE RECEIPT",
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 22, 90, 162),
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    left: 25.0, top: 0, right: 25.0, bottom: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '  ${widget.paymentDetails["name"]}  -> ${widget.paymentDetails["apartment"]}',
                      style: TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      ' --Receipt no. --$receiptNumber',
                      style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.normal,
                          color: Color.fromARGB(255, 16, 79, 168)),
                    ),
                    SizedBox(height: 20.0),
                    TextFormField(
                      controller: amountController,
                      decoration:
                          InputDecoration(labelText: 'Amount (Figures)'),
                      style: TextStyle(
                          color: Color.fromARGB(255, 188, 4, 4),
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter the payment amount'
                          : null,
                    ),
                    TextFormField(
                      controller: amountInWordsController,
                      decoration: InputDecoration(labelText: 'Amount in Words'),
                      style: TextStyle(
                          color: Color.fromARGB(255, 188, 4, 4),
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter the amount in words'
                          : null,
                    ),
                    TextFormField(
                      controller: reasonController,
                      decoration:
                          InputDecoration(labelText: 'Reason for payment'),
                      style: TextStyle(
                          color: Color.fromARGB(255, 188, 4, 4),
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter the reason for payment'
                          : null,
                    ),
                    TextFormField(
                      controller: payerPhoneController,
                      decoration: InputDecoration(labelText: 'Client\'s Phone'),
                      style: TextStyle(
                          color: Color.fromARGB(255, 188, 4, 4),
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter the client\'s phone number'
                          : null,
                    ),
                    TextFormField(
                      controller: balanceController,
                      decoration: InputDecoration(labelText: 'Balance'),
                      style: TextStyle(
                          color: Color.fromARGB(255, 188, 4, 4),
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold),
                    ),
                    TextFormField(
                      controller: nextDateController,
                      decoration:
                          InputDecoration(labelText: 'Next Payment on:'),
                      style: TextStyle(
                          color: Color.fromARGB(255, 188, 4, 4),
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Center(
                      child: Column(
                        children: [
                          SizedBox(height: 30.0),
                          if (_isSubmitting)
                            Column(
                              children: [
                                SizedBox(
                                  height:
                                      10.0, // Adjust the height for thickness
                                  child: LinearProgressIndicator(
                                    value: _uploadProgress,
                                    minHeight:
                                        8.0, // Set the thickness of the progress indicator
                                  ),
                                ),
                                SizedBox(height: 20.0),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          color: Color.fromARGB(255, 46, 46, 46),
                          child: TextButton.icon(
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                MyDatabase()));
                                  },
                            icon: Icon(
                              Icons.arrow_back,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                            label: Text(
                              "Back",
                              style: TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255)),
                            ),
                          ),
                        ),
                        SizedBox(width: 50.0),
                        Container(
                          color: Color.fromARGB(255, 14, 178, 38),
                          child: TextButton.icon(
                            onPressed: _isSubmitting ? null : _submitPayment,
                            icon: Icon(
                              Icons.print,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                            label: Text(
                              "Create",
                              style: TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255)),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? formatPhoneNumber(String phone) {
    // Remove any non-digit characters
    phone = phone.replaceAll(RegExp(r'\D'), '');

    if (phone.startsWith('0')) {
      // Remove leading 0 and add 256
      phone = '256' + phone.substring(1);
    } else if (phone.startsWith('7')) {
      // Add 256 before 7
      phone = '256' + phone;
    } else if (!phone.startsWith('256')) {
      // If the phone number does not start with 256, discard it
      return null;
    }

    return phone;
  }

  void _submitPayment() async {
    String? formattedPhone = formatPhoneNumber(payerPhoneController.text);

    if (formattedPhone == null) {
      _showErrorDialog('Invalid phone number.start with 0 or 7');
      return;
    }
    Map<String, dynamic> payment = {
      'clientId': 1,
      'paymentDate': DateTime.now().toIso8601String(),
      'amount': amountController.text,
      'amountInWords': amountInWordsController.text,
      'reasonOfPayment': reasonController.text,
      'payerPhone': payerPhoneController.text,
      'balance': balanceController.text,
      'nextpayment': nextDateController.text,
      'dueDate': '',
      'year': '',
    };
    if (_validateInputs()) {
      setState(() {
        _isSubmitting = true;
        _uploadProgress = 0.0;
      });

      Timer.periodic(Duration(milliseconds: 100), (Timer timer) {
        if (_uploadProgress >= 1.0) {
          timer.cancel();
        } else {
          setState(() {
            _uploadProgress += 0.1;
          });
        }
      });

      try {
        await Future.delayed(Duration(seconds: 3)); // Simulate a delay
        await _submitToGoogleSheet(payment);
        try {
          final sendSMS = SendSMS();
          final name = widget.paymentDetails["name"] ?? "";
          final amount = payment["amount"] ?? "";
          final reason = payment["reasonOfPayment"] ?? "";
          final message =
              "Dear $name, you have paid Ugx $amount -- $reason. Thank you - Premium Rent App";

          await sendSMS.sendSms(message, formattedPhone);
        } catch (e) {
          print('Error: $e');
          _showErrorDialog(
              'Failed to send SMS to client. Check internet or SMS balance.');
        }
        _createReceipt(payment);
        print('Data successfully uploaded and receipt created.');
      } catch (e) {
        print('Error: $e');
        _showErrorDialog('Failed to upload. Please check your connection.');
      } finally {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _submitToGoogleSheet(Map<String, dynamic> payment) async {
    final String url = 'https://sheetdb.io/api/v1/k16v2dd0hgbvh';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'name': widget.paymentDetails["name"] ?? '',
          'phone': payment["payerPhone"] ?? '',
          'apartment': '${widget.paymentDetails["apartment"]}',
          'amountInWords': payment["amountInWords"] ?? '',
          'reason': payment["reasonOfPayment"] ?? '',
          'balance': payment["balance"] ?? '',
          'nextpayment': payment["nextpayment"] ?? '',
          'amount': payment["amount"] ?? '',
          'receiptNumber': receiptNumber.toString(),
          'date': payment["paymentDate"] ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Data uploaded successfully');
      } else {
        print(
            'Failed to submit data, check your internet: ${response.statusCode}');
        throw Exception('Failed to submit data');
      }
    } catch (e) {
      print('Error submitting data, Check your internet: $e');
      throw e;
    }
  }

  bool _validateInputs() {
    if (amountController.text.isEmpty ||
        amountInWordsController.text.isEmpty ||
        reasonController.text.isEmpty ||
        payerPhoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all the fields'),
          backgroundColor: Color.fromARGB(255, 187, 37, 37),
        ),
      );
      return false;
    }
    return true;
  }

  void _createReceipt(Map<String, dynamic> payment) async {
    try {
      // Create a PDF document
      final PdfDocument document = PdfDocument();

      // Add a page to the document
      document.pageSettings.size = PdfPageSize.a4;
      PdfPage page = document.pages.add();

      // Change the page orientation to landscape
      document.pageSettings.orientation = PdfPageOrientation.landscape;

      // Get the background image from assets
      final ByteData data = await rootBundle.load('assets/receipt.png');
      final Uint8List backgroundImageBytes = data.buffer.asUint8List();
      final PdfBitmap backgroundBitmap = PdfBitmap(backgroundImageBytes);

      // Calculate the position and size to maintain the aspect ratio
      double imageWidth, imageHeight;
      if (backgroundBitmap.width > backgroundBitmap.height) {
        imageWidth = page.getClientSize().width;
        imageHeight = (page.getClientSize().width / backgroundBitmap.width) *
            backgroundBitmap.height;
      } else {
        imageHeight = page.getClientSize().height;
        imageWidth = (page.getClientSize().height / backgroundBitmap.height) *
            backgroundBitmap.width;
      }

      page.graphics.drawImage(
        backgroundBitmap,
        Rect.fromLTWH(0, 0, imageWidth, imageHeight),
      );

      // Add new text at the top without pushing existing content
      final PdfFont topTextFont =
          PdfStandardFont(PdfFontFamily.helvetica, 14); // Font for top text
      final PdfColor textColor = PdfColor(0, 107, 179); // Sky blue color
      final PdfFont topTextFont2 = PdfStandardFont(
        PdfFontFamily.helvetica,
        15,
        style: PdfFontStyle.bold,
      );
      // Font for top text
      final PdfColor textColor2 = PdfColor(0, 0, 0); // Sky blue color
      double topTextX = 0; // X position for the top text
      double topTextY = 87; // Y position for the top text

      _drawParagraph(
        page.graphics,
        topTextFont2,
        '                        ${(widget.paymentDetails["apartment"] ?? "").toString().toUpperCase()}',
        topTextX,
        topTextY,
        textColor2,
      );

// Define the font for the next payment text
      final PdfFont nextPaymentFont =
          PdfStandardFont(PdfFontFamily.helvetica, 14);
      final PdfColor nextPaymentColor =
          PdfColor(255, 0, 0); // Red color for visibility

// Define a new starting position for the next payment text
      double nextPaymentX = 50;
      double nextPaymentY = 300; // Starting Y position; adjust as needed

// Add the next payment text
      _drawParagraph(
        page.graphics,
        nextPaymentFont,
        '                   ${payment["nextpayment"] ?? "N/A"}', // Change key if needed
        nextPaymentX,
        nextPaymentY,
        nextPaymentColor,
      );

// If needed, update y position for subsequent content
      double x = 50;
      double y = 119;

      // Existing content drawing logic
      String receiptforclient =
          '${widget.paymentDetails["name"] ?? ''},   Tel: ${payment["payerPhone"] ?? ""}';

      String _getMonthName(int month) {
        switch (month) {
          case 1:
            return 'Jan';
          case 2:
            return 'Feb';
          case 3:
            return 'Mar';
          case 4:
            return 'Apr';
          case 5:
            return 'May';
          case 6:
            return 'Jun';
          case 7:
            return 'Jul';
          case 8:
            return 'Aug';
          case 9:
            return 'Sep';
          case 10:
            return 'Oct';
          case 11:
            return 'Nov';
          case 12:
            return 'Dec';
          default:
            return '';
        }
      }

      int receiptNumber = 1;
      try {
        receiptNumber = await ReceiptNumberHelper.instance.getReceiptNumber();
        print(receiptNumber);
      } catch (e) {
        print('Error fetching receipt number: $e');
      }
      final String receiptNumberText = '$receiptNumber';
      String dateofreceipt =
          "${DateTime.now().day}/${_getMonthName(DateTime.now().month)}/${DateTime.now().year}";
      print('date is--------------------- $dateofreceipt');

      _drawParagraph(
        page.graphics,
        topTextFont,
        '$receiptNumberText                                                                           $dateofreceipt',
        x,
        y,
        textColor,
      );
      y += 47; // Increased line spacing for readability

      _drawParagraph(
        page.graphics,
        topTextFont,
        receiptforclient,
        x,
        y,
        textColor,
      );
      y += 22; // Increased line spacing for readability

      final amountText = payment["amountInWords"] ?? "";
      final splitStrings = _splitText(amountText, 60, 80);
      final firstamount = splitStrings[0];
      final secondamount = splitStrings[1];

      _drawParagraph(
        page.graphics,
        topTextFont,
        '                           $firstamount', // Use the text that is properly wrapped and possibly truncated
        x,
        y,
        textColor,
      );

      y += 20;

      _drawParagraph(
        page.graphics,
        topTextFont,
        '$secondamount', // Use the text that is properly wrapped and possibly truncated
        x,
        y,
        textColor,
      );

      y += 30;

      // Print the wrapped amount in words to the console

      final reasonText = payment["reasonOfPayment"] ?? "";
      final splitStringsReason = _splitText(reasonText, 40, 80);
      final firstreason = splitStringsReason[0];
      final secondreason = splitStringsReason[1];
      print('-------------FIRST REASON -------$firstreason');
      print('-------------SECOND REASON -------$firstreason');

      _drawParagraph(
        page.graphics,
        topTextFont,
        '                       $firstreason',
        x,
        y,
        textColor,
      );
      y += 20;

      _drawParagraph(
        page.graphics,
        topTextFont,
        ' $secondreason',
        x,
        y,
        textColor,
      );
      y += 30;

      // Print the wrapped reason of payment to the console

      _drawParagraph(
        page.graphics,
        topTextFont,
        '                                                                              ${payment["balance"] ?? ""}',
        x,
        y,
        textColor,
      );
      y += 36;

      _drawParagraph(
        page.graphics,
        topTextFont,
        '            ${payment["amount"] ?? ""}',
        x,
        y,
        textColor,
      );
      y += 10;

      // Save the PDF to a file in the "receipts" subfolder
      final List<int> bytes = await document.save();
      document.dispose();

      // Save the PDF to a file in the "receipts" subfolder
      final String selectedMonth =
          widget.paymentDetails['selectedMonth'] ?? 'default';
      final String timestamp = getFormattedTimestamp();
      final String fileName =
          'Receipt_${widget.paymentDetails["name"]}_$timestamp.pdf';
      final String filePath = await _saveAsFile(bytes, selectedMonth, fileName);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('Receipt'),
              actions: [
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () async {
                    await _sharePdf(filePath);
                  },
                ),
              ],
            ),
            body: SfPdfViewer.file(File(filePath)),
          ),
        ),
      );

      //UPLOAD TO firebase
      //await FirebaseFileUpload.uploadPdf(context, filePath, selectedMonth);

      // Share the PDF file
      await _sharePdf(filePath);

      // Display the PDF using Syncfusion PDF Viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('Receipt'),
            ),
            body: SfPdfViewer.file(File(filePath)),
          ),
        ),
      );
    } catch (e) {
      print('Error creating receipt: $e');
      _showErrorDialog('Error creating receipt: $e');
    }
  }

  List<String> _splitText(
      String text, int firstMaxLength, int secondMaxLength) {
    // Helper function to join words into a single line of max length
    String joinWords(List<String> words, int maxLength) {
      String line = '';
      for (var word in words) {
        // Check if adding this word exceeds the maximum length
        if ((line.length + word.length + (line.isEmpty ? 0 : 1)) > maxLength) {
          break;
        }
        if (line.isNotEmpty) {
          line += ' ';
        }
        line += word;
      }
      return line;
    }

    // Split text into words
    final words = text.split(' ');

    // Get the first line
    final firstLine = joinWords(words, firstMaxLength);

    // Remove words already used in the first line
    final remainingWordsAfterFirstLine =
        text.substring(firstLine.length).trim().split(' ');

    // Get the second line
    final secondLine = joinWords(remainingWordsAfterFirstLine, secondMaxLength);

    // Remove words already used in the second line
    final remainingWordsAfterSecondLine = remainingWordsAfterFirstLine
        .skipWhile((word) =>
            (secondLine.length + word.length + (secondLine.isEmpty ? 0 : 1)) <=
            secondMaxLength)
        .join(' ');

    return [firstLine, secondLine, remainingWordsAfterSecondLine];
  }

  void _drawParagraph(
    PdfGraphics graphics,
    PdfFont font,
    String text,
    double x,
    double y,
    PdfColor color,
  ) {
    final PdfStringFormat format = PdfStringFormat(
      lineAlignment: PdfVerticalAlignment.middle,
    );

    graphics.drawString(
      text,
      font,
      brush: PdfSolidBrush(color),
      format: format,
      bounds: Rect.fromLTWH(x, y, graphics.clientSize.width - 2 * x, 25),
    );
  }

  Future<void> _sharePdf(String filePath) async {
    try {
      // Check if the file exists
      File file = File(filePath);
      bool exists = await file.exists();
      print('File exists: $exists');
      if (exists) {
        // Share the PDF file
        await Share.shareXFiles([XFile(filePath)], text: 'Receipt');
      } else {
        throw 'The source file doesn\'t exist.';
      }
    } catch (e) {
      print('Error sharing PDF: $e');
      _showErrorDialog('Error sharing PDF: $e');
    }
  }

  Future<String> _getSubfolderPath(String selectedMonth) async {
    final String externalStorageDir = await _getExternalStorageDirectory();
    final String subfolderPath =
        path.join(externalStorageDir, 'receipts', selectedMonth);

    // Create the subfolder if it doesn't exist
    final Directory subfolderDir = Directory(subfolderPath);
    if (!await subfolderDir.exists()) {
      await subfolderDir.create(recursive: true);
    }

    return subfolderPath;
  }

  Future<String> _getExternalStorageDirectory() async {
    final Directory? externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      return externalDir.path;
    } else {
      throw 'External storage directory not available';
    }
  }

  Future<String> _saveAsFile(
      List<int> bytes, String selectedMonth, String fileName) async {
    final String subfolderPath = await _getSubfolderPath(selectedMonth);

    // Save the PDF to a file in the subfolder
    final String filePath = path.join(subfolderPath, fileName);
    final File file = File(filePath);
    await file.writeAsBytes(bytes);

    // Print the file path for debugging
    print('File Path: $filePath');

    return filePath;
  }

  String getFormattedTimestamp() {
    final DateTime now = DateTime.now();
    final String day = now.day.toString();
    final String month = _getMonthName(now.month);
    final String year = now.year.toString();
    final String hour = _getHour(now.hour);
    final String minute = now.minute.toString().padLeft(2, '0');

    return '$day$month$year-$hour-$minute hrs';
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'jan';
      case 2:
        return 'feb';
      case 3:
        return 'mar';
      case 4:
        return 'apr';
      case 5:
        return 'may';
      case 6:
        return 'jun';
      case 7:
        return 'jul';
      case 8:
        return 'aug';
      case 9:
        return 'sep';
      case 10:
        return 'oct';
      case 11:
        return 'nov';
      case 12:
        return 'dec';
      default:
        return '';
    }
  }

  String _getHour(int hour) {
    if (hour == 0) {
      return '12';
    } else if (hour > 12) {
      return (hour - 12).toString();
    } else {
      return hour.toString();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadCurrentReceiptNumber() async {
    int receiptNumberGot =
        await ReceiptNumberHelper.instance.getReceiptNumber();
    setState(() {
      receiptNumber = receiptNumberGot;
    });
  }

  Future<void> _submitToGoogleSheetTest() async {
    final String url = 'https://sheetdb.io/api/v1/k16v2dd0hgbvh';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'name': 'John Doe',
          'phone': '123456789',
          'amountInWords': 'one hundred dollars',
          'reason': 'Jane Doe',
          'balance': '50',
          'amount': '100',
          'receiptNumber': '12345',
          'date': '2024-07-25',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        print('Data submitted successfully');
      } else {
        print('Failed to submit data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error submitting data: $e');
    }
  }
}
