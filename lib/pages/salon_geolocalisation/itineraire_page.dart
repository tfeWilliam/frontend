import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/salon_details_geo.dart';
import '../../services/geoapify_service/geoapify_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'enum/enum.dart';

class ItinerairePage extends StatefulWidget {
  final SalonDetailsForGeo salon;
  final Color primaryColor;
  final Color accentColor;

  const ItinerairePage({
    super.key,
    required this.salon,
    this.primaryColor = const Color(0xFF8E44AD),
    this.accentColor = const Color(0xFFE67E22),
  });

  @override
  State<ItinerairePage> createState() => _ItinerairePageState();
}

class _ItinerairePageState extends State<ItinerairePage>
    with TickerProviderStateMixin {

  // 📍 État de géolocalisation
  LatLng? userLocation;
  LatLng? salonLocation;
  bool isLoadingLocation = true;
  bool hasLocationPermission = false;

  // 🛣️ État de l'itinéraire
  RouteResult? currentRoute;
  bool isLoadingRoute = false;
  TransportMode selectedMode = TransportMode.drive;

  // 🅿️ Parkings proches
  List<POI> nearbyParking = [];
  bool showParking = false;

  // 🗺️ Contrôleur de carte
  final MapController mapController = MapController();

  // 🎨 Animation
  late AnimationController _fabAnimationController;
  late AnimationController _routeInfoAnimationController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeLocation();
  }

  void _initAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _routeInfoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _routeInfoAnimationController.dispose();
    super.dispose();
  }

  /// 📍 Initialiser la géolocalisation
  Future<void> _initializeLocation() async {
    setState(() => isLoadingLocation = true);

    try {
      // Vérifier et demander les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationPermissionDialog();
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        setState(() => hasLocationPermission = true);

        // Obtenir la position utilisateur
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Position du salon
        final salonPos = LatLng(
          widget.salon.latitude ?? 0.0,
          widget.salon.longitude ?? 0.0,
        );

        setState(() {
          userLocation = LatLng(position.latitude, position.longitude);
          salonLocation = salonPos;
          isLoadingLocation = false;
        });

        // Calculer l'itinéraire automatiquement
        await _calculateRoute();

        // Animer vers la vue de l'itinéraire
        _centerMapOnRoute();

        // Charger les parkings proches
        _loadNearbyParking();

        _fabAnimationController.forward();
      }
    } catch (e) {
      setState(() => isLoadingLocation = false);
      _showErrorDialog("Erreur de localisation", e.toString());
    }
  }

  /// 🛣️ Calculer l'itinéraire
  Future<void> _calculateRoute() async {
    if (userLocation == null || salonLocation == null) return;

    setState(() => isLoadingRoute = true);

    try {
      final route = await GeoapifyService.getRoute(
        start: userLocation!,
        end: salonLocation!,
        mode: selectedMode,
      );

      setState(() {
        currentRoute = route;
        isLoadingRoute = false;
      });

      if (route != null) {
        _routeInfoAnimationController.forward();
        // ✅ Vibration optionnelle
        try {
          // Vibration disponible seulement sur mobile
          // Vous pouvez commenter cette ligne si le package vibration n'est pas installé
          // if (await Vibration.hasVibrator() ?? false) {
          //   Vibration.vibrate(duration: 100);
          // }
        } catch (e) {
          print("ℹ️ Vibration non disponible: $e");
        }
      } else {
        // 🚌 Gestion spéciale pour le transport public
        if (selectedMode == TransportMode.transit) {
          _showTransportNotAvailableDialog();
        } else {
          _showErrorDialog("Erreur d'itinéraire",
              "Impossible de calculer l'itinéraire avec le mode ${_getTransportLabel(selectedMode).toLowerCase()}");
        }
      }
    } catch (e) {
      setState(() => isLoadingRoute = false);
      _showErrorDialog("Erreur", e.toString());
    }
  }

  /// 🅿️ Charger les parkings proches
  Future<void> _loadNearbyParking() async {
    if (salonLocation == null) return;

    try {
      final parking = await GeoapifyService.findNearbyParking(salonLocation!);
      setState(() {
        nearbyParking = parking;
      });
    } catch (e) {
      print("❌ Erreur chargement parking: $e");
    }
  }

  /// 🗺️ Centrer la carte sur l'itinéraire
  void _centerMapOnRoute() {
    if (userLocation != null && salonLocation != null) {
      // ✅ Calculer le centre et zoom manuellement
      final latitudes = [userLocation!.latitude, salonLocation!.latitude];
      final longitudes = [userLocation!.longitude, salonLocation!.longitude];

      final centerLat = (latitudes[0] + latitudes[1]) / 2;
      final centerLng = (longitudes[0] + longitudes[1]) / 2;
      final center = LatLng(centerLat, centerLng);

      // Calculer un zoom approprié basé sur la distance
      final distance = Geolocator.distanceBetween(
        userLocation!.latitude, userLocation!.longitude,
        salonLocation!.latitude, salonLocation!.longitude,
      );

      double zoom;
      if (distance < 1000) {
        zoom = 15.0;
      } else if (distance < 5000) {
        zoom = 13.0;
      } else if (distance < 10000) {
        zoom = 12.0;
      } else {
        zoom = 10.0;
      }

      mapController.move(center, zoom);
    }
  }

  /// 📱 Ouvrir dans une app de navigation externe
  Future<void> _openInExternalApp(String app) async {
    if (salonLocation == null) return;

    String url;
    switch (app) {
      case 'google':
        url = 'https://www.google.com/maps/dir/?api=1&destination=${salonLocation!.latitude},${salonLocation!.longitude}';
        break;
      case 'waze':
        url = 'https://waze.com/ul?ll=${salonLocation!.latitude},${salonLocation!.longitude}&navigate=yes';
        break;
      case 'apple':
        url = 'http://maps.apple.com/?daddr=${salonLocation!.latitude},${salonLocation!.longitude}';
        break;
      default:
        return;
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _showErrorDialog("Erreur", "Impossible d'ouvrir $app Maps");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: widget.primaryColor,
        elevation: 0,
        title: Text(
          "Itinéraire",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1, // Index pour "Rechercher"
        onTap: (index) {
          // Navigation gérée par BottomNavBar
        },
      ),
    );
  }

  Widget _buildExternalAppsButton() {
    return Positioned(
      top: 80,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: PopupMenuButton<String>(
          icon: Icon(Icons.open_in_new, color: widget.primaryColor),
          onSelected: _openInExternalApp,
          tooltip: "Ouvrir dans une autre app",
          itemBuilder: (context) => [
            PopupMenuItem(value: 'google', child: Row(
              children: [
                Icon(Icons.map, color: Colors.blue),
                SizedBox(width: 8),
                Text('Google Maps'),
              ],
            )),
            PopupMenuItem(value: 'waze', child: Row(
              children: [
                Icon(Icons.navigation, color: Colors.orange),
                SizedBox(width: 8),
                Text('Waze'),
              ],
            )),
            PopupMenuItem(value: 'apple', child: Row(
              children: [
                Icon(Icons.map_outlined, color: Colors.grey),
                SizedBox(width: 8),
                Text('Apple Maps'),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Positioned(
      bottom: 100, // Au-dessus de la bottom nav bar
      left: 16,
      right: 16,
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabAnimationController,
          curve: Curves.easeOut,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 🅿️ Bouton Parking
            _buildActionButton(
              icon: Icons.local_parking,
              label: "Parking",
              isActive: showParking,
              activeColor: Colors.green,
              onPressed: () {
                setState(() => showParking = !showParking);
              },
            ),

            // 📍 Bouton Centrer
            _buildActionButton(
              icon: Icons.my_location,
              label: "Centrer",
              isActive: false,
              activeColor: widget.primaryColor,
              onPressed: _centerMapOnRoute,
            ),

            // 🔄 Bouton Recalculer
            _buildActionButton(
              icon: isLoadingRoute ? Icons.hourglass_empty : Icons.refresh,
              label: "Recalculer",
              isActive: false,
              activeColor: widget.primaryColor,
              onPressed: isLoadingRoute ? null : _calculateRoute,
              isLoading: isLoadingRoute,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isActive ? Colors.transparent : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onPressed,
              child: Center(
                child: isLoading
                    ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: isActive ? Colors.white : activeColor,
                    strokeWidth: 2,
                  ),
                )
                    : Icon(
                  icon,
                  color: isActive ? Colors.white : Colors.grey[700],
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? activeColor : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (isLoadingLocation) {
      return _buildLoadingView();
    }

    if (!hasLocationPermission) {
      return _buildNoPermissionView();
    }

    return Stack(
      children: [
        Column(
          children: [
            // 📍 Titre du salon
            _buildSalonHeader(),

            // 🎛️ Sélecteur de mode de transport
            _buildTransportModeSelector(),

            // 📊 Informations de route
            if (currentRoute != null) _buildRouteInfo(),

            // 🗺️ Carte
            Expanded(child: _buildMap()),

            // 🔧 Espace pour les boutons du bas
            SizedBox(height: 80),
          ],
        ),

        // 🎯 Actions flottantes en bas
        _buildBottomActions(),

        // 📱 Bouton d'ouverture dans apps externes
        _buildExternalAppsButton(),
      ],
    );
  }

  Widget _buildSalonHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.primaryColor, widget.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Itinéraire vers",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            widget.salon.nom,
            style: GoogleFonts.poppins(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: widget.primaryColor),
          SizedBox(height: 24),
          Text(
            "Localisation en cours...",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Recherche de votre position",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPermissionView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 24),
            Text(
              "Autorisation de localisation requise",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              "Pour calculer l'itinéraire, nous avons besoin d'accéder à votre position.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _initializeLocation,
              icon: Icon(Icons.location_on),
              label: Text("Autoriser la localisation"),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportModeSelector() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: TransportMode.values.map((mode) {
          final isSelected = selectedMode == mode;
          final isTransit = mode == TransportMode.transit;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => selectedMode = mode);
                _calculateRoute();
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? widget.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isTransit && !isSelected
                      ? Border.all(color: Colors.orange.withOpacity(0.3), width: 1)
                      : null,
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Icon(
                          _getTransportIcon(mode),
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: 24,
                        ),
                        // ⚠️ Indicateur pour transport public
                        if (isTransit && !isSelected)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getTransportLabel(mode),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                    // Note pour transport public
                    if (isTransit && !isSelected)
                      Text(
                        "Limité",
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRouteInfo() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, -1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _routeInfoAnimationController,
        curve: Curves.easeOutCubic,
      )),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.primaryColor, widget.primaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        currentRoute!.distanceFormatted,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Distance totale",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.white30,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.access_time, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        currentRoute!.durationFormatted,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Temps estimé",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (userLocation == null || salonLocation == null) {
      return Center(
        child: CircularProgressIndicator(color: widget.primaryColor),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: userLocation!,
            initialZoom: 14.0,
            maxZoom: 18.0,
            minZoom: 8.0,
          ),
          children: [
            // 🗺️ Tuiles Geoapify
            TileLayer(
              urlTemplate: 'https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey=${GeoapifyService.apiKey}',
              additionalOptions: {
                'apiKey': GeoapifyService.apiKey,
              },
            ),

            // 🛣️ Ligne d'itinéraire
            if (currentRoute != null && currentRoute!.points.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: currentRoute!.points,
                    strokeWidth: 6.0,
                    color: widget.primaryColor,
                    borderStrokeWidth: 2.0,
                    borderColor: Colors.white,
                  ),
                ],
              ),

            // 📍 Marqueurs
            MarkerLayer(
              markers: [
                // Marqueur utilisateur (départ)
                Marker(
                  point: userLocation!,
                  width: 60,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),

                // Marqueur salon (arrivée)
                Marker(
                  point: salonLocation!,
                  width: 60,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.content_cut,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),

                // 🅿️ Marqueurs parking (si activés)
                if (showParking)
                  ...nearbyParking.map((parking) => Marker(
                    point: parking.location,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.local_parking,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🔧 Helper methods
  IconData _getTransportIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.drive:
        return Icons.directions_car;
      case TransportMode.walk:
        return Icons.directions_walk;
      case TransportMode.bicycle:
        return Icons.directions_bike;
      case TransportMode.transit:
        return Icons.directions_transit;
    }
  }

  String _getTransportLabel(TransportMode mode) {
    switch (mode) {
      case TransportMode.drive:
        return 'Voiture';
      case TransportMode.walk:
        return 'Marche';
      case TransportMode.bicycle:
        return 'Vélo';
      case TransportMode.transit:
        return 'Transport';
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Autorisation requise"),
        content: Text(
            "L'autorisation de localisation est nécessaire pour calculer l'itinéraire. "
                "Veuillez l'activer dans les paramètres de l'application."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: Text("Paramètres"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showTransportNotAvailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.directions_transit, color: Colors.orange),
            SizedBox(width: 8),
            Text("Transport public"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Le transport public n'est pas disponible pour cette zone.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              "Alternatives suggérées :",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.directions_car, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text("Voiture"),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.directions_bike, size: 20, color: Colors.green),
                SizedBox(width: 8),
                Text("Vélo"),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.directions_walk, size: 20, color: Colors.orange),
                SizedBox(width: 8),
                Text("Marche"),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              setState(() => selectedMode = TransportMode.drive);
              _calculateRoute();
            },
            icon: Icon(Icons.directions_car, size: 16),
            label: Text("Voiture"),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
