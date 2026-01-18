import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AutoPartsApiService {
  static const String _baseUrl = 'https://auto-parts-catalog.p.rapidapi.com';
  static const String _apiKey =
      '6659a45db5msh997ca542425dbd7p1d6ee8jsn2a43e71fa05c';
  static const String _apiHost = 'auto-parts-catalog.p.rapidapi.com';

  /// Search for parts by keyword
  Future<List<AutoPart>> searchParts(String keyword) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/articles/search?keyword=$keyword'),
        headers: {'x-rapidapi-key': _apiKey, 'x-rapidapi-host': _apiHost},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List? ?? [];
        return articles.map((article) => AutoPart.fromJson(article)).toList();
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to search parts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Search parts error: $e');
      throw Exception('Failed to search parts: $e');
    }
  }

  /// Get part details by article ID
  Future<AutoPartDetail?> getPartDetails(
    String articleId, {
    String langId = '16',
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/articles/get-article-category/article-id/$articleId/lang-id/$langId',
        ),
        headers: {'x-rapidapi-key': _apiKey, 'x-rapidapi-host': _apiHost},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AutoPartDetail.fromJson(data);
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Get part details error: $e');
      return null;
    }
  }

  /// Get parts by vehicle (brand, model, year)
  Future<List<AutoPart>> getPartsByVehicle({
    required String brand,
    required String model,
    String? year,
  }) async {
    try {
      final queryParams = {
        'brand': brand,
        'model': model,
        if (year != null) 'year': year,
      };

      final uri = Uri.parse(
        '$_baseUrl/articles/by-vehicle',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'x-rapidapi-key': _apiKey, 'x-rapidapi-host': _apiHost},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List? ?? [];
        return articles.map((article) => AutoPart.fromJson(article)).toList();
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        throw Exception(
          'Failed to get parts by vehicle: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Get parts by vehicle error: $e');
      throw Exception('Failed to get parts by vehicle: $e');
    }
  }
}

/// Model for Auto Part from API
class AutoPart {
  final String articleId;
  final String articleNumber;
  final String brandName;
  final String description;
  final String? category;
  final double? price;

  AutoPart({
    required this.articleId,
    required this.articleNumber,
    required this.brandName,
    required this.description,
    this.category,
    this.price,
  });

  factory AutoPart.fromJson(Map<String, dynamic> json) {
    return AutoPart(
      articleId: json['articleId']?.toString() ?? '',
      articleNumber: json['articleNumber']?.toString() ?? '',
      brandName: json['brandName']?.toString() ?? '',
      description: json['description']?.toString() ?? 'No description',
      category: json['category']?.toString(),
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'articleId': articleId,
      'articleNumber': articleNumber,
      'brandName': brandName,
      'description': description,
      'category': category,
      'price': price,
    };
  }
}

/// Model for detailed Auto Part information
class AutoPartDetail {
  final String articleId;
  final String articleNumber;
  final String brandName;
  final String description;
  final String category;
  final List<String> applicableVehicles;
  final Map<String, dynamic> specifications;

  AutoPartDetail({
    required this.articleId,
    required this.articleNumber,
    required this.brandName,
    required this.description,
    required this.category,
    required this.applicableVehicles,
    required this.specifications,
  });

  factory AutoPartDetail.fromJson(Map<String, dynamic> json) {
    return AutoPartDetail(
      articleId: json['articleId']?.toString() ?? '',
      articleNumber: json['articleNumber']?.toString() ?? '',
      brandName: json['brandName']?.toString() ?? '',
      description: json['description']?.toString() ?? 'No description',
      category: json['category']?.toString() ?? 'General',
      applicableVehicles:
          (json['applicableVehicles'] as List?)
              ?.map((v) => v.toString())
              .toList() ??
          [],
      specifications: json['specifications'] as Map<String, dynamic>? ?? {},
    );
  }
}
