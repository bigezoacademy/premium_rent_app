import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SendSMS {
  String sendingStatus = "Sending...";

  static const String _username = "alfredochola";
  static const String _password = "JesusisLORD";
  static const String _sender = "Premium Rent App";

  Future<String> sendSms({
    required String phone,
    required String msg,
  }) async {
    String apiUrl = "https://www.egosms.co/api/v1/plain/?";
    try {
      sendingStatus = "Sending...";

      Map<String, String> params = {
        'number': phone,
        'message': msg,
        'username': _username,
        'password': _password,
        'sender': _sender,
      };

      String encodedParams = params.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final url = Uri.parse('$apiUrl$encodedParams');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print("Response: \n");
        print(response.body);
        sendingStatus = "Success";
        return "SMS sent successfully!";
      } else {
        sendingStatus = "Failed";
        print(
            "Failed: Status \\${response.statusCode}, Body: \n${response.body}");
        return "Failed: Status \\${response.statusCode}, Body: \n${response.body}";
      }
    } catch (e) {
      sendingStatus = "Failed";
      print("Error: $e");
      // Only show error if status code was not 200
      return "Failed to send SMS. Please check your connection or try again.";
    }
  }
}
