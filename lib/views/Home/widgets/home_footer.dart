import 'package:flutter/material.dart';
import '../../../models/home/visitor_count.dart';

class HomeFooter extends StatelessWidget {
  final VisitorCount visitorCount;

  const HomeFooter({super.key, required this.visitorCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(color: Color(0xFF2c3e50)),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 768) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVisitorStats(),
                    const SizedBox(height: 30),
                    _buildFooterLinks(),
                    const SizedBox(height: 30),
                    _buildCopyright(),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildVisitorStats()),
                  Expanded(flex: 1, child: _buildFooterLinks()),
                  Expanded(flex: 1, child: _buildCopyright()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visitor',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildVisitorRow(
          icon: Icons.today,
          label: 'Today',
          value: visitorCount.today.toString(),
        ),
        _buildVisitorRow(
          icon: Icons.calendar_month,
          label: 'This Month',
          value: visitorCount.thisMonth.toString(),
        ),
        _buildVisitorRow(
          icon: Icons.bar_chart,
          label: 'Total Visits',
          value: visitorCount.total.toString(),
        ),
      ],
    );
  }

  Widget _buildVisitorRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Links',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildLink('About Us', Icons.info_outline),
        _buildLink('Contact', Icons.contact_mail),
        _buildLink('Privacy Policy', Icons.privacy_tip),
        _buildLink('Terms of Service', Icons.description),
        _buildLink('Help & Support', Icons.help_outline),
      ],
    );
  }

  Widget _buildLink(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Handle link tap
        },
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 16),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyright() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.public, color: Colors.white38, size: 30),
        const SizedBox(height: 16),
        Text(
          '© ${DateTime.now().year} Bangladesh GIS Platform',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          'All Rights Reserved',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        const SizedBox(height: 16),
        Text(
          'Version 1.0.0',
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
        ),
      ],
    );
  }
}
