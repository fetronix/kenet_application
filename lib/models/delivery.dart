// models/delivery.dart

class Delivery {
  final int? id;
  final String supplierName;
  final int quantity;
  final String dateDelivered;
  final String personReceiving;
  final String? invoiceFile; // URL or path to the uploaded file
  final String invoiceNumber;
  final String project;
  final String comments;

  Delivery({
    this.id,
    required this.supplierName,
    required this.quantity,
    required this.dateDelivered,
    required this.personReceiving,
    this.invoiceFile,
    required this.invoiceNumber,
    required this.project,
    required this.comments,
  });

  Map<String, dynamic> toJson() {
    return {
      'supplier_name': supplierName,
      'quantity': quantity,
      'date_delivered': dateDelivered,
      'person_receiving': personReceiving,
      'invoice_file': invoiceFile,
      'invoice_number': invoiceNumber,
      'project': project,
      'comments': comments,
    };
  }
// Convert JSON to Delivery object
  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      supplierName: json['supplier_name'] ?? '',  // Provide fallback empty string
      quantity: json['quantity'] ?? 0,
      dateDelivered: json['date_delivered'] ?? '',
      personReceiving: json['person_receiving'] ?? '',
      invoiceFile: json['invoice_file'],  // This can be null
      invoiceNumber: json['invoice_number'] ?? '',
      project: json['project'] ?? '',
      comments: json['comments'] ?? '',  // Provide fallback empty string
    );
  }

}