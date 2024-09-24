import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

// HomeBloc with initial data load, search, and category filter logic
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final List<Map<String, dynamic>> _data = [
    {
      "id": 1,
      "slk_id": "SLK001",
      "supplier": "Supplier A",
      "quantity": 34,
      "serial_number": "SN001",
      "tag_number": "TAG001",
      "datetime": "2024-09-04T13:13:28+03:00",
      "invoice_number": "1292jyg",
      "invoice": "/media/invoices/Attachment_Information_Form.docx",
      "comments": "Delivered on time",
      "project": "Project Alpha",
      "location_name": "University of Nairobi",
      "received_by_name": "Kenet",
      "asset_name": "Router",
      "category": "Networking Equipment",
      "status": "instore"
    },
    {
      "id": 2,
      "slk_id": "SLK002",
      "supplier": "Supplier B",
      "quantity": 3,
      "serial_number": "SN002",
      "tag_number": "TAG002",
      "datetime": "2024-09-05T09:56:30+03:00",
      "invoice_number": "235435345hy",
      "invoice": "/media/invoices/Attachment_Information_Form.docx.pdf",
      "comments": "Pending approval",
      "project": "Project Beta",
      "location_name": "University of Nairobi",
      "received_by_name": "NewUser",
      "asset_name": "Chair",
      "category": "Furniture",
      "status": "pendingDispatch"
    },
    {
      "id": 3,
      "slk_id": "SLK003",
      "supplier": "Supplier C",
      "quantity": 45,
      "serial_number": "SN003",
      "tag_number": "TAG003",
      "datetime": "2024-09-06T10:00:00+03:00",
      "invoice_number": "INV001",
      "invoice": "/media/invoices/invoice_A.pdf",
      "comments": "Delivered on time",
      "project": "Project Gamma",
      "location_name": "Location A",
      "received_by_name": "Alice",
      "asset_name": "Switch Hub",
      "category": "Networking Equipment",
      "status": "onsite"
    },
    {
      "id": 4,
      "slk_id": "SLK004",
      "supplier": "Supplier D",
      "quantity": 20,
      "serial_number": "SN004",
      "tag_number": "TAG004",
      "datetime": "2024-09-07T11:30:00+03:00",
      "invoice_number": "INV002",
      "invoice": "/media/invoices/invoice_B.pdf",
      "comments": "Pending review",
      "project": "Project Delta",
      "location_name": "Location B",
      "received_by_name": "Bob",
      "asset_name": "Mobile Phone",
      "category": "Electronics",
      "status": "pendingDispatch"
    },
    {
      "id": 5,
      "slk_id": "SLK005",
      "supplier": "Supplier E",
      "quantity": 15,
      "serial_number": "SN005",
      "tag_number": "TAG005",
      "datetime": "2024-09-08T12:45:00+03:00",
      "invoice_number": "INV003",
      "invoice": "/media/invoices/invoice_C.pdf",
      "comments": "Requires follow-up",
      "project": "Project Epsilon",
      "location_name": "Location C",
      "received_by_name": "Charlie",
      "asset_name": "System Unit",
      "category": "Computers",
      "status": "instore"
    },
    {
      "id": 6,
      "slk_id": "SLK006",
      "supplier": "Supplier F",
      "quantity": 10,
      "serial_number": "SN006",
      "tag_number": "TAG006",
      "datetime": "2024-09-09T08:30:00+03:00",
      "invoice_number": "INV004",
      "invoice": "/media/invoices/invoice_D.pdf",
      "comments": "Ready for pickup",
      "project": "Project Zeta",
      "location_name": "Location D",
      "received_by_name": "David",
      "asset_name": "Monitor",
      "category": "Electronics",
      "status": "onsite"
    },
    {
      "id": 7,
      "slk_id": "SLK007",
      "supplier": "Supplier G",
      "quantity": 5,
      "serial_number": "SN007",
      "tag_number": "TAG007",
      "datetime": "2024-09-09T14:00:00+03:00",
      "invoice_number": "INV005",
      "invoice": "/media/invoices/invoice_E.pdf",
      "comments": "In use",
      "project": "Project Eta",
      "location_name": "Location E",
      "received_by_name": "Eve",
      "asset_name": "Office Table",
      "category": "Furniture",
      "status": "instore"
    },
    {
      "id": 8,
      "slk_id": "SLK008",
      "supplier": "Supplier H",
      "quantity": 8,
      "serial_number": "SN008",
      "tag_number": "TAG008",
      "datetime": "2024-09-10T10:15:00+03:00",
      "invoice_number": "INV006",
      "invoice": "/media/invoices/invoice_F.pdf",
      "comments": "Delivered successfully",
      "project": "Project Theta",
      "location_name": "Location F",
      "received_by_name": "Frank",
      "asset_name": "Server",
      "category": "Servers",
      "status": "onsite"
    },
    // New items
    {
      "id": 9,
      "slk_id": "SLK009",
      "supplier": "Supplier I",
      "quantity": 25,
      "serial_number": "SN009",
      "tag_number": "TAG009",
      "datetime": "2024-09-11T09:00:00+03:00",
      "invoice_number": "INV007",
      "invoice": "/media/invoices/invoice_G.pdf",
      "comments": "Awaiting delivery",
      "project": "Project Iota",
      "location_name": "Location G",
      "received_by_name": "George",
      "asset_name": "Laptop",
      "category": "Computers",
      "status": "pendingDispatch"
    },
    {
      "id": 10,
      "slk_id": "SLK010",
      "supplier": "Supplier J",
      "quantity": 12,
      "serial_number": "SN010",
      "tag_number": "TAG010",
      "datetime": "2024-09-12T15:30:00+03:00",
      "invoice_number": "INV008",
      "invoice": "/media/invoices/invoice_H.pdf",
      "comments": "Returned",
      "project": "Project Kappa",
      "location_name": "Location H",
      "received_by_name": "Hannah",
      "asset_name": "Projector",
      "category": "Electronics",
      "status": "instore"
    },
    {
      "id": 11,
      "slk_id": "SLK011",
      "supplier": "Supplier K",
      "quantity": 9,
      "serial_number": "SN011",
      "tag_number": "TAG011",
      "datetime": "2024-09-13T11:00:00+03:00",
      "invoice_number": "INV009",
      "invoice": "/media/invoices/invoice_I.pdf",
      "comments": "In transit",
      "project": "Project Lambda",
      "location_name": "Location I",
      "received_by_name": "Isaac",
      "asset_name": "Hard Drive",
      "category": "Storage",
      "status": "pendingDispatch"
    },
    {
      "id": 12,
      "slk_id": "SLK012",
      "supplier": "Supplier L",
      "quantity": 14,
      "serial_number": "SN012",
      "tag_number": "TAG012",
      "datetime": "2024-09-14T13:45:00+03:00",
      "invoice_number": "INV010",
      "invoice": "/media/invoices/invoice_J.pdf",
      "comments": "To be assembled",
      "project": "Project Mu",
      "location_name": "Location J",
      "received_by_name": "Jack",
      "asset_name": "3D Printer",
      "category": "Office Equipment",
      "status": "pendingDispatch"
    },
    {
      "id": 13,
      "slk_id": "SLK013",
      "supplier": "Supplier M",
      "quantity": 22,
      "serial_number": "SN013",
      "tag_number": "TAG013",
      "datetime": "2024-09-15T16:00:00+03:00",
      "invoice_number": "INV011",
      "invoice": "/media/invoices/invoice_K.pdf",
      "comments": "Scheduled for maintenance",
      "project": "Project Nu",
      "location_name": "Location K",
      "received_by_name": "Kelly",
      "asset_name": "Scanner",
      "category": "Office Equipment",
      "status": "instore"
    }
  ];



  HomeBloc() : super(HomeInitial()) {
    // Handle initial data load
    on<LoadHomeDataEvent>((event, emit) async {
      emit(HomeLoading());
      try {
        await Future.delayed(Duration(seconds: 1)); // Simulating delay
        emit(HomeLoaded(items: _data)); // Load all initial data
      } catch (error) {
        emit(HomeError('Failed to load initial home data.'));
      }
    });

    // Handle search
    on<SearchHomeEvent>((event, emit) async {
      emit(HomeLoading());

      try {
        await Future.delayed(Duration(seconds: 1)); // Simulating delay
        final filteredItems = _data.where((item) {
          return item['tag_number'].toLowerCase().contains(event.query.toLowerCase()) ||
              item['serial_number'].toLowerCase().contains(event.query.toLowerCase()) ||
              item['invoice_number'].toLowerCase().contains(event.query.toLowerCase()) ||
              item['asset_name'].toLowerCase().contains(event.query.toLowerCase());
        }).toList();

        emit(HomeLoaded(items: filteredItems)); // Load filtered data based on search
      } catch (error) {
        emit(HomeError('Failed to load search results.'));
      }
    });

    // Handle category filtering
    on<FilterByCategoryEvent>((event, emit) async {
      emit(HomeLoading());

      try {
        await Future.delayed(Duration(seconds: 1)); // Simulating delay
        final filteredItems = _data.where((item) {
          return item['category'] == event.category;
        }).toList();

        emit(HomeLoaded(items: filteredItems)); // Load filtered data based on category
      } catch (error) {
        emit(HomeError('Failed to load category filter results.'));
      }
    });
  }
}

// Event class
abstract class HomeEvent {}

// Event to load initial data
class LoadHomeDataEvent extends HomeEvent {}

// Event to search data
class SearchHomeEvent extends HomeEvent {
  final String query;

  SearchHomeEvent({required this.query});
}

// Event to filter items by category
class FilterByCategoryEvent extends HomeEvent {
  final String category;

  FilterByCategoryEvent({required this.category});
}

// State classes
abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Map<String, dynamic>> items;

  HomeLoaded({required this.items});
}

class HomeError extends HomeState {
  final String message;

  HomeError(this.message);
}
