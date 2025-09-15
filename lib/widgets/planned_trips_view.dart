import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/trip_details_page.dart';
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:flutter_application_1/widgets/trip_map_painter.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

// Enhanced color palette
const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kSecondaryBlue = Color(0xFF3B82F6);
const Color kAccentBlue = Color(0xFF60A5FA);
const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kGreyText = Color(0xFF475569);
const Color kLightGrey = Color(0xFF94A3B8);
const Color kSurfaceWhite = Color(0xFFFAFAFA);

enum ViewMode { grid, map, list }
class PlannedTripsView extends StatefulWidget {
  final List<Trip> plannedTrips;
  final List<Trip> previousTrips;
  final bool showMapView; // This parameter is now correctly defined

  const PlannedTripsView({
    super.key,
    required this.plannedTrips,
    this.previousTrips = const [],
    required this.showMapView, // It is required
  });

  @override
  State<PlannedTripsView> createState() => _PlannedTripsViewState();
}


class _PlannedTripsViewState extends State<PlannedTripsView> with TickerProviderStateMixin {
  ViewMode _currentViewMode = ViewMode.grid;
  late List<AnimationController> _cardAnimationControllers;
  
  // Map control variables
  Offset _mapCenter = const Offset(0, 0);
  double _zoomLevel = 1.0;
  bool _showRoutes = true;
  bool _showPreviousTrips = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(covariant PlannedTripsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.plannedTrips.length != oldWidget.plannedTrips.length) {
      _disposeAnimations();
      _initializeAnimations();
    }
  }

  void _initializeAnimations() {
    _cardAnimationControllers = List.generate(
      widget.plannedTrips.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      )..forward(),
    );
  }

  void _disposeAnimations() {
    for (var controller in _cardAnimationControllers) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeAnimations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildViewModeSelector(),
        const SizedBox(height: 16),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildCurrentView(),
          ),
        ),
      ],
    );
  }

  Widget _buildViewModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ]
      ),
      child: Row(
        children: [
          _buildViewModeButton(icon: Icons.grid_view_rounded, mode: ViewMode.grid, label: 'Grid'),
          _buildViewModeButton(icon: Icons.map_outlined, mode: ViewMode.map, label: 'Map'),
          _buildViewModeButton(icon: Icons.list_alt_rounded, mode: ViewMode.list, label: 'List'),
        ],
      ),
    );
  }

  Widget _buildViewModeButton({required IconData icon, required ViewMode mode, required String label}) {
    final isSelected = _currentViewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentViewMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : kGreyText),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : kGreyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentViewMode) {
      case ViewMode.grid: return _buildGridView();
      case ViewMode.map: return _buildInteractiveMapView();
      case ViewMode.list: return _buildListView();
    }
  }

  Widget _buildAnimatedItem(Widget child, int index) {
     if (index >= _cardAnimationControllers.length) return child; // Safety check
    final controller = _cardAnimationControllers[index];
    return FadeTransition(
      opacity: CurvedAnimation(parent: controller, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero)
            .animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  // --- Grid View Implementation ---
  Widget _buildGridView() {
    return GridView.builder(
      key: const ValueKey('grid'),
      padding: const EdgeInsets.only(top: 8, bottom: 80, left: 4, right: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75),
      itemCount: widget.plannedTrips.length,
      itemBuilder: (context, index) => _buildAnimatedItem(_buildTripCard(widget.plannedTrips[index]), index),
    );
  }
  
  Widget _buildTripCard(Trip trip) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToTripDetails(trip),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(tag: trip.imageUrl, child: CachedNetworkImage(imageUrl: trip.imageUrl, fit: BoxFit.cover)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.black.withAlpha(153), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.center),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.name,
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, shadows: const [Shadow(blurRadius: 10)])),
                  const SizedBox(height: 4),
                  Text(_getDaysUntilTrip(trip.plannedDate),
                      style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- List View Implementation ---
  Widget _buildListView() {
    return ListView.builder(
      key: const ValueKey('list'),
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: widget.plannedTrips.length,
      itemBuilder: (context, index) => _buildAnimatedItem(_buildTripListItem(widget.plannedTrips[index]), index),
    );
  }
  
  Widget _buildTripListItem(Trip trip) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToTripDetails(trip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Hero(
                    tag: trip.imageUrl,
                    child: CachedNetworkImage(
                        imageUrl: trip.imageUrl, width: 80, height: 80, fit: BoxFit.cover),
                  )),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: kDarkBlue)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: kGreyText, size: 14),
                        const SizedBox(width: 4),
                        Expanded(child: Text(trip.location, style: GoogleFonts.poppins(fontSize: 13, color: kGreyText), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(_getDaysUntilTrip(trip.plannedDate), style: GoogleFonts.poppins(fontSize: 12, color: kSecondaryBlue, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: kLightGrey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // --- Map View Implementation ---
  Widget _buildInteractiveMapView() {
    return Container(
      key: const ValueKey('map'),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 4))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildMapHeader(),
            Expanded(child: LayoutBuilder(builder: (context, constraints) {
              return Stack(
                children: [
                  _buildCustomMap(constraints),
                  _buildMapControls(),
                  _buildMapLegend(),
                ],
              );
            })),
            _buildTripTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [kPrimaryBlue, kSecondaryBlue]),
      ),
      child: Row(
        children: [
          const Icon(Icons.map_outlined, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your Journey Map',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          _buildMapToggleButtons(),
        ],
      ),
    );
  }

  Widget _buildMapToggleButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToggleButton('Routes', _showRoutes, Icons.route_outlined, (value) => setState(() => _showRoutes = value)),
        const SizedBox(width: 8),
        _buildToggleButton('History', _showPreviousTrips, Icons.history, (value) => setState(() => _showPreviousTrips = value)),
      ],
    );
  }
  
  Widget _buildToggleButton(String label, bool value, IconData icon, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: value ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomMap(BoxConstraints constraints) {
    return GestureDetector(
      onPanUpdate: (details) => setState(() => _mapCenter += details.delta / _zoomLevel),
      onScaleUpdate: (details) => setState(() => _zoomLevel = (_zoomLevel * details.scale).clamp(0.5, 3.0)),
      child: CustomPaint(
        size: constraints.biggest,
        painter: TripMapPainter(
          plannedTrips: widget.plannedTrips,
          previousTrips: widget.previousTrips,
          mapCenter: _mapCenter,
          zoomLevel: _zoomLevel,
          showRoutes: _showRoutes,
          showPreviousTrips: _showPreviousTrips,
        ),
        child: Stack(children: _buildMapPins(constraints.biggest)),
      ),
    );
  }

  List<Widget> _buildMapPins(Size size) {
    List<Widget> pins = [];
    final allTrips = [
      ...widget.plannedTrips.map((t) => {'trip': t, 'isPlanned': true}),
      if (_showPreviousTrips) ...widget.previousTrips.map((t) => {'trip': t, 'isPlanned': false}),
    ];

    for (int i = 0; i < allTrips.length; i++) {
      final tripData = allTrips[i];
      final Trip trip = tripData['trip'] as Trip;
      final bool isPlanned = tripData['isPlanned'] as bool;
      final position = _getMapPosition(size, i, allTrips.length, isPrevious: !isPlanned);

      pins.add(Positioned(
          left: position.dx - 25,
          top: position.dy - 60,
          child: _buildAnimatedMapPin(trip: trip, index: i, isPlanned: isPlanned)));
    }
    return pins;
  }
  
  Offset _getMapPosition(Size size, int index, int total, {bool isPrevious = false}) {
      final centerX = (size.width / 2) - _mapCenter.dx * _zoomLevel;
      final centerY = (size.height / 2) - _mapCenter.dy * _zoomLevel;

      if (isPrevious) {
        final angle = (index * 2.3) + 0.5;
        final radius = (size.width / 5 + (index * 10)) * _zoomLevel;
        return Offset(centerX + radius * math.cos(angle), centerY + radius * math.sin(angle));
      } else {
        final angle = (index * 2 * math.pi / total);
        final radius = (size.width / 3.5 + (index * 8)) * _zoomLevel;
        return Offset(centerX + radius * math.cos(angle), centerY + radius * math.sin(angle));
      }
  }

  Widget _buildAnimatedMapPin({required Trip trip, required int index, required bool isPlanned}) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 800 + (index * 150)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () => _navigateToTripDetails(trip),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(trip.name,
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: kDarkBlue)),
                      Text(DateFormat('MMM dd').format(trip.plannedDate),
                          style: GoogleFonts.poppins(fontSize: 8, color: kGreyText)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: isPlanned ? 36 : 30,
                  height: isPlanned ? 36 : 30,
                  decoration: BoxDecoration(
                    color: isPlanned ? kPrimaryBlue : kAccentBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: (isPlanned ? kPrimaryBlue : kAccentBlue).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: Icon(isPlanned ? Icons.flight_takeoff : Icons.check, color: Colors.white, size: isPlanned ? 16 : 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMapControls() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Column(
        children: [
          FloatingActionButton.small(heroTag: "zoom_in", onPressed: () => setState(() => _zoomLevel = (_zoomLevel * 1.2).clamp(0.5, 3.0)), backgroundColor: Colors.white, child: const Icon(Icons.add, color: kPrimaryBlue)),
          const SizedBox(height: 8),
          FloatingActionButton.small(heroTag: "zoom_out", onPressed: () => setState(() => _zoomLevel = (_zoomLevel / 1.2).clamp(0.5, 3.0)), backgroundColor: Colors.white, child: const Icon(Icons.remove, color: kPrimaryBlue)),
          const SizedBox(height: 8),
          FloatingActionButton.small(heroTag: "center_map", onPressed: () => setState(() {_mapCenter = const Offset(0, 0); _zoomLevel = 1.0;}), backgroundColor: Colors.white, child: const Icon(Icons.center_focus_strong, color: kPrimaryBlue)),
        ],
      ),
    );
  }
  
  Widget _buildMapLegend() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Legend', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12, color: kDarkBlue)),
            const SizedBox(height: 8),
            _buildLegendItem(color: kPrimaryBlue, icon: Icons.flight_takeoff, label: 'Planned Trips'),
            if (_showPreviousTrips) ...[
              const SizedBox(height: 4),
              _buildLegendItem(color: kAccentBlue, icon: Icons.check, label: 'Completed Trips'),
            ],
            if (_showRoutes) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 20, height: 2, decoration: BoxDecoration(color: kSecondaryBlue, borderRadius: BorderRadius.circular(1))),
                  const SizedBox(width: 6),
                  Text('Routes', style: GoogleFonts.poppins(fontSize: 10, color: kGreyText)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildLegendItem({required Color color, required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 12),
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: kGreyText)),
      ],
    );
  }

  Widget _buildTripTimeline() {
    final allTrips = [...widget.plannedTrips, ...widget.previousTrips];
    allTrips.sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
    
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceWhite.withOpacity(0.8),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trip Timeline', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: kDarkBlue)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allTrips.length,
              itemBuilder: (context, index) {
                final trip = allTrips[index];
                final isPlanned = widget.plannedTrips.contains(trip);
                
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPlanned ? Colors.white : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isPlanned ? kPrimaryBlue.withOpacity(0.3) : Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isPlanned ? kPrimaryBlue : kAccentBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(isPlanned ? Icons.flight_takeoff : Icons.check, color: Colors.white, size: 12),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(trip.name,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12, color: kDarkBlue),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(DateFormat('MMM dd, yyyy').format(trip.plannedDate),
                          style: GoogleFonts.poppins(fontSize: 10, color: kGreyText)),
                      const SizedBox(height: 2),
                      Text(
                        isPlanned ? _getDaysUntilTrip(trip.plannedDate) : 'Completed',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: isPlanned ? kSecondaryBlue : Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTripDetails(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailsPage(trip: trip),
      ),
    );
  }

  String _getDaysUntilTrip(DateTime plannedDate) {
    final now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final tripDay = DateTime(plannedDate.year, plannedDate.month, plannedDate.day);
    final difference = tripDay.difference(now).inDays;

    if (difference < 0) return '${difference.abs()} days ago';
    if (difference == 0) return 'Trip is today';
    if (difference == 1) return 'Trip is tomorrow';
    return 'In $difference days';
  }
}