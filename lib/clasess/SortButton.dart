import 'package:flutter/material.dart';

class SortItem {
  final String value;
  final String label;
  const SortItem(this.value, this.label);
}

class SortButton extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final List<SortItem> items;
  const SortButton({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'فرز',
      onSelected: onChanged,
      itemBuilder: (_) => items
          .map((e) => PopupMenuItem<String>(value: e.value, child: Text(e.label)))
          .toList(),
      icon: const Icon(Icons.sort),
    );
  }
}
