import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../clasess/app_snackbar.dart';

class NameOnlySaleContractPage extends StatefulWidget {
  final String? contractId;
  const NameOnlySaleContractPage({super.key, this.contractId});

  @override
  State<NameOnlySaleContractPage> createState() =>
      _NameOnlySaleContractPageState();
}

class _NameOnlySaleContractPageState extends State<NameOnlySaleContractPage> {
  final _formKey = GlobalKey<FormState>();

  final _sellerName = TextEditingController();
  final _buyerName = TextEditingController();
  final _sellerSign = TextEditingController();
  final _buyerSign = TextEditingController();
  final _itemDesc = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController();
  final _sellerNationalId = TextEditingController();
  final _buyerNationalId = TextEditingController();

  bool _agreeSeller = false;
  bool _agreeBuyer = false;

  @override
  void dispose() {
    _sellerName.dispose();
    _buyerName.dispose();
    _sellerSign.dispose();
    _buyerSign.dispose();
    _itemDesc.dispose();
    _price.dispose();
    _city.dispose();
    _sellerNationalId.dispose();
    _buyerNationalId.dispose();
    super.dispose();
  }

  Future<void> _saveToFirestore() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeSeller || !_agreeBuyer) {
      AppSnackBar.show(context, "يجب تأكيد الموافقة من الطرفين",
          backgroundColor: Theme.of(context).colorScheme.error,
          icon: Icons.error_outline);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final contractData = {
      "sellerName": _sellerName.text,
      "buyerName": _buyerName.text,
      "sellerNationalId": _sellerNationalId.text,
      "buyerNationalId": _buyerNationalId.text,
      "itemDescription": _itemDesc.text,
      "price": _price.text,
      "city": _city.text,
      "sellerSignature": _sellerSign.text,
      "buyerSignature": _buyerSign.text,
      "date": intl.DateFormat('yyyy-MM-dd').format(DateTime.now()),
      "createdBy": user.uid,
      "createdAt": FieldValue.serverTimestamp(),
    };

    final docRef = widget.contractId != null
        ? FirebaseFirestore.instance
        .collection("contracts")
        .doc(widget.contractId)
        : FirebaseFirestore.instance.collection("contracts").doc();

    await docRef.set(contractData);

    if (!mounted) return;

    AppSnackBar.show(context, "تم حفظ العقد بنجاح",
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icons.check_circle);

    _showContractOptions(contractData);
  }

  void _showContractOptions(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.picture_as_pdf,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text("توليد ومشاركة PDF"),
              onTap: () {
                Navigator.pop(context);
                _generatePdf(data);
              },
            ),
            ListTile(
              leading: Icon(Icons.done,
                  color: Theme.of(context).colorScheme.secondary),
              title: const Text("إنهاء"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 🖨️ إنشاء PDF
  Future<void> _generatePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text("عقد بيع",
                      style: pw.TextStyle(
                          fontSize: 22, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 20),
                pw.Text("اسم البائع: ${data['sellerName']}"),
                pw.Text("الرقم الوطني للبائع: ${data['sellerNationalId']}"),
                pw.Text("اسم المشتري: ${data['buyerName']}"),
                pw.Text("الرقم الوطني للمشتري: ${data['buyerNationalId']}"),
                pw.SizedBox(height: 10),
                pw.Text("الوصف: ${data['itemDescription']}"),
                pw.Text("السعر: ${data['price']}"),
                pw.Text("المدينة: ${data['city']}"),
                pw.SizedBox(height: 10),
                pw.Text("توقيع البائع: ${data['sellerSignature']}"),
                pw.Text("توقيع المشتري: ${data['buyerSignature']}"),
                pw.SizedBox(height: 20),
                pw.Text("التاريخ: ${data['date']}"),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'sale_contract.pdf',
    );
  }

  Widget _field(String label, TextEditingController c,
      {int maxLines = 1,
        bool required = false,
        TextInputType? keyboard}) {
    final colors = Theme.of(context).colorScheme;

    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: GoogleFonts.cairo(),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
      validator: (val) {
        if (required && (val == null || val.trim().isEmpty)) {
          return "الحقل مطلوب";
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("عقد بيع"),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _field("اسم البائع", _sellerName, required: true),
                  const SizedBox(height: 12),
                  _field("الرقم الوطني للبائع", _sellerNationalId,
                      keyboard: TextInputType.number, required: true),
                  const SizedBox(height: 12),
                  _field("اسم المشتري", _buyerName, required: true),
                  const SizedBox(height: 12),
                  _field("الرقم الوطني للمشتري", _buyerNationalId,
                      keyboard: TextInputType.number, required: true),
                  const SizedBox(height: 12),
                  _field("وصف المبيع", _itemDesc, maxLines: 3, required: true),
                  const SizedBox(height: 12),
                  _field("السعر", _price,
                      keyboard: TextInputType.number, required: true),
                  const SizedBox(height: 12),
                  _field("المدينة", _city, required: true),
                  const SizedBox(height: 12),
                  _field("توقيع البائع (بالاسم)", _sellerSign, required: true),
                  const SizedBox(height: 12),
                  _field("توقيع المشتري (بالاسم)", _buyerSign, required: true),
                  const SizedBox(height: 20),

                  // ✅ الشروط
                  Card(
                    color: colors.surfaceVariant,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        "الشروط والأحكام:\n"
                            "1- يلتزم البائع بتسليم المبيع بالحالة المتفق عليها.\n"
                            "2- يلتزم المشتري بدفع المبلغ المتفق عليه كاملاً.\n"
                            "3- يعتبر توقيع الطرفين إقراراً بالقبول بجميع البنود.",
                      ),
                    ),
                  ),

                  CheckboxListTile(
                    value: _agreeSeller,
                    onChanged: (v) =>
                        setState(() => _agreeSeller = v ?? false),
                    title: const Text("أُقر أنا البائع بموافقتي على الشروط"),
                    activeColor: colors.primary,
                  ),
                  CheckboxListTile(
                    value: _agreeBuyer,
                    onChanged: (v) =>
                        setState(() => _agreeBuyer = v ?? false),
                    title: const Text("أُقر أنا المشتري بموافقتي على الشروط"),
                    activeColor: colors.primary,
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _saveToFirestore,
                    icon: const Icon(Icons.save),
                    label: const Text("حفظ العقد"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
