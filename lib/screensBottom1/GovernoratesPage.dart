// lib/screensBottom1/GovernoratesPage.dart
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:untitled1/screensBottom1/screen2.dart'; // فيها CategoriesScreen

class GovernoratesPage extends StatefulWidget {
  final bool isAdmin; // ✅ نضيف isAdmin

  const GovernoratesPage({super.key, this.isAdmin = false});

  @override
  State<GovernoratesPage> createState() => _GovernoratesPageState();
}

class _GovernoratesPageState extends State<GovernoratesPage> {
  final List<String> governorates = const [
    'عمّان','إربد','الزرقاء','العقبة','الكرك',
    'الطفيلة','مأدبا','جرش','عجلون','المفرق','معان',
  ];

  final TextEditingController _searchC = TextEditingController();
  String? selectedGovernorate;

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          title: Text(
            'اختر المحافظة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'المحافظة',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    color: isLight ? Colors.black87 : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Dropdown
              DropdownButton2<String>(
                isExpanded: true,
                hint: Text(
                  'اختر محافظة',
                  style: GoogleFonts.cairo(
                    color: isLight ? Colors.grey[600] : cs.onSurfaceVariant,
                  ),
                ),
                value: selectedGovernorate,
                items: _buildDropdownItems(),
                onChanged: (val) => setState(() => selectedGovernorate = val),
                buttonStyleData: ButtonStyleData(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary, width: 1.1),
                  ),
                ),
                iconStyleData: IconStyleData(
                  icon: Icon(Icons.keyboard_arrow_down, color: cs.primary),
                ),
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 320,
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                ),
                dropdownSearchData: DropdownSearchData(
                  searchController: _searchC,
                  searchInnerWidgetHeight: 56,
                  searchInnerWidget: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _searchC,
                      style: GoogleFonts.cairo(),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن المحافظة…',
                        hintStyle: GoogleFonts.cairo(),
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: isLight
                            ? Colors.white
                            : cs.surfaceContainerHighest,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        suffixIcon: _searchC.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchC.clear();
                            setState(() {});
                          },
                        )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  searchMatchFn: (item, search) {
                    final v = (item.value ?? '').toString();
                    return v.contains(search);
                  },
                ),
                onMenuStateChange: (isOpen) {
                  if (!isOpen) _searchC.clear();
                },
              ),

              const Spacer(),

              // زر متابعة
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  label: Text(
                    'متابعة',
                    style: GoogleFonts.cairo(fontSize: 16),
                  ),
                  onPressed: selectedGovernorate == null
                      ? null
                      : () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoriesScreen(
                          governorate: selectedGovernorate!,
                          isAdmin: widget.isAdmin, // ✅ تمرير isAdmin
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems() {
    final filteredItems =
    governorates.where((g) => g.contains(_searchC.text)).toList();

    if (filteredItems.isEmpty) {
      return [
        const DropdownMenuItem<String>(
          value: null,
          child: Center(
            child: Text('لا توجد نتائج', style: TextStyle(color: Colors.grey)),
          ),
        )
      ];
    }

    return filteredItems
        .map(
          (g) => DropdownMenuItem<String>(
        value: g,
        child: Text(g, style: GoogleFonts.cairo(fontSize: 16)),
      ),
    )
        .toList();
  }
}
