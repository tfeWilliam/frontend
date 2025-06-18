// lib/pages/salon_geolocalisation/salon_map_page.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hairbnb/models/salon_details_geo.dart';
import 'package:hairbnb/pages/coiffeuses/services/city_autocomplete.dart';
import 'package:hairbnb/pages/coiffeuses/services/geocoding_service.dart';
import 'package:provider/provider.dart';
import 'package:hairbnb/models/current_user.dart';
import 'package:hairbnb/services/providers/current_user_provider.dart';
import 'package:hairbnb/services/providers/cart_provider.dart'; // ✅ AJOUT : Import du CartProvider
import 'package:hairbnb/widgets/bottom_nav_bar.dart';
import '../chat/chat_page.dart';
import '../coiffeuses/services/location_service.dart';
import 'api_salon_location_service.dart';
import 'itineraire_page.dart';
import 'modals/show_salon_details_modal.dart';
import 'modals/show_salon_services_modal_service/show_salon_services_modal_service.dart';
import 'widgets/build_team_preview.dart';

class SalonsListPage extends StatefulWidget {
  const SalonsListPage({super.key});

  @override
  _SalonsListPageState createState() => _SalonsListPageState();
}

class _SalonsListPageState extends State<SalonsListPage> {
  // MODIFIÉ: Utilisation du nouveau modèle
  List<SalonDetailsForGeo> salons = [];
  Position? _currentPosition;
  Position? _gpsPosition;
  double _gpsRadius = 10.0;
  final TextEditingController cityController = TextEditingController();
  final TextEditingController distanceController = TextEditingController();
  bool showCitySearch = false;
  late CurrentUser? currentUser;
  int _currentIndex = 1;
  String? activeSearchLabel;
  bool isLoading = true;

  int _itemsPerPage = 10;
  int _currentPage = 1;

  final Color primaryColor = Color(0xFF8E44AD);
  final Color accentColor = Color(0xFFE67E22);
  final Color backgroundColor = Color(0xFFF5F5F5);
  final Color cardColor = Colors.white;

  // MODIFIÉ: Getter avec le nouveau type
  List<SalonDetailsForGeo> get _paginatedSalons {
    if (salons.isEmpty) return [];
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = _currentPage * _itemsPerPage;
    return salons.sublist(start, end > salons.length ? salons.length : end);
  }

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    setState(() {
      isLoading = true;
    });

    try {
      final position = await LocationService.getUserLocation();
      if (position != null) {
        setState(() {
          _gpsPosition = position;
          _currentPosition = position;
          activeSearchLabel = "📍 Autour de ma position (${_gpsRadius.toInt()} km)";
        });
        await _fetchSalons(position, _gpsRadius);
      }
    } catch (e) {
      print("❌ Erreur de localisation : $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSalons(Position position, double radius) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Utilisation de la nouvelle méthode qui retourne SalonsResponse
      final salonsResponse = await ApiSalonService.fetchNearbySalons(
        position.latitude,
        position.longitude,
        radius,
      );

      currentUser = Provider.of<CurrentUserProvider>(context, listen: false).currentUser;

      setState(() {
        // Récupération des salons depuis la response
        salons = salonsResponse.salons;
        _currentPage = 1;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Erreur API : $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Impossible de charger les salons: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _searchByCity() async {
    final city = cityController.text.trim();
    final distanceText = distanceController.text.trim();

    if (city.isEmpty || distanceText.isEmpty) return;

    final parsedDistance = double.tryParse(distanceText);
    if (parsedDistance == null || parsedDistance > 150) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Distance invalide. Maximum 150 km."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final position = await GeocodingService.getCoordinatesFromCity(city);
    if (position != null) {
      setState(() {
        _currentPosition = position;
        activeSearchLabel = "🏙️ Autour de $city (${parsedDistance.toInt()} km)";
        showCitySearch = false;
      });
      await _fetchSalons(position, parsedDistance);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ville introuvable."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // MODIFIÉ: Utilisation directe de la distance du modèle ou calcul si nécessaire
  double _calculateDistance(SalonDetailsForGeo salon) {
    // On utilise d'abord la distance déjà calculée par l'API
    return salon.distance;
  }

  void _onTabTapped(int index) => setState(() => _currentIndex = index);

  // dans le fichier salon_map_page.dart
  void _viewSalonDetails(SalonDetailsForGeo salon) {
    if (currentUser != null) {
      showDialog( // <-- Utilise showDialog à la place
        context: context,
        builder: (context) => Dialog( // <-- Enveloppe ton modal dans un Dialog
          backgroundColor: Colors.transparent, // Pour que ton Container du modal gère son propre fond
          insetPadding: EdgeInsets.all(20), // Ajoute un peu de marge autour du dialogue centré
          child: SalonDetailsModal(
            currentUser: currentUser!,
            salon: salon,
            calculateDistance: _calculateDistance,
            primaryColor: primaryColor,
            accentColor: accentColor,
          ),
        ),
      );
    } else {
      // Optionnel : Afficher un message si l'utilisateur n'est pas connecté
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veuillez vous connecter pour voir les détails du salon."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// ✅ NOUVEAU : Affiche un message de succès centré
  void _showSuccessDialog(BuildContext context, int nombreServices) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône de succès
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
                SizedBox(height: 16),
                
                // Titre
                Text(
                  "Succès !",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 8),
                
                // Message
                Text(
                  "$nombreServices service${nombreServices > 1 ? 's' : ''} ajouté${nombreServices > 1 ? 's' : ''} au panier !",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 24),
                
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text("Continuer"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Fermer ce dialog
                          Navigator.pushNamed(context, '/cart'); // Aller au panier
                        },
                        child: Text("Voir panier"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ✅ NOUVEAU : Affiche un message d'erreur centré
  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône d'erreur
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                SizedBox(height: 16),
                
                // Titre
                Text(
                  "Erreur",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                
                // Message
                Text(
                  "Impossible d'ajouter les services au panier.\nVeuillez réessayer.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 24),
                
                // Bouton
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("OK"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          "Salons à proximité",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: Colors.white),
            onPressed: () {
              if (salons.isNotEmpty) {
                _openItineraire(salons.first);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No salons available to show on map yet.")),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, backgroundColor],
            stops: [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: _buildSalonsList(),
              ),
            ),
            if (salons.length > _itemsPerPage) _buildPagination(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeSearchLabel != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                activeSearchLabel!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          showCitySearch ? _buildCitySearch() : _buildGpsSearch(),
        ],
      ),
    );
  }

  Widget _buildCitySearch() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: CityAutocompleteField(
                  controller: cityController,
                  apiKey: 'b097f188b11f46d2a02eb55021d168c1',
                  onCitySelected: (ville) {},
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              width: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: distanceController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'km',
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: accentColor,
              child: IconButton(
                icon: Icon(Icons.search, color: Colors.white),
                onPressed: _searchByCity,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        TextButton.icon(
          icon: Icon(Icons.my_location),
          label: Text("Revenir à ma position"),
          onPressed: () {
            setState(() {
              showCitySearch = false;
              if (_gpsPosition != null) {
                _currentPosition = _gpsPosition;
                activeSearchLabel = "📍 Autour de ma position (${_gpsRadius.toInt()} km)";
                _fetchSalons(_gpsPosition!, _gpsRadius);
              }
            });
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildGpsSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Rayon de recherche",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Slider(
                value: _gpsRadius,
                min: 1,
                max: 50,
                divisions: 10,
                label: "${_gpsRadius.toInt()} km",
                onChanged: (val) {
                  setState(() {
                    _gpsRadius = val;
                    activeSearchLabel = "📍 Autour de ma position (${_gpsRadius.toInt()} km)";
                  });
                  if (_gpsPosition != null) {
                    _fetchSalons(_gpsPosition!, _gpsRadius);
                  }
                },
                activeColor: Colors.white,
                inactiveColor: Colors.white30,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${_gpsRadius.toInt()} km",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            icon: Icon(Icons.location_city),
            label: Text("Rechercher par ville"),
            onPressed: () {
              setState(() {
                showCitySearch = true;
                cityController.clear();
                distanceController.clear();
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalonsList() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)));
    }

    if (salons.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              "Aucun salon trouvé",
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              "Essayez d'augmenter la distance ou de rechercher dans une autre zone",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_currentPosition != null) {
                  _fetchSalons(_currentPosition!, _gpsRadius);
                }
              },
              icon: Icon(Icons.refresh),
              label: Text("Actualiser"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _paginatedSalons.length,
      itemBuilder: (context, index) => _buildSalonCard(_paginatedSalons[index]),
    );
  }

  // Utilisation du nouveau modèle
  Widget _buildSalonCard(SalonDetailsForGeo salon) {
    // Utilisation directe de la distance du modèle
    final distance = salon.distance;
    final coiffeuses = salon.coiffeusesDetails;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _viewSalonDetails(salon),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSalonCardHeader(salon, distance),
                if (coiffeuses.isNotEmpty) buildTeamPreview(coiffeuses),
                _buildCardActions(salon),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSalonCardHeader(SalonDetailsForGeo salon, double distance) {
    return Row(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: salon.hasLogo
              ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              salon.getLogoUrl("https://www.hairbnb.site") ?? "",
              fit: BoxFit.cover,
              errorBuilder: (ctx, obj, st) => Icon(Icons.spa, color: primaryColor, size: 30),
            ),
          )
              : Icon(Icons.spa, color: primaryColor, size: 30),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                salon.nom,
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              if (salon.slogan != null && salon.slogan!.isNotEmpty)
                Text(
                  salon.slogan!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  // MODIFIÉ: Utilisation du getter distanceFormatee
                  salon.distanceFormatee,
                  style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
      ],
    );
  }

  // ✅ CORRIGÉ : Bouton Services avec logique d'ajout au panier
  Widget _buildCardActions(SalonDetailsForGeo salon) {
    final coiffeuses = salon.coiffeusesDetails;
    CoiffeuseDetailsForGeo? contactPersonne = salon.proprietaire;

    if (contactPersonne == null && coiffeuses.isNotEmpty) {
      contactPersonne = coiffeuses.first;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () => _openItineraire(salon),
            icon: const Icon(Icons.directions, size: 16),
            label: const Text("Itinéraire"),
            style: OutlinedButton.styleFrom(
              foregroundColor: accentColor,
              side: BorderSide(color: accentColor),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              if (contactPersonne != null && currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      currentUser: currentUser!,
                      otherUserId: contactPersonne!.uuid,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Aucun contact disponible pour ce salon."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: Icon(Icons.chat_bubble_outline, size: 16),
            label: Text("Contacter"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: BorderSide(color: Colors.green),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
              textStyle: TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              // ✅ NOUVEAU : Le modal gère maintenant tout l'ajout au panier avec notifications centrées
              await SalonServicesModalService.afficherServicesModal(
                context,
                salon: salon,
                currentUser: currentUser, // ✅ NOUVEAU : Passer currentUser
                primaryColor: primaryColor,
                accentColor: accentColor,
              );

              // ✅ Plus besoin de logique d'ajout au panier ici - le modal gère tout !
              print("✅ Modal services fermé pour ${salon.nom}");
            },
            icon: Icon(Icons.design_services, size: 16),
            label: Text("Services"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
              textStyle: TextStyle(fontSize: 12),
            ),
          ),
          // ElevatedButton.icon(
          //   onPressed: () async {
          //     try {
          //       // 🔄 Afficher le modal et récupérer les services sélectionnés
          //       final selectedServices = await SalonServicesModalService.afficherServicesModal(
          //         context,
          //         salon: salon,
          //         primaryColor: primaryColor,
          //         accentColor: accentColor,
          //       );
          //
          //       // ✅ Si des services ont été sélectionnés, les ajouter au panier
          //       if (selectedServices != null && selectedServices.isNotEmpty && currentUser != null) {
          //         final cartProvider = Provider.of<CartProvider>(context, listen: false);
          //
          //         // 📦 Ajouter chaque service au panier
          //         for (var service in selectedServices) {
          //           await cartProvider.addToCart(service, currentUser!.idTblUser.toString());
          //         }
          //
          //         _showSuccessDialog(context, selectedServices.length);
          //
          //         print("✅ ${selectedServices.length} services ajoutés au panier depuis la liste des salons pour ${salon.nom}");
          //       }
          //     } catch (e) {
          //       // ❌ Gestion des erreurs avec message centré
          //       print("❌ Erreur lors de l'ajout au panier depuis la liste des salons : $e");
          //       _showErrorDialog(context);
          //     }
          //   },
          //   icon: Icon(Icons.design_services, size: 16),
          //   label: Text("Services"),
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: primaryColor,
          //     foregroundColor: Colors.white,
          //     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          //     visualDensity: VisualDensity.compact,
          //     textStyle: TextStyle(fontSize: 12),
          //   ),
          // )
          // 🎯 BOUTON SERVICES - Version CORRIGÉE avec ajout au panier
          // ElevatedButton.icon(
          //   onPressed: () async {
          //     try {
          //       // 🔄 Afficher le modal et récupérer les services sélectionnés
          //       final selectedServices = await SalonServicesModalService.afficherServicesModal(
          //         context,
          //         salon: salon,
          //         primaryColor: primaryColor,
          //         accentColor: accentColor,
          //       );
          //
          //       // ✅ Si des services ont été sélectionnés, les ajouter au panier
          //       if (selectedServices != null && selectedServices.isNotEmpty && currentUser != null) {
          //         final cartProvider = Provider.of<CartProvider>(context, listen: false);
          //
          //         // 📦 Ajouter chaque service au panier
          //         for (var service in selectedServices) {
          //           await cartProvider.addToCart(service, currentUser!.idTblUser.toString());
          //         }
          //
          //         // 🎯 NOUVEAU : Message centré au lieu de SnackBar
          //         _showSuccessDialog(context, selectedServices.length);
          //
          //         print("✅ ${selectedServices.length} services ajoutés au panier depuis la liste des salons pour ${salon.nom}");
          //       }
          //     } catch (e) {
          //       // ❌ Gestion des erreurs avec message centré
          //       print("❌ Erreur lors de l'ajout au panier depuis la liste des salons : $e");
          //       _showErrorDialog(context);
          //     }
          //   },
          //   icon: Icon(Icons.design_services, size: 16),
          //   label: Text("Services"),
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: primaryColor,
          //     foregroundColor: Colors.white,
          //     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          //     visualDensity: VisualDensity.compact,
          //     textStyle: TextStyle(fontSize: 12),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      color: backgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, size: 16),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                color: primaryColor,
                disabledColor: Colors.grey[300],
              ),
              Text(
                "Page $_currentPage/${((salons.length - 1) / _itemsPerPage + 1).floor()}",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: _currentPage * _itemsPerPage < salons.length
                    ? () => setState(() => _currentPage++)
                    : null,
                color: primaryColor,
                disabledColor: Colors.grey[300],
              ),
            ],
          ),
          Row(
            children: [
              Text(
                "Afficher:",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButton<int>(
                  value: _itemsPerPage,
                  items: [5, 10, 20].map((value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(
                        '$value',
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _itemsPerPage = value;
                        _currentPage = 1;
                      });
                    }
                  },
                  underline: SizedBox(),
                  icon: Icon(Icons.arrow_drop_down, size: 18),
                  isDense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openItineraire(SalonDetailsForGeo salon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItinerairePage(
          salon: salon,
          primaryColor: primaryColor,
          accentColor: accentColor,
        ),
      ),
    );
  }
}
