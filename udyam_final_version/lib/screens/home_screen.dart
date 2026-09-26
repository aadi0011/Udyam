import 'package:flutter/material.dart';

import '../translations.dart';
import 'login_screen.dart';
import 'sell_product_screen.dart';
import 'stock_catalog_screen.dart';

class HomeScreen extends StatelessWidget {
  final String languageCode;
  final String pehchanId;

  const HomeScreen({
    super.key,
    required this.languageCode,
    required this.pehchanId,
  });

  void _showAccountCenter(BuildContext context) {
    final t = textFor(languageCode);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${t.accountCenter} | Account Center'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel | रद्द करें'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // TODO: once real auth is wired up, also call
              // supabase.auth.signOut() here before navigating away.
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(
              '${t.logout} | Logout',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = textFor(languageCode);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: const Text('Home | होम'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: '${t.accountCenter} | Account Center',
            onPressed: () => _showAccountCenter(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HomeButton(
              label: 'Sell Product | उत्पाद बेचें | ${t.sell}',
              icon: Icons.add_shopping_cart,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SellProductScreen(
                    languageCode: languageCode,
                    pehchanId: pehchanId,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _HomeButton(
              label: 'Stock & Catalog | स्टॉक प्रबंधन | ${t.stock}',
              icon: Icons.inventory_2,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StockCatalogScreen(
                    languageCode: languageCode,
                    pehchanId: pehchanId,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange.shade50,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, color: Colors.deepOrange),
        onPressed: onTap,
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: const TextStyle(fontSize: 15)),
        ),
      ),
    );
  }
}
