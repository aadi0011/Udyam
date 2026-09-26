import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../translations.dart';

class _Product {
  final String id; // primary key from Supabase, needed to update the right row
  final String name;
  final double price;
  int stock;
  final String? imageUrl;
  _Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.imageUrl,
  });
}

class StockCatalogScreen extends StatefulWidget {
  final String languageCode;
  final String pehchanId;
  const StockCatalogScreen({
    super.key,
    required this.languageCode,
    required this.pehchanId,
  });

  @override
  State<StockCatalogScreen> createState() => _StockCatalogScreenState();
}

class _StockCatalogScreenState extends State<StockCatalogScreen> {
  final Map<String, TextEditingController> _stockControllers = {};
  List<_Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final rows = await Supabase.instance.client
          .from('Udyam-data')
          .select()
          .eq('pehchan_id', widget.pehchanId);

      final fetched = (rows as List).map((row) {
        final map = row as Map<String, dynamic>;
        return _Product(
          id: map['id'].toString(),
          name: (map['product_name'] ?? 'Unnamed').toString(),
          price: double.tryParse('${map['price']}') ?? 0,
          stock: int.tryParse('${map['stock']}') ?? 0,
          imageUrl: map['image_url'] as String?,
        );
      }).toList();

      setState(() {
        _products = fetched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load products: $e';
        _isLoading = false;
      });
    }
  }

  TextEditingController _controllerFor(_Product product) {
    return _stockControllers.putIfAbsent(
      product.id,
      () => TextEditingController(text: '${product.stock}'),
    );
  }

  @override
  void dispose() {
    for (final c in _stockControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pushStockUpdate(_Product product) async {
    try {
      await Supabase.instance.client
          .from('Udyam-data')
          .update({'stock': product.stock})
          .eq('id', product.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not update stock: $e')));
      }
    }
  }

  void _updateStock(_Product product, int delta) {
    setState(() {
      product.stock = (product.stock + delta).clamp(0, 9999);
      _controllerFor(product).text = '${product.stock}';
    });
    _pushStockUpdate(product);
  }

  void _setStockManually(_Product product, String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return;
    setState(() {
      product.stock = parsed.clamp(0, 9999);
    });
    _pushStockUpdate(product);
  }

  @override
  Widget build(BuildContext context) {
    final t = textFor(widget.languageCode);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: Text('Stock & Catalog | स्टॉक प्रबंधन | ${t.stock}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProducts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_errorMessage!, textAlign: TextAlign.center),
              ),
            )
          : _products.isEmpty
          ? const Center(child: Text('No products yet | कोई उत्पाद नहीं'))
          : RefreshIndicator(
              onRefresh: _fetchProducts,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = _products[index];
                  final stockController = _controllerFor(product);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              (product.imageUrl != null &&
                                  product.imageUrl!.isNotEmpty)
                              ? Image.network(
                                  product.imageUrl!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 56,
                                    height: 56,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '₹${product.price.toStringAsFixed(0)}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _updateStock(product, -1),
                        ),
                        SizedBox(
                          width: 56,
                          child: TextField(
                            controller: stockController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (value) =>
                                _setStockManually(product, value),
                            onEditingComplete: () => _setStockManually(
                              product,
                              stockController.text,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _updateStock(product, 1),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
