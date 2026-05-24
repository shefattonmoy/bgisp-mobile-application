import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/constant.dart';
import '../../models/Contact/contact.dart';

class ContactApi {
  final String baseUrl = AppConstants.myAPILink;

  Future<bool> sendContactMessage(ContactMessage message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/contact/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message.toJson()),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }
}