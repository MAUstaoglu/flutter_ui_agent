import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_ui_agent/flutter_ui_agent.dart';
import 'package:http/http.dart' as http;

class PokedexPage extends StatefulWidget {
  const PokedexPage({super.key});

  @override
  State<PokedexPage> createState() => _PokedexPageState();
}

class _PokedexPageState extends State<PokedexPage> {
  List<Pokemon> _pokemonList = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadPokemon();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPokemon() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final offset = _currentPage * _limit;
      final response = await http.get(
        Uri.parse(
            'https://pokeapi.co/api/v2/pokemon?limit=$_limit&offset=$offset'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];

        // Fetch detailed info for each Pokemon
        final List<Pokemon> newPokemon = [];
        for (var i = 0; i < results.length; i++) {
          final pokemonData = results[i];
          final detailResponse = await http.get(Uri.parse(pokemonData['url']));

          if (detailResponse.statusCode == 200) {
            final detail = json.decode(detailResponse.body);
            newPokemon.add(Pokemon.fromJson(detail));
          }
        }

        if (mounted) {
          setState(() {
            _pokemonList.addAll(newPokemon);
            _currentPage++;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load Pokemon';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshPokemon() async {
    if (mounted) {
      setState(() {
        _pokemonList.clear();
        _currentPage = 0;
      });
    }
    await _loadPokemon();

    debugPrint('🔄 Pokedex refreshed!');
  }

  void _searchPokemon(String query) async {
    if (query.isEmpty) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon/${query.toLowerCase()}'),
      );

      if (response.statusCode == 200) {
        final detail = json.decode(response.body);
        final pokemon = Pokemon.fromJson(detail);

        if (mounted) {
          setState(() {
            _pokemonList = [pokemon];
            _isLoading = false;
          });

          debugPrint('Found ${pokemon.name}!');
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Pokemon not found';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error searching: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _filterByType(String type) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/type/${type.toLowerCase()}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List pokemonEntries = data['pokemon'];

        final List<Pokemon> filteredPokemon = [];
        // Only fetch first 20 to avoid too many requests
        for (var i = 0;
            i < (pokemonEntries.length > 20 ? 20 : pokemonEntries.length);
            i++) {
          final entry = pokemonEntries[i];
          final detailResponse =
              await http.get(Uri.parse(entry['pokemon']['url']));

          if (detailResponse.statusCode == 200) {
            final detail = json.decode(detailResponse.body);
            filteredPokemon.add(Pokemon.fromJson(detail));
          }
        }

        if (mounted) {
          setState(() {
            _pokemonList = filteredPokemon;
            _isLoading = false;
          });

          debugPrint('Filtered by $type type');
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Type not found';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error filtering: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokedex'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          AiActionWidget(
            actionId: 'refresh_pokedex',
            description: 'Refresh and reload the Pokedex list',
            onExecute: _refreshPokemon,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshPokemon,
              tooltip: 'Refresh',
            ),
          ),
          AiActionWidget(
            actionId: 'scroll_pokedex_top',
            description: 'Scroll to the top of the Pokedex',
            onExecute: _scrollToTop,
            child: IconButton(
              icon: const Icon(Icons.arrow_upward),
              onPressed: _scrollToTop,
              tooltip: 'Scroll to top',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Hidden action to go back to home
          AiActionWidget(
            actionId: 'go_back',
            description: 'Go back to home page, return to main screen',
            immediateRegistration: true,
            onExecuteAsync: () async {
              if (mounted) {
                Navigator.pop(context);
                await Future.delayed(const Duration(milliseconds: 500));
              }
            },
            child: const SizedBox.shrink(), // Hidden action
          ),
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              children: [
                // Search Pokemon
                AiActionWidget(
                  actionId: 'search_pokemon',
                  immediateRegistration:
                      true, // Keep registered even during rebuilds
                  description: 'Search for a specific Pokemon by name or ID',
                  parameters: const [
                    AgentActionParameter.string(
                      name: 'name',
                      description: 'Pokemon name or Pokédex ID',
                    ),
                  ],
                  onExecuteWithParams: (params) {
                    final name = params['name'] as String?;
                    if (name != null && name.isNotEmpty) {
                      _searchPokemon(name);
                    }
                  },
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Pokemon (e.g., pikachu, 25)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: _searchPokemon,
                  ),
                ),
                const SizedBox(height: 12),
                // Show Pokemon Details (invisible widget, just for AI action registration)
                AiActionWidget(
                  actionId: 'show_pokemon_details',
                  immediateRegistration:
                      true, // Keep registered even during rebuilds
                  description:
                      'Search for and show detailed information about a specific Pokemon by name (e.g., Pikachu, Charmander, Bulbasaur, Squirtle)',
                  parameters: const [
                    AgentActionParameter.string(
                      name: 'name',
                      description: 'Pokemon name to display',
                    ),
                  ],
                  onExecuteWithParams: (params) async {
                    final name = params['name'] as String?;
                    if (name != null && name.isNotEmpty) {
                      // First search for the Pokemon
                      _searchPokemon(name);
                      // Wait a bit for the search to complete
                      await Future.delayed(const Duration(milliseconds: 500));
                      // If we have results, show the first one
                      if (_pokemonList.isNotEmpty) {
                        _showPokemonDetails(_pokemonList.first);
                      }
                    }
                  },
                  child: const SizedBox.shrink(), // Invisible widget
                ),
                // Type Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Filter by type: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      ..._buildTypeFilters(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Pokemon List
          Expanded(
            child: _isLoading && _pokemonList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_errorMessage),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshPokemon,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _pokemonList.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _pokemonList.length) {
                            return _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : ElevatedButton(
                                    onPressed: _loadPokemon,
                                    child: const Text('Load More'),
                                  );
                          }
                          return _buildPokemonCard(_pokemonList[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTypeFilters() {
    final types = ['fire', 'water', 'grass', 'electric', 'psychic', 'dragon'];
    return types.map((type) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: AiActionWidget(
          actionId: 'filter_by_$type',
          description: 'Filter Pokemon by $type type',
          onExecute: () => _filterByType(type),
          child: FilterChip(
            label: Text(type.toUpperCase()),
            onSelected: (_) => _filterByType(type),
            backgroundColor: _getTypeColor(type).withAlpha(77),
            selectedColor: _getTypeColor(type),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPokemonCard(Pokemon pokemon) {
    return AiActionWidget(
      actionId: 'view_pokemon_${pokemon.id}',
      description: 'View details of ${pokemon.name}',
      onExecute: () {
        _showPokemonDetails(pokemon);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showPokemonDetails(pokemon),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'pokemon_${pokemon.id}',
                child: Image.network(
                  pokemon.imageUrl,
                  height: 100,
                  width: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.catching_pokemon, size: 100);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '#${pokemon.id.toString().padLeft(3, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                pokemon.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: pokemon.types
                    .map((type) => Chip(
                          label: Text(
                            type,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white),
                          ),
                          backgroundColor: _getTypeColor(type),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPokemonDetails(Pokemon pokemon) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pokemon.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '#${pokemon.id.toString().padLeft(3, '0')}',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Hero(
                tag: 'pokemon_${pokemon.id}',
                child: Image.network(
                  pokemon.imageUrl,
                  height: 150,
                  width: 150,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: pokemon.types
                    .map((type) => Chip(
                          label: Text(type.toUpperCase(),
                              style: const TextStyle(color: Colors.white)),
                          backgroundColor: _getTypeColor(type),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('HP', pokemon.hp),
                  _buildStatItem('ATK', pokemon.attack),
                  _buildStatItem('DEF', pokemon.defense),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Colors.orange;
      case 'water':
        return Colors.blue;
      case 'grass':
        return Colors.green;
      case 'electric':
        return Colors.yellow[700]!;
      case 'psychic':
        return Colors.purple;
      case 'dragon':
        return Colors.indigo;
      case 'normal':
        return Colors.grey;
      case 'fighting':
        return Colors.red[800]!;
      case 'flying':
        return Colors.lightBlue;
      case 'poison':
        return Colors.deepPurple;
      case 'ground':
        return Colors.brown;
      case 'rock':
        return Colors.grey[700]!;
      case 'bug':
        return Colors.lightGreen;
      case 'ghost':
        return Colors.deepPurple[300]!;
      case 'steel':
        return Colors.blueGrey;
      case 'ice':
        return Colors.cyan;
      case 'fairy':
        return Colors.pink;
      case 'dark':
        return Colors.brown[800]!;
      default:
        return Colors.grey;
    }
  }
}

class Pokemon {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;
  final int hp;
  final int attack;
  final int defense;

  Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
    required this.hp,
    required this.attack,
    required this.defense,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as List;
    return Pokemon(
      id: json['id'],
      name: json['name'],
      imageUrl: json['sprites']['other']['official-artwork']['front_default'] ??
          json['sprites']['front_default'] ??
          '',
      types: (json['types'] as List)
          .map((t) => t['type']['name'] as String)
          .toList(),
      hp: stats.firstWhere((s) => s['stat']['name'] == 'hp')['base_stat'],
      attack:
          stats.firstWhere((s) => s['stat']['name'] == 'attack')['base_stat'],
      defense:
          stats.firstWhere((s) => s['stat']['name'] == 'defense')['base_stat'],
    );
  }
}
