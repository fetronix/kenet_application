// allUrls.dart

class ApiUrls {
  static const String baseUrl = 'http://197.136.16.164:8000/app';
  static const String basewebsitelinks = 'http://197.136.16.164:8000';

  // Authentication Endpoints
  static const String login = '$baseUrl/api/login/';

  static const String Appversion = 'http://197.136.16.164:8000/api/latest_version/';


  //adding consignment  Ednpoints
  static const String supplierurl = '$baseUrl/api/suppliers/';
  static const String addconsignmenturl = '$baseUrl/delivery/new/';


  static const String usersrurl = '$baseUrl/api/users/';
  static const String usersadminurl = '$baseUrl/api/user-checkouts/';


  // Checkout Endpoints
  static const String checkoutList = '$baseUrl/checkoutsadmin/';
  static const String checkoutuserList = '$baseUrl/checkouts/';
  static const String checkoutDetail = '$baseUrl/checkout/';
  static String getCheckoutDetail(int checkoutId) => '$checkoutDetail$checkoutId/';
  static String rejectCheckoutDetail(int checkoutId) => '$checkoutDetail/$checkoutId/reject/';
  static String approveCheckoutDetail(int checkoutId) => '$checkoutDetail$checkoutId/approve/';
  static String updateCheckoutDetail(int checkoutId) => '$checkoutDetail$checkoutId/update/';
  static String updateuserCheckoutDetail(int checkoutId) => '$checkoutDetail$checkoutId/update/user/';

  // Asset Endpoints
  static const String assetList = '$baseUrl/api/assets/';
  static String getAssetDetail(int assetId) => '$baseUrl/assets/$assetId/';  // Asset endpoint with assetId
  static String faultyAssetDetail(int assetId) => '$baseUrl/assets/$assetId/return_faulty/';  // Asset endpoint with assetId
  static String decommissionedAssetDetail(int assetId) => '$baseUrl/assets/$assetId/return_decommissioned/';  // Asset endpoint with assetId
  static String removecart(int assetId) => '$baseUrl/cart/remove/$assetId/';  // Asset endpoint with assetId



  // Additional Asset URL
  static const String apiUrl = '$baseUrl/assets/'; // For general asset requests

  // Category Endpoints
  static const String categoryApiUrl = '$baseUrl/api/categories/';  // Category API

  // Delivery Endpoints
  static const String deliveryApiUrl = '$baseUrl/api/mydeliveries/';  // Deliveries API
  static const String deliveryallApiUrl = '$baseUrl/api/delivery/';  // Deliveries API

  // Location Endpoints
  static const String locationApiUrl = '$baseUrl/api/locations/';  // Location API



  // Cart Endpoints
  static const String cartList = '$baseUrl/cart/';
  static String addToCart(int assetId) => '$baseUrl/cart/add/$assetId/';


  // Location Endpoints
  static const String locationList = '$baseUrl/locations/';
  static const String addLocation = '$baseUrl/locations/add/';


  // Auth Endpoints
  static const String passwordReset = '$baseUrl/password_reset/';

  // Signature Endpoints
  static const String uploadSignature = '$baseUrl/signature/upload/';
  static const String signatureDetail = '$baseUrl/signature';
  static String getSignatureDetail(int signatureId) => '$signatureDetail/$signatureId/';


  static const String adminportal = '$basewebsitelinks/admin/';


  // Utility function to generate any URL with an ID
  static String withId(String url, int id) => '$url/$id/';
}
