import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<LanguageProvider>(context).t;

    return Scaffold(
      backgroundColor: const Color(0xFFeef2f7),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t['about'] ?? 'About'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF008080), Color(0xFF004d4d)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/bgisp_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.public,
                              color: Colors.blue,
                              size: 40,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t['aboutBgisp'] ?? 'About BGISP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bangladesh GIS Platform',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Mission Card
                  _buildInfoCard(
                    icon: Icons.visibility,
                    title: t['mission'] ?? 'Our Mission',
                    description: t['missionText'] ?? '',
                    color: const Color(0xFF008080),
                  ),
                  const SizedBox(height: 16),

                  // Vision Card
                  _buildInfoCard(
                    icon: Icons.public,
                    title: t['vision'] ?? 'Our Vision',
                    description: t['visionText'] ?? '',
                    color: const Color(0xFF2c3e50),
                  ),
                  const SizedBox(height: 16),

                  // Objective Card
                  _buildInfoCard(
                    icon: Icons.gps_fixed,
                    title: t['objective'] ?? 'Our Objective',
                    description: t['objectiveText'] ?? '',
                    color: const Color(0xFFe67e22),
                  ),
                  const SizedBox(height: 16),

                  // Description Card
                  _buildInfoCard(
                    icon: Icons.info_outline,
                    title: t['aboutBgisp'] ?? 'About BGISP',
                    description:
                        '${t['aboutBgispDesc1'] ?? ''}\n\n${t['aboutBgispDesc2'] ?? ''}\n\n${t['aboutBgispDesc3'] ?? ''}\n\n${t['aboutBgispDesc4'] ?? ''}',
                    color: const Color(0xFF8e44ad),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF2c3e50),
              child: Column(
                children: [
                  const Icon(Icons.public, color: Colors.white38, size: 30),
                  const SizedBox(height: 12),
                  Text(
                    '© ${DateTime.now().year} Bangladesh GIS Platform',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t['version'] ?? 'Version 1.0.0',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              height: 1.7,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
