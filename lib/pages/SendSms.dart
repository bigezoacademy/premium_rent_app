import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SendSMS {
  String sendingStatus = "Sending...";

  Future<String> sendSms(String msg, String phone) async {
    String username = "premium_rent_app";
    String password = "3n34VJAYtq@vZp.";
    String apiUrl = "https://www.egosms.co/api/v1/plain/?";
    try {
      sendingStatus = "Sending...";

      // Parameters to add to the URL
      Map<String, String> params = {
        'number': phone,
        'message': msg,
        'username': username,
        'password': password,
        'sender': username,
      };

      // Encoding the above parameters
      String encodedParams = params.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      // Sending HTTP request to the composed URL
      final url = Uri.parse('$apiUrl$encodedParams');
      final response = await http.get(url);

      // Receiving response
      if (response.statusCode == 200) {
        print("Response: ${response.body}");
        return "Success";
      } else {
        sendingStatus = "Failed";
        print("$sendingStatus: ${response.reasonPhrase}");
      }
    } catch (e) {
      sendingStatus = "Failed";
      print(
          "$sendingStatus $username .... $password .... $apiUrl .... $msg ... $phone ... THE END");
      print("Error: $e");
      return sendingStatus;
    }
    return sendingStatus;
  }
}
