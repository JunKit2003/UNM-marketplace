// api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'product.dart'; // Import the Product model

class ApiService {
  static Future<List<Product>> fetchProducts() async {
    final response =
        await http.get(Uri.parse('https://api.youruniversity.com/products'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((product) => Product.fromJson(product)).toList();
    } else {
      throw Exception('Failed to load products from the API');
    }
  }
}
