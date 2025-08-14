import 'dart:convert';
import 'package:http/http.dart' as http;

class RawgApiService {
  static const String apiKey = 'c8ec13985b404f939ac18c7d96e8df08';
  static const String baseUrl = 'https://api.rawg.io/api';

  Future<List<dynamic>> fetchPlatforms() async {
    final url = Uri.parse('$baseUrl/platforms?key=$apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load platforms');
    }
  }

  Future<List<dynamic>> fetchGames({
    required String startDate,
    required String endDate,
    required List<int> platformIds,
  }) async {
    final platformsStr = platformIds.join(',');
    final url = Uri.parse(
      '$baseUrl/games?key=$apiKey&dates=$startDate,$endDate&platforms=$platformsStr',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load games');
    }
  }

  Future<Map<String, dynamic>> fetchGameDetails(int gameId) async {
    final url = Uri.parse('$baseUrl/games/$gameId?key=$apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load game details');
    }
  }
}

class RawgGame {
  final int id;
  final String name;
  final String backgroundImage;
  final String? genre;
  final String? platform;

  RawgGame({
    required this.id,
    required this.name,
    required this.backgroundImage,
    this.genre,
    this.platform,
  });

  factory RawgGame.fromJson(Map<String, dynamic> json) {
    return RawgGame(
      id: json['id'],
      name: json['name'],
      backgroundImage: json['background_image'] ?? '',
      genre: (json['genres'] as List).isNotEmpty
          ? json['genres'][0]['name']
          : null,
      platform: (json['platforms'] as List).isNotEmpty
          ? json['platforms'][0]['platform']['name']
          : null,
    );
  }
}
