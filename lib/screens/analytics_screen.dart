import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:products/models/models.dart';

class AnalyticsScreen extends StatefulWidget {
  final List<Category> categories;
  const AnalyticsScreen({super.key, required this.categories});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final cats = widget.categories.where((c) => c.products.isNotEmpty).toList();
    final total = cats.fold<int>(0, (sum, c) => sum + c.products.length);
    final mostStocked = cats.isEmpty
        ? 'N/A'
        : cats.reduce((a, b) => a.products.length > b.products.length ? a : b).name;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: cats.isEmpty
          ? const Center(child: Text("No products to analyze. Add some first!"))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) => setState(() {
                          touchedIndex = (response?.touchedSection?.touchedSectionIndex ?? -1);
                        }),
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: List.generate(cats.length, (i) {
                        final isTouched = i == touchedIndex;
                        final pct = (cats[i].products.length / total * 100).toStringAsFixed(1);
                        return PieChartSectionData(
                          color: cats[i].color,
                          value: cats[i].products.length.toDouble(),
                          title: '$pct%',
                          radius: isTouched ? 60 : 50,
                          titleStyle: TextStyle(
                            fontSize: isTouched ? 16 : 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text("Summary",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _statCard(context, "Total Items", total.toString(), Icons.inventory_2,
                    Theme.of(context).colorScheme.primary),
                _statCard(context, "Most Stocked", mostStocked, Icons.star_rounded,
                    Colors.amber.shade700),
              ],
            ),
    );
  }

  Widget _statCard(BuildContext context, String title, String value, IconData icon, Color color) =>
      Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: Icon(icon, color: color, size: 32),
          title: Text(title,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7))),
          subtitle: Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
      );
}
