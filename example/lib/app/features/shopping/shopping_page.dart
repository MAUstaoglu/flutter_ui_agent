import 'package:flutter/material.dart';
import 'package:flutter_ui_agent/flutter_ui_agent.dart';

/// A complete e-commerce page demonstrating multi-task AI capabilities
///
/// The AI can perform complex tasks like:
/// - "Find shoes under $100, add 2 to cart, apply coupon SAVE20, and checkout"
/// - "Show me the red sneakers, add size 10 to cart"
/// - "Clear my cart and go back to home"
class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  final _searchController = TextEditingController();
  final _couponController = TextEditingController();
  final _scrollController = ScrollController();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  final List<CartItem> _cartItems = [];

  String _selectedCategory = 'all';
  double _maxPrice = 500;
  String _sortBy = 'name';
  bool _showCart = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    _allProducts = [
      Product('1', 'Running Shoes', 89.99, 'shoes', 'red', 4.5,
          'https://dummyimage.com/300x300/ff5252/ffffff&text=Running+Shoes'),
      Product('2', 'Sneakers', 129.99, 'shoes', 'blue', 4.8,
          'https://dummyimage.com/300x300/2196f3/ffffff&text=Sneakers'),
      Product('3', 'Boots', 159.99, 'shoes', 'black', 4.3,
          'https://dummyimage.com/300x300/212121/ffffff&text=Boots'),
      Product('4', 'T-Shirt', 29.99, 'clothing', 'white', 4.6,
          'https://dummyimage.com/300x300/fafafa/333333&text=T-Shirt'),
      Product('5', 'Jeans', 79.99, 'clothing', 'blue', 4.7,
          'https://dummyimage.com/300x300/1565c0/ffffff&text=Jeans'),
      Product('6', 'Jacket', 199.99, 'clothing', 'black', 4.9,
          'https://dummyimage.com/300x300/263238/ffffff&text=Jacket'),
      Product('7', 'Backpack', 49.99, 'accessories', 'gray', 4.4,
          'https://dummyimage.com/300x300/757575/ffffff&text=Backpack'),
      Product('8', 'Watch', 299.99, 'accessories', 'silver', 4.8,
          'https://dummyimage.com/300x300/bdbdbd/333333&text=Watch'),
    ];
    _filteredProducts = List.from(_allProducts);
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List.from(_allProducts);
      } else {
        _filteredProducts = _allProducts
            .where((p) =>
                p.name.toLowerCase().contains(query.toLowerCase()) ||
                p.category.toLowerCase().contains(query.toLowerCase()) ||
                p.color.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });

    final message = query.isEmpty
        ? 'Showing all products'
        : 'Searching for: $query (${_filteredProducts.length} found)';

    debugPrint('🔍 $message');
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'all') {
        _filteredProducts = List.from(_allProducts);
      } else {
        _filteredProducts =
            _allProducts.where((p) => p.category == category).toList();
      }
      _applyPriceFilter();
    });

    final message =
        'Filtered by ${category.toUpperCase()} (${_filteredProducts.length} products)';
    debugPrint('📦 $message');
  }

  void _filterByPrice(double maxPrice) {
    setState(() {
      _maxPrice = maxPrice;
      _applyPriceFilter();
    });

    final message =
        'Filtered by price: under \$${maxPrice.toStringAsFixed(0)} (${_filteredProducts.length} products)';
    debugPrint('💰 $message');
  }

  void _applyPriceFilter() {
    setState(() {
      _filteredProducts =
          _filteredProducts.where((p) => p.price <= _maxPrice).toList();
    });
  }

  void _filterByColor(String color) {
    setState(() {
      _filteredProducts = _allProducts
          .where((p) => p.color.toLowerCase() == color.toLowerCase())
          .toList();
    });

    debugPrint(
        'Filtered by color: $color (${_filteredProducts.length} products)');
  }

  void _sortProducts(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      switch (sortBy) {
        case 'price_low':
          _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_high':
          _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'rating':
          _filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        default:
          _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
      }
    });

    final sortText = sortBy == 'price_low'
        ? 'price (low to high)'
        : sortBy == 'price_high'
            ? 'price (high to low)'
            : sortBy == 'rating'
                ? 'rating'
                : 'name';

    debugPrint('📊 Sorted by $sortText');
  }

  void _addToCart(String productName, [int quantity = 1]) {
    final product = _allProducts.firstWhere(
      (p) => p.name.toLowerCase() == productName.toLowerCase(),
      orElse: () => _allProducts.first,
    );

    setState(() {
      final existingIndex =
          _cartItems.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity += quantity;
      } else {
        _cartItems.add(CartItem(product, quantity));
      }
    });

    final message = 'Added $quantity x ${product.name} to cart';
    debugPrint('🛒 $message');
  }

  void _removeFromCart(String productId) {
    final product =
        _cartItems.firstWhere((item) => item.product.id == productId).product;

    setState(() {
      _cartItems.removeWhere((item) => item.product.id == productId);
    });

    final message = 'Removed ${product.name} from cart';
    debugPrint('🗑️ $message');
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
    debugPrint('🧹 Cart cleared');
  }

  void _applyCoupon(String code) {
    // Simulate coupon validation
    final validCoupons = {
      'SAVE20': 0.20,
      'SAVE10': 0.10,
      'SAVE5': 0.05,
    };

    if (validCoupons.containsKey(code.toUpperCase())) {
      final discount = validCoupons[code.toUpperCase()]! * 100;
      final message = 'Coupon applied! $discount% off';
      debugPrint('🎫 $message');
    } else {
      debugPrint('❌ Invalid coupon code: $code');
    }
  }

  void _checkout() {
    if (_cartItems.isEmpty) {
      debugPrint('⚠️ Cart is empty');
      return;
    }

    final total = _cartItems.fold<double>(
        0, (sum, item) => sum + (item.product.price * item.quantity));
    debugPrint(
        '💳 Checkout - ${_cartItems.length} items, Total: \$${total.toStringAsFixed(2)}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Checkout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items: ${_cartItems.length}'),
            Text('Total: \$${_calculateTotal().toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('Proceeding to payment...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCart();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    return _cartItems.fold(
        0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  void _toggleCart() {
    setState(() {
      _showCart = !_showCart;
    });

    final message = _showCart
        ? 'Showing cart (${_cartItems.length} items)'
        : 'Showing products';
    debugPrint('👁️ $message');
  }

  void _viewProduct(String productId) {
    final product = _allProducts.firstWhere((p) => p.id == productId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(product.imageUrl, height: 150),
            const SizedBox(height: 16),
            Text('Price: \$${product.price}'),
            Text('Color: ${product.color}'),
            Text('Rating: ${product.rating} ⭐'),
            Text('Category: ${product.category}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addToCart(product.name);
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.grey.shade300;
      case 'gray':
        return Colors.grey;
      case 'silver':
        return Colors.grey.shade400;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Shopping'),
        actions: [
          AiActionWidget(
            actionId: 'toggle_cart_view',
            description: 'Show or hide the shopping cart',
            immediateRegistration: true,
            onExecute: _toggleCart,
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: _toggleCart,
                ),
                if (_cartItems.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_cartItems.length}',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // AI go_back action (hidden, but registers for AI commands)
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
            child: const SizedBox.shrink(),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: AiActionWidget(
              actionId: 'search_products',
              description: 'Search for products by name, category, or color',
              parameters: const [
                AgentActionParameter.string(
                  name: 'query',
                  description: 'Search keywords or category name',
                ),
              ],
              immediateRegistration: true,
              onExecuteWithParams: (params) {
                final query = params['query'] as String;
                _searchController.text = query;
                _search(query);
              },
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _search,
              ),
            ),
          ),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Category filters
                for (final category in [
                  'all',
                  'shoes',
                  'clothing',
                  'accessories'
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AiActionWidget(
                      actionId: 'filter_by_$category',
                      description: 'Filter products by $category category',
                      immediateRegistration: true,
                      onExecute: () => _filterByCategory(category),
                      child: FilterChip(
                        label: Text(category.toUpperCase()),
                        selected: _selectedCategory == category,
                        onSelected: (_) => _filterByCategory(category),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Color filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AiActionWidget(
              actionId: 'filter_by_color',
              description:
                  'Filter products by color (red, blue, black, white, gray, silver)',
              parameters: const [
                AgentActionParameter.string(
                  name: 'color',
                  description: 'Color to filter by',
                  enumValues: [
                    'red',
                    'blue',
                    'black',
                    'white',
                    'gray',
                    'silver',
                  ],
                ),
              ],
              immediateRegistration: true,
              onExecuteWithParams: (params) {
                final color = params['color'] as String;
                _filterByColor(color);
              },
              child: Wrap(
                spacing: 8,
                children: [
                  for (final color in [
                    'red',
                    'blue',
                    'black',
                    'white',
                    'gray',
                    'silver'
                  ])
                    ChoiceChip(
                      label: Text(color.toUpperCase()),
                      selected: false,
                      onSelected: (_) => _filterByColor(color),
                      avatar: CircleAvatar(
                        backgroundColor: _getColorFromString(color),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Price filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AiActionWidget(
              actionId: 'filter_by_price',
              description: 'Filter products by maximum price',
              parameters: const [
                AgentActionParameter.number(
                  name: 'maxPrice',
                  description: 'Maximum acceptable price',
                  min: 0,
                  max: 500,
                ),
              ],
              immediateRegistration: true,
              onExecuteWithParams: (params) {
                final maxPrice = (params['maxPrice'] as num).toDouble();
                _filterByPrice(maxPrice);
              },
              child: Row(
                children: [
                  const Icon(Icons.attach_money, size: 20),
                  const Text('Max Price: '),
                  Expanded(
                    child: Slider(
                      value: _maxPrice,
                      min: 0,
                      max: 500,
                      divisions: 10,
                      label: '\$${_maxPrice.toStringAsFixed(0)}',
                      onChanged: (value) {
                        setState(() => _maxPrice = value);
                        _filterByPrice(value);
                      },
                    ),
                  ),
                  Text('\$${_maxPrice.toStringAsFixed(0)}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Sort action
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AiActionWidget(
              actionId: 'sort_products',
              description:
                  'Sort products by name, price_low, price_high, or rating',
              parameters: const [
                AgentActionParameter.string(
                  name: 'sortBy',
                  description: 'Sorting method',
                  enumValues: [
                    'name',
                    'price_low',
                    'price_high',
                    'rating',
                  ],
                ),
              ],
              immediateRegistration: true,
              onExecuteWithParams: (params) {
                final sortBy = params['sortBy'] as String;
                _sortProducts(sortBy);
              },
              child: Row(
                children: [
                  const Icon(Icons.sort, size: 20),
                  const SizedBox(width: 8),
                  const Text('Sort by:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'name', label: Text('Name')),
                        ButtonSegment(
                            value: 'price_low', label: Text('Price ↑')),
                        ButtonSegment(
                            value: 'price_high', label: Text('Price ↓')),
                        ButtonSegment(value: 'rating', label: Text('Rating')),
                      ],
                      selected: {_sortBy},
                      onSelectionChanged: (Set<String> newSelection) {
                        _sortProducts(newSelection.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Product Grid or Cart View
          Expanded(
            child: _showCart ? _buildCartView() : _buildProductGrid(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Scroll to top
          AiActionWidget(
            actionId: 'scroll_to_top',
            description: 'Scroll to the top of the product list',
            immediateRegistration: true,
            onExecute: () {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
              debugPrint('Scrolled to top');
            },
            child: FloatingActionButton.small(
              heroTag: 'scroll_top',
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
            ),
          ),
          const SizedBox(height: 8),

          // Scroll to bottom
          AiActionWidget(
            actionId: 'scroll_to_bottom',
            description: 'Scroll to the bottom of the product list',
            immediateRegistration: true,
            onExecute: () {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
              debugPrint('Scrolled to bottom');
            },
            child: FloatingActionButton.small(
              heroTag: 'scroll_bottom',
              onPressed: () {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(Icons.arrow_downward),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return AiActionWidget(
          actionId: 'view_product_${product.id}',
          description: 'View details of ${product.name}',
          immediateRegistration: true,
          onExecute: () => _viewProduct(product.id),
          child: AiActionWidget(
            actionId:
                'add_${product.name.toLowerCase().replaceAll(' ', '_')}_to_cart',
            description: 'Add ${product.name} to cart',
            parameters: const [
              AgentActionParameter.integer(
                name: 'quantity',
                description: 'Number of units to add',
                min: 1,
                defaultValue: 1,
              ),
            ],
            immediateRegistration: true,
            onExecuteWithParams: (params) {
              final quantity = params['quantity'] as int? ?? 1;
              _addToCart(product.name, quantity);
            },
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        product.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${product.price}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 14, color: Colors.amber),
                                Text('${product.rating}'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                product.color,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartView() {
    if (_cartItems.isEmpty) {
      return const Center(
        child: Text('Your cart is empty'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _cartItems.length,
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              return AiActionWidget(
                actionId: 'remove_${item.product.id}_from_cart',
                description: 'Remove ${item.product.name} from cart',
                immediateRegistration: true,
                onExecute: () => _removeFromCart(item.product.id),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Image.network(item.product.imageUrl, width: 50),
                    title: Text(item.product.name),
                    subtitle:
                        Text('\$${item.product.price} x ${item.quantity}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle),
                      onPressed: () => _removeFromCart(item.product.id),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Coupon input
              Row(
                children: [
                  Expanded(
                    child: AiActionWidget(
                      actionId: 'apply_coupon',
                      description:
                          'Apply a discount coupon code (SAVE20, SAVE10, SAVE5)',
                      parameters: const [
                        AgentActionParameter.string(
                          name: 'code',
                          description: 'Coupon code to apply',
                          enumValues: ['SAVE20', 'SAVE10', 'SAVE5'],
                        ),
                      ],
                      immediateRegistration: true,
                      onExecuteWithParams: (params) {
                        final code = params['code'] as String;
                        _couponController.text = code;
                        _applyCoupon(code);
                      },
                      child: TextField(
                        controller: _couponController,
                        decoration: const InputDecoration(
                          hintText: 'Coupon code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _applyCoupon(_couponController.text),
                    child: const Text('Apply'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Total and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: \$${_calculateTotal().toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // Clear cart
                      AiActionWidget(
                        actionId: 'clear_cart',
                        description: 'Remove all items from cart',
                        immediateRegistration: true,
                        onExecute: _clearCart,
                        child: TextButton(
                          onPressed: _clearCart,
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Checkout
                      AiActionWidget(
                        actionId: 'checkout',
                        description:
                            'Proceed to checkout and complete purchase',
                        immediateRegistration: true,
                        onExecute: _checkout,
                        child: ElevatedButton(
                          onPressed: _checkout,
                          child: const Text('Checkout'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _couponController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String color;
  final double rating;
  final String imageUrl;

  Product(this.id, this.name, this.price, this.category, this.color,
      this.rating, this.imageUrl);
}

class CartItem {
  final Product product;
  int quantity;

  CartItem(this.product, this.quantity);
}
