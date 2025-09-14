// lib/previous_trip_details_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/models/previous_trip_model.dart';

class PreviousTripDetailsPage extends StatefulWidget {
  final PreviousTrip trip;
  const PreviousTripDetailsPage({super.key, required this.trip});

  @override
  State<PreviousTripDetailsPage> createState() =>
      _PreviousTripDetailsPageState();
}

class _PreviousTripDetailsPageState extends State<PreviousTripDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Show FAB only on the Expenses tab (index 1)
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        setState(() {
          _showFab = true;
        });
      } else {
        setState(() {
          _showFab = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 1,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(widget.trip.baseTrip.location,
                    style: GoogleFonts.playfairDisplay(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                background: Hero(
                  tag: widget.trip.baseTrip.imageUrl,
                  child: CachedNetworkImage(
                    imageUrl: widget.trip.baseTrip.imageUrl,
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.4),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1565C0),
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: const Color(0xFF2196F3),
                tabs: const [
                  Tab(icon: Icon(Icons.info_outline), text: "Details"),
                  Tab(icon: Icon(Icons.receipt_long_outlined), text: "Expenses"),
                  Tab(icon: Icon(Icons.photo_library_outlined), text: "Photos"),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDetailsTab(),
            _buildExpensesTab(),
            _buildPhotosTab(),
          ],
        ),
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              onPressed: () {
                // Placeholder to add a new expense
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Add new expense form would appear here.")));
              },
              backgroundColor: const Color(0xFF2196F3),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // --- UI for the Details Tab ---
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailItem(
            icon: Icons.calendar_today,
            title: 'Trip Date',
            content:
                DateFormat('MMMM d, yyyy').format(widget.trip.baseTrip.plannedDate),
          ),
          const SizedBox(height: 24),
          _buildDetailItem(
            icon: Icons.notes,
            title: 'Notes',
            content: widget.trip.baseTrip.notes,
          ),
          const SizedBox(height: 24),
          Text(
            'Activities',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 8),
          ...widget.trip.baseTrip.activities.map((activity) => Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline,
                      color: Color(0xFF2196F3)),
                  title: Text(activity, style: GoogleFonts.poppins()),
                ),
              )),
        ],
      ),
    );
  }

  // --- UI for the Expenses Tab ---
  Widget _buildExpensesTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Total Expenses', style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[700])),
                const SizedBox(height: 8),
                Text(
                  '₹${widget.trip.totalExpenses.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1565C0)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...widget.trip.expenses.map((expense) => Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(expense.icon, color: const Color(0xFF2196F3)),
                title: Text(expense.description, style: GoogleFonts.poppins()),
                trailing: Text('₹${expense.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            )),
      ],
    );
  }

  // --- UI for the Photos Tab ---
  Widget _buildPhotosTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: widget.trip.photos.length,
      itemBuilder: (context, index) {
        final photo = widget.trip.photos[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: GridTile(
            footer: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo.location,
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy').format(photo.date),
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            child: CachedNetworkImage(
              imageUrl: photo.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        );
      },
    );
  }
  
  // Helper widget for the Details Tab
  Widget _buildDetailItem({required IconData icon, required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF2196F3), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1565C0)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28.0),
          child: Text(
            content,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87, height: 1.5),
          ),
        ),
      ],
    );
  }
}