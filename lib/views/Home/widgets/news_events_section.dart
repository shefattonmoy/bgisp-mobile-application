import 'package:flutter/material.dart';

class NewsEventsSection extends StatelessWidget {
 NewsEventsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 15),
            child: Row(
              children: [
                // News icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF008080), Color(0xFF70d3d3)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF008080).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.newspaper,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'News & Events',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2c3e50),
                  ),
                ),
                const Spacer(),
                // View All button
                TextButton(
                  onPressed: () {
                    // Navigate to all news/events
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF008080),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // News Cards Container
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(20),
              itemCount: _newsEvents.length,
              itemBuilder: (context, index) {
                final event = _newsEvents[index];
                return _buildNewsCard(
                  context: context,
                  title: event['title'] as String,
                  description: event['description'] as String,
                  date: event['date'] as String,
                  category: event['category'] as String,
                  color: event['color'] as Color,
                  onTap: () {
                    // Handle news card tap
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard({
    required BuildContext context,
    required String title,
    required String description,
    required String date,
    required String category,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with icon
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getCategoryIcon(category),
                          color: color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              category,
                              style: TextStyle(
                                color: color.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.5,
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Footer with date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            date,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Read More',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 10,
                            color: color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'workshop':
        return Icons.school;
      case 'conference':
        return Icons.people;
      case 'training':
        return Icons.auto_stories;
      case 'announcement':
        return Icons.campaign;
      case 'update':
        return Icons.update;
      default:
        return Icons.newspaper;
    }
  }

  // Sample news/events data
  final List<Map<String, dynamic>> _newsEvents = [
    {
      'title': 'GIS Workshop 2024',
      'description': 'Upcoming GIS workshop and training program for government officials covering advanced spatial analysis.',
      'date': 'Dec 15, 2024',
      'category': 'Workshop',
      'color': const Color(0xFF008080),
    },
    {
      'title': 'Annual Conference',
      'description': 'National GIS conference featuring keynote speakers and latest technology demonstrations.',
      'date': 'Jan 20, 2025',
      'category': 'Conference',
      'color': const Color(0xFFe67e22),
    },
    {
      'title': 'Training Program',
      'description': 'Comprehensive training on GIS data management and visualization techniques.',
      'date': 'Feb 5, 2025',
      'category': 'Training',
      'color': const Color(0xFF3498db),
    },
    {
      'title': 'Platform Update',
      'description': 'New features and improvements coming to the Bangladesh GIS Platform.',
      'date': 'Dec 28, 2024',
      'category': 'Announcement',
      'color': const Color(0xFF9b59b6),
    },
    {
      'title': 'System Maintenance',
      'description': 'Scheduled maintenance and updates for improved system performance.',
      'date': 'Dec 20, 2024',
      'category': 'Update',
      'color': const Color(0xFFe74c3c),
    },
  ];
}