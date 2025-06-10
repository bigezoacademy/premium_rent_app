import 'package:flutter/material.dart';
import 'SendSms.dart';

class SendSmsPage extends StatefulWidget {
  final String tenantName;
  final String tenantPhone;
  const SendSmsPage(
      {Key? key, required this.tenantName, required this.tenantPhone})
      : super(key: key);

  @override
  State<SendSmsPage> createState() => _SendSmsPageState();
}

class _SendSmsPageState extends State<SendSmsPage> {
  final TextEditingController _msgController = TextEditingController();
  String _status = '';
  bool _sending = false;

  String _formatPhone(String phone) {
    // Remove leading + or 0, ensure starts with 256
    String p = phone.trim();
    if (p.startsWith('+')) p = p.substring(1);
    if (p.startsWith('0')) p = '256' + p.substring(1);
    if (!p.startsWith('256')) p = '256' + p;
    return p;
  }

  Future<void> _sendSms() async {
    setState(() {
      _sending = true;
      _status = 'Sending...';
    });
    final phone = _formatPhone(widget.tenantPhone);
    final msg = _msgController.text.trim();
    if (msg.isEmpty) {
      setState(() {
        _status = 'Message cannot be empty.';
        _sending = false;
      });
      return;
    }
    final result = await SendSMS().sendSms(phone: phone, msg: msg);
    setState(() {
      _status = result;
      _sending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send SMS to Tenant'),
        backgroundColor: Color.fromARGB(255, 21, 136, 54),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tenant:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.tenantName),
            SizedBox(height: 12),
            Text('Phone:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_formatPhone(widget.tenantPhone)),
            SizedBox(height: 24),
            TextField(
              controller: _msgController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.blue,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.blue,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.blue,
                    width: 2,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.send),
                  label: Text('Send SMS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(5), // 5px border radius
                    ),
                  ),
                  onPressed: _sending ? null : _sendSms,
                ),
                SizedBox(width: 16),
                if (_sending) CircularProgressIndicator(),
              ],
            ),
            SizedBox(height: 16),
            Text(_status, style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
