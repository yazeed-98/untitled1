import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../clasess/rating_sheet.dart' show RatingService;
import '../clasess/report_dialog.dart' show ReportService;
import 'offersDetail.dart';


class OffersPage extends StatefulWidget {
  final bool isAdmin;

  const OffersPage({super.key, this.isAdmin = false});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  List<Map<String, dynamic>> _offers = [];
  final Set<String> _favs = {};

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    final snap = await FirebaseFirestore.instance.collection('offers').get();
    setState(() {
      _offers = snap.docs.map((doc) {
        final d = doc.data();
        d['id'] = doc.id;
        d['ref'] = doc.reference;
        return d;
      }).toList();
    });
  }

  double _avg(Map<String, dynamic> data) {
    final ratings = (data['ratings'] as Map?) ?? {};
    if (ratings.isEmpty) return 0;
    final values = ratings.values.map((e) => (e as num).toDouble()).toList();
    return values.reduce((a, b) => a + b) / values.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("العروض"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _offers.length,
        itemBuilder: (context, i) {
          final o = _offers[i];
          final avg = _avg(o);
          final id = o['id'] as String;
          final ref = o['ref'] as DocumentReference<Map<String, dynamic>>;

          return OfferCard(
            offer: o,
            rating: avg,
            isFavorite: _favs.contains(id),
            onFavoriteChanged: (v) => setState(() {
              v ? _favs.add(id) : _favs.remove(id);
            }),
            isAdmin: widget.isAdmin,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OfferDetailsPage(offer: o),
                ),
              );
            },
            onRate: () => RatingService.ratePlace(
              context,
              ref: ref,
              placeName: (o['title'] ?? '') as String,
            ),
            onReport: () => ReportService.reportPlace(
              context,
              placeType: 'offer',
              placeId: id,
              placeName: (o['title'] ?? '') as String,
            ),
          );
        },
      ),
    );
  }
}

class OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final double rating;
  final bool isFavorite;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onRate;
  final VoidCallback onReport;
  final ValueChanged<bool> onFavoriteChanged;

  const OfferCard({
    super.key,
    required this.offer,
    required this.rating,
    required this.isFavorite,
    required this.onFavoriteChanged,
    required this.onTap,
    required this.onRate,
    required this.onReport,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((offer['image'] ?? '').isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    offer['image'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                offer['title'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "المكان: ${offer['placeName'] ?? ''} (${offer['placeType'] ?? ''})",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 18),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1)),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red[400],
                    ),
                    onPressed: () => onFavoriteChanged(!isFavorite),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onRate,
                    icon: const Icon(Icons.star_rate),
                    label: const Text("قيّم"),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.report),
                    label: const Text("إبلاغ"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
