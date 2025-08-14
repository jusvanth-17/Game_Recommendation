import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Game {
  final int id;
  final String title;
  final String thumbnail;
  final String genre;
  final String platform;
  final String shortDescription;

  Game({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.genre,
    required this.platform,
    required this.shortDescription,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown Title',
      thumbnail: json['thumbnail'] ?? '',
      genre: json['genre'] ?? 'Unknown Genre',
      platform: json['platform'] ?? 'Unknown Platform',
      shortDescription: json['short_description'] ?? 'No description available',
    );
  }
}

class HomeScreenTest extends StatefulWidget {
  const HomeScreenTest({super.key});

  @override
  State<HomeScreenTest> createState() => _HomeScreenTestState();
}

class _HomeScreenTestState extends State<HomeScreenTest> {
  List<Game> games = [];
  List<Game> filteredGames = [];
  bool loading = true;
  String? error;
  final TextEditingController _searchController = TextEditingController();
  String selectedGenre = 'All';
  List<String> genres = ['All'];

  @override
  void initState() {
    super.initState();
    fetchGames();
    _searchController.addListener(_filterGames);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchGames() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      print('Fetching games from API...');
      final url = Uri.parse('https://www.freetogame.com/api/games');
      final response = await http.get(url);

      print('Response status: ${response.statusCode}');
      print('Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Number of games received: ${data.length}');
        
        final gamesList = data.map((e) => Game.fromJson(e)).toList();
        
        // Extract unique genres
        final Set<String> genreSet = {'All'};
        for (var game in gamesList) {
          genreSet.add(game.genre);
        }

        setState(() {
          games = gamesList;
          filteredGames = gamesList;
          genres = genreSet.toList();
          loading = false;
        });
        
        print('Games loaded successfully: ${games.length}');
      } else {
        setState(() {
          error = 'Failed to load games. Status: ${response.statusCode}';
          loading = false;
        });
        print('Error: Failed to load games. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = 'Network error: ${e.toString()}';
        loading = false;
      });
      print('Exception: ${e.toString()}');
    }
  }

  void _filterGames() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredGames = games.where((game) {
        final matchesSearch = game.title.toLowerCase().contains(query) ||
            game.genre.toLowerCase().contains(query);
        final matchesGenre = selectedGenre == 'All' || game.genre == selectedGenre;
        return matchesSearch && matchesGenre;
      }).toList();
    });
  }

  void _onGenreChanged(String? genre) {
    setState(() {
      selectedGenre = genre ?? 'All';
    });
    _filterGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Recommendations - Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: fetchGames,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Games',
          ),
        ],
      ),
      body: Column(
        children: [
          // Test User Profile Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.account_circle, size: 40),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, Test User!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'test@example.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search games...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Genre: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedGenre,
                        isExpanded: true,
                        onChanged: _onGenreChanged,
                        items: genres.map((String genre) {
                          return DropdownMenuItem<String>(
                            value: genre,
                            child: Text(genre),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Debug Info
          if (loading || error != null || games.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Debug: Loading: $loading, Error: $error, Games: ${games.length}, Filtered: ${filteredGames.length}',
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),

          // Games List
          Expanded(
            child: _buildGamesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList() {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading games...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: fetchGames,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (filteredGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No games found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchGames,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredGames.length,
        itemBuilder: (context, index) {
          final game = filteredGames[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    game.thumbnail,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        game.shortDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              game.genre,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.blue[100],
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              game.platform,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.green[100],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Show a simple dialog with game info for testing
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(game.title),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Genre: ${game.genre}'),
                                    Text('Platform: ${game.platform}'),
                                    const SizedBox(height: 8),
                                    Text(game.shortDescription),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.info_outline),
                          label: const Text('View Details'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
