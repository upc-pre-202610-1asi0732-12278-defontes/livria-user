import 'package:flutter/material.dart';
import 'package:livria_user/common/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Vista estática de la tienda + imagen del mapa; al tocar se abre Google Maps
/// (evita el SDK nativo de [google_maps_flutter], que crasheaba en algunos Android).
class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  static final Uri _storeMapsUri = Uri.parse(
    'https://www.google.com/maps/place/Av.+Rep%C3%BAblica+de+Chile+661,+Jes%C3%BAs+Mar%C3%ADa+15072/@-12.070464,-77.0423135,16z/data=!4m6!3m5!1s0x9105c8ec25485527:0x582ab043d0a29504!8m2!3d-12.0711073!4d-77.0384899!16s%2Fg%2F11vstpy8sp?entry=ttu&g_ep=EgoyMDI2MDUxMC4wIKXMDSoASAFQAw%3D%3D',
  );

  /// Ajusta el nombre si tu archivo difiere (p. ej. `livria_map.PNG`).
  static const String _mapPreviewAsset = 'assets/images/livria_map.png';

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  Future<void> _openStoreOnMaps() async {
    try {
      final ok = await launchUrl(
        LocationPage._storeMapsUri,
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Maps')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Maps: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('UBICACIÓN'),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
        titleTextStyle: textTheme.labelLarge?.copyWith(color: AppColors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OUR STORE',
                    style: textTheme.headlineLarge?.copyWith(
                      color: AppColors.darkBlue,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Come visit our store!',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: AppColors.darkBlue,
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.pexels.com/photos/34824141/pexels-photo-34824141.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500',
                    ),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black26,
                      BlendMode.darken,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'LIVRIA STORE',
                        style: textTheme.headlineLarge?.copyWith(
                          color: AppColors.white,
                          shadows: [
                            const Shadow(
                              blurRadius: 4.0,
                              color: Colors.black,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.white),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'LIVRIA',
                          style: textTheme.headlineMedium?.copyWith(
                            color: AppColors.white,
                            fontSize: 36,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                'ADDRESS',
                style: textTheme.headlineLarge?.copyWith(
                  color: AppColors.secondaryYellow,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Text(
                'Av. República de Chile 661, Jesús María 15072, Peru',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openStoreOnMaps,
                  borderRadius: BorderRadius.circular(12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            LocationPage._mapPreviewAsset,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 250,
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Add map image at\n${LocationPage._mapPreviewAsset}',
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 12,
                            child: Material(
                              color: AppColors.darkBlue.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.map_outlined, color: AppColors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Open in Google Maps',
                                      style: textTheme.labelLarge?.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
