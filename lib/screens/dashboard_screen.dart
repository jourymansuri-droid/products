// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:products/models/models.dart';

class DashboardScreen extends StatelessWidget {
  final List<Category> categories;
  final Map<String, dynamic> settings;
  final Function(Category) onNavigateToCategory;

  const DashboardScreen({
    super.key,
    required this.categories,
    required this.settings,
    required this.onNavigateToCategory,
  });

  @override
  Widget build(BuildContext context) {
    final expiringDays = settings['expiringSoonDays'] ?? 7;
    final now = DateTime.now();
    final expiringProducts = categories
        .expand((c) => c.products)
        .where((p) {
          final diff = p.expiryDate.difference(now).inDays;
          return diff >= 0 && diff < expiringDays;
        })
        .toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    final totalProducts = categories.isNotEmpty
        ? categories.map((c) => c.products.length).reduce((a, b) => a + b)
        : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(children: [
                    const Icon(Icons.category, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text("${categories.length} Categories",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  Row(children: [
                    const Icon(Icons.inventory_2, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text("$totalProducts Items",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text("Expiring Soon (Next $expiringDays Days)",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          if (expiringProducts.isEmpty)
            const Card(
              child: ListTile(
                leading:
                    Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text("Nothing is expiring soon!"),
              ),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: expiringProducts.length,
                itemBuilder: (context, i) {
                  final p = expiringProducts[i];
                  final c = categories.firstWhere((cat) => cat.products.contains(p));
                  final daysLeft = p.expiryDate.difference(now).inDays + 1;
                  return SizedBox(
                    width: 160,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(c.name,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const Spacer(),
                            Text("$daysLeft days left",
                                style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 24),
          const Text("All Categories",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final c = categories[i];
              return Card(
                child: InkWell(
                  onTap: () => onNavigateToCategory(c),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(c.icon, size: 32, color: c.color),
                        const SizedBox(height: 12),
                        Text(c.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        const Spacer(),
                        Text("${c.products.length} items",
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
