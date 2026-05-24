import 'package:flutter/material.dart';
import 'dart:async';

class PartnersSection extends StatefulWidget {
  const PartnersSection({super.key});

  @override
  State<PartnersSection> createState() => _PartnersSectionState();
}

class _PartnersSectionState extends State<PartnersSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _currentPartnerIndex = 0;
  int? _hoveredPartnerId;
  late Timer _autoRotateTimer;
  late PageController _pageController;

  final List<Map<String, dynamic>> partnersData = [
    {
      'id': 1,
      'name': 'World Bank Group',
      'image': 'assets/images/partner1.png',
      'description':
          'Global partnership for sustainable development and poverty reduction',
      'type': 'Strategic Partner',
      'website': 'https://www.worldbank.org',
    },
    {
      'id': 2,
      'name': 'United Nations Development Programme',
      'image': 'assets/images/partner2.png',
      'description':
          'Leading UN agency on sustainable development goals implementation',
      'type': 'Development Partner',
      'website': 'https://www.undp.org',
    },
    {
      'id': 3,
      'name': 'ESRI',
      'image': 'assets/images/partner3.png',
      'description': 'Global leader in GIS software and geospatial technology',
      'type': 'Technology Partner',
      'website': 'https://www.esri.com',
    },
    {
      'id': 4,
      'name': 'Google Earth Engine',
      'image': 'assets/images/partner4.png',
      'description':
          'Cloud-based platform for planetary-scale environmental data analysis',
      'type': 'Technology Partner',
      'website': 'https://earthengine.google.com',
    },
    {
      'id': 5,
      'name': 'ICIMOD',
      'image': 'assets/images/partner5.png',
      'description':
          'Regional intergovernmental learning and knowledge sharing centre',
      'type': 'Knowledge Partner',
      'website': 'https://www.icimod.org',
    },
    {
      'id': 6,
      'name': 'USAID',
      'image': 'assets/images/partner6.png',
      'description': 'Leading international development agency',
      'type': 'Development Partner',
      'website': 'https://www.usaid.gov',
    },
    {
      'id': 7,
      'name': 'Asian Development Bank',
      'image': 'assets/images/partner7.png',
      'description': 'Promoting social and economic development in Asia',
      'type': 'Strategic Partner',
      'website': 'https://www.adb.org',
    },
    {
      'id': 8,
      'name': 'JICA',
      'image': 'assets/images/partner8.png',
      'description': "Japan's leading development cooperation agency",
      'type': 'Development Partner',
      'website': 'https://www.jica.go.jp',
    },
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController(viewportFraction: 0.85);

    // Setup pulse animation for the icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Setup auto-rotate timer
    _autoRotateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _pageController.hasClients) {
        final nextPage = (_currentPartnerIndex + 1) % partnersData.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _autoRotateTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0F9F9), Color(0xFFE8F4F4)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Animated gradient bar at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 4,
              child: AnimatedContainer(
                duration: const Duration(seconds: 3),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF008080),
                      Color(0xFF70D3D3),
                      Color(0xFF008080),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Section
                  _buildHeader(),
                  const SizedBox(height: 30),

                  // Partners Carousel
                  SizedBox(height: 420, child: _buildPartnersCarousel()),

                  // Dot Indicators Only
                  _buildDotIndicators(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated Icon
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF008080), Color(0xFF70D3D3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x4D008080),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.handshake, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 20),

        // Title with gradient text
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF008080), Color(0xFF004D4D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Our Partners',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Subtitle
        Text(
          'Collaborating with leading organizations worldwide',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPartnersCarousel() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPartnerIndex = index;
        });
      },
      itemCount: partnersData.length,
      physics: const BouncingScrollPhysics(),
      pageSnapping: true,
      itemBuilder: (context, index) {
        return _buildPartnerCard(partnersData[index]);
      },
    );
  }

  Widget _buildPartnerCard(Map<String, dynamic> partner) {
    final isHovered = _hoveredPartnerId == partner['id'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()
          ..translate(0.0, isHovered ? -10.0 : 0.0, 0.0)
          ..scale(isHovered ? 1.02 : 1.0),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoveredPartnerId = partner['id']),
          onExit: (_) => setState(() => _hoveredPartnerId = null),
          child: GestureDetector(
            onTap: () {
              // Handle partner card tap
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isHovered
                        ? const Color(0x26008080)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: isHovered ? 50 : 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo Area
                        Container(
                          height: 180,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFF8F9FA), Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0x1A008080),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Image.asset(
                              partner['image'],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.business,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                );
                              },
                            ),
                          ),
                        ),

                        // Info Section
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Partner Name
                                Text(
                                  partner['name'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C3E50),
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),

                                // Partner Type Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0x1A008080),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    partner['type'],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF008080),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Description
                                Flexible(
                                  child: Text(
                                    partner['description'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      height: 1.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                  ),
                                ),
                                const SizedBox(height: 15),

                                // Website Link
                                TextButton.icon(
                                  onPressed: () {
                                    // Handle website visit
                                    // You could use url_launcher package here
                                  },
                                  icon: const Icon(
                                    Icons.open_in_new,
                                    size: 14,
                                    color: Color(0xFF008080),
                                  ),
                                  label: const Text(
                                    'Visit Website',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF008080),
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0x0D008080),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bottom gradient bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 4,
                        child: const FractionallySizedBox(
                          widthFactor: 1.0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF008080), Color(0xFF70D3D3)],
                              ),
                            ),
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
    );
  }

  Widget _buildDotIndicators() {
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          partnersData.length,
          (index) => GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: index == _currentPartnerIndex ? 28 : 10,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: index == _currentPartnerIndex
                    ? const LinearGradient(
                        colors: [Color(0xFF008080), Color(0xFF70D3D3)],
                      )
                    : null,
                color: index == _currentPartnerIndex
                    ? null
                    : Colors.grey.shade300,
                boxShadow: index == _currentPartnerIndex
                    ? [
                        BoxShadow(
                          color: const Color(0xFF008080).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
