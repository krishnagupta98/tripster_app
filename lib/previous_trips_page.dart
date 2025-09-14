import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/planned_trips_page.dart'; 
import 'package:flutter_application_1/models/trip_model.dart';
import 'package:intl/intl.dart';

// Enhanced color palette
const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kSecondaryBlue = Color(0xFF3B82F6);
const Color kAccentBlue = Color(0xFF60A5FA);
const Color kDarkBlue = Color(0xFF1E3A8A);
const Color kLightBlue = Color(0xFFF0F4FF);
const Color kGreyText = Color(0xFF475569);
const Color kLightGrey = Color(0xFF94A3B8);
const Color kSurfaceWhite = Color(0xFFFAFAFA);

enum ViewMode { grid, map, list }

class PlannedTripsView extends StatefulWidget {
  final List<Trip> plannedTrips;

  const PlannedTripsView({
    super.key,
    required this.plannedTrips,
  });

  @override
  State<PlannedTripsView> createState() => _PlannedTripsViewState();
}

class _PlannedTripsViewState extends State<PlannedTripsView> with TickerProviderStateMixin {
  ViewMode _currentViewMode = ViewMode.grid;
  late AnimationController _animationController;
  late List<AnimationController> _cardAnimationControllers;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    
    // Initialize animation controllers for each card
    _cardAnimationControllers = List.generate(
      widget.plannedTrips.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 600 + (index * 100)),
        vsync: this,
      )..forward(),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _cardAnimationControllers) {
      controller.dispose();
    }
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
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
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
      ),
      child: Row(
        children: [
          _buildViewModeButton(
            icon: Icons.grid_view_rounded,
            mode: ViewMode.grid,
            label: 'Grid',
          ),
          _buildViewModeButton(
            icon: Icons.map_outlined,
            mode: ViewMode.map,
            label: 'Map',
          ),
          _buildViewModeButton(
            icon: Icons.list_alt_rounded,
            mode: ViewMode.list,
            label: 'List',
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required ViewMode mode,
    required String label,
  }) {
    final isSelected = _currentViewMode == mode;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentViewMode = mode;
          });
          _animationController.reset();
          _animationController.forward();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : kGreyText,
              ),
              const SizedBox(width: 6),
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
      case ViewMode.grid:
        return _buildGridView();
      case ViewMode.map:
        return _buildMapView();
      case ViewMode.list:
        return _buildListView();
    }
  }

  Widget _buildGridView() {
    return GridView.builder(
      key: const ValueKey('grid_view'),
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: widget.plannedTrips.length,
      itemBuilder: (context, index) {
        final trip = widget.plannedTrips[index];
        return _buildTripCard(trip, index);
      },
    );
  }

  Widget _buildTripCard(Trip trip, int index) {
    // Ensure we have enough animation controllers
    if (index >= _cardAnimationControllers.length) {
      return _buildStaticTripCard(trip);
    }
    
    return AnimatedBuilder(
      animation: _cardAnimationControllers[index],
      builder: (context, child) {
        final animation = CurvedAnimation(
          parent: _cardAnimationControllers[index],
          curve: Curves.easeOutBack,
        );
        
        return Transform.scale(
          scale: animation.value,
          child: _buildStaticTripCard(trip),
        );
      },
    );
  }

  Widget _buildStaticTripCard(Trip trip) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () => _navigateToTripDetails(trip),
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'trip_image_${trip.location}',
                  child: CachedNetworkImage(
                    imageUrl: trip.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: kLightBlue,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: kLightBlue,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: kGreyText,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                    ),
                  ),
                ),
                // Content overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          trip.location,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM dd, yyyy').format(trip.plannedDate),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Status indicator
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getTripStatus(trip.plannedDate) == 'Upcoming'
                          ? kAccentBlue
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getTripStatus(trip.plannedDate),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      key: const ValueKey('map_view'),
      margin: const EdgeInsets.only(bottom: 80),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Map Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryBlue, kSecondaryBlue],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Trip Locations',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.plannedTrips.length} trips',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Placeholder Map (you can integrate with Google Maps or similar)
            Expanded(
              child: Container(
                width: double.infinity,
                color: kLightBlue,
                child: Stack(
                  children: [
                    // Map placeholder background
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1519302959554-a75be0afc82a?ixlib=rb-4.0.3&auto=format&fit=crop&w=2000&q=80',
                          ),
                          fit: BoxFit.cover,
                          opacity: 0.3,
                        ),
                      ),
                    ),
                    // Location pins
                    ...widget.plannedTrips.asMap().entries.map((entry) {
                      int index = entry.key;
                      Trip trip = entry.value;
                      return Positioned(
                        left: (index * 80.0) + 50,
                        top: (index * 60.0) + 80,
                        child: _buildMapPin(trip, index),
                      );
                    }).toList(),
                    // Map controls
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FloatingActionButton.small(
                            heroTag: "zoom_in",
                            onPressed: () {},
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.add, color: kPrimaryBlue),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: "zoom_out",
                            onPressed: () {},
                            backgroundColor: Colors.white,
                            child: const Icon(Icons.remove, color: kPrimaryBlue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Trip timeline at bottom
            Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.plannedTrips.length,
                itemBuilder: (context, index) {
                  final trip = widget.plannedTrips[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kSurfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.location,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: kDarkBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(trip.plannedDate),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: kGreyText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_outlined,
                              size: 14,
                              color: kGreyText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getDaysUntilTrip(trip.plannedDate),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: kGreyText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPin(Trip trip, int index) {
    return GestureDetector(
      onTap: () => _navigateToTripDetails(trip),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              trip.location,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: kDarkBlue,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPrimaryBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      key: const ValueKey('list_view'),
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: widget.plannedTrips.length,
      itemBuilder: (context, index) {
        final trip = widget.plannedTrips[index];
        return _buildListItem(trip, index);
      },
    );
  }

  Widget _buildListItem(Trip trip, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToTripDetails(trip),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Trip image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: CachedNetworkImage(
                      imageUrl: trip.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: kLightBlue,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: kLightBlue,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Trip details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.location,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kDarkBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: kGreyText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('EEEE, MMM dd, yyyy').format(trip.plannedDate),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: kGreyText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_outlined,
                            size: 16,
                            color: kGreyText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getDaysUntilTrip(trip.plannedDate),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: kGreyText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status and arrow
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTripStatus(trip.plannedDate) == 'Upcoming'
                            ? kAccentBlue.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getTripStatus(trip.plannedDate),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getTripStatus(trip.plannedDate) == 'Upcoming'
                              ? kAccentBlue
                              : Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: kLightGrey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTripStatus(DateTime plannedDate) {
    final now = DateTime.now();
    final difference = plannedDate.difference(now).inDays;
    
    if (difference < 0) {
      return 'Overdue';
    } else if (difference <= 7) {
      return 'This Week';
    } else {
      return 'Upcoming';
    }
  }

  String _getDaysUntilTrip(DateTime plannedDate) {
    final now = DateTime.now();
    final difference = plannedDate.difference(now).inDays;
    
    if (difference < 0) {
      return '${difference.abs()} days overdue';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else {
      return 'In $difference days';
    }
  }

  void _navigateToTripDetails(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlannedTripsPage(plannedTrips: widget.plannedTrips),
      ),
    );
  }
}