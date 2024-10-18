// services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/delivery.dart';
import 'dart:io';

class ApiService {
  final String baseUrl = 'http://197.136.16.164:8000/app'; // Update with your API base URL

  // Fetch all deliveries from the API
  Future<List<Delivery>> fetchDeliveries() async {
    final response = await http.get(Uri.parse('$baseUrl/deliveries/'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((delivery) => Delivery.fromJson(delivery)).toList();
    } else {
      throw Exception('Failed to load deliveries');
    }
  }


  Future<bool> createDelivery(Delivery delivery, String invoiceFilePath) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/deliveries/'));

    // Add text fields to the request
    request.fields['supplier_name'] = delivery.supplierName;
    request.fields['quantity'] = delivery.quantity.toString();
    request.fields['date_delivered'] = delivery.dateDelivered;
    request.fields['person_receiving'] = delivery.personReceiving;
    request.fields['invoice_number'] = delivery.invoiceNumber;
    request.fields['project'] = delivery.project;
    request.fields['comments'] = delivery.comments;

    // Attach the invoice file
    request.files.add(await http.MultipartFile.fromPath('invoice_file', invoiceFilePath));

    // Send the request
    var response = await request.send();

    // Check the response status
    if (response.statusCode == 201) {
      return true;
    } else {
      print('Failed to add delivery. Status Code: ${response.statusCode}');
      return false;
    }
  }
}