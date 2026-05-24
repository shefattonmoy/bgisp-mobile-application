import 'package:flutter/material.dart';

class StatisticCard extends StatefulWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Gradient gradient;
  final VoidCallback? onTap;

  const StatisticCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.gradient,
    this.onTap,
  });

  @override
  State<StatisticCard> createState() => _StatisticCardState();
}

class _StatisticCardState extends State<StatisticCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isClickable = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) {
        if (isClickable) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (isClickable) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(
                  _isHovered && isClickable ? 0.2 : 0.08,
                ),
                blurRadius: _isHovered && isClickable ? 20 : 10,
                offset: Offset(0, _isHovered && isClickable ? 6 : 3),
              ),
            ],
            border: Border.all(
              color: widget.color.withOpacity(
                _isHovered && isClickable ? 0.4 : 0.15,
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                // Simple Row layout - NO nested Column
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Small Icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: widget.gradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(widget.icon, color: widget.color, size: 16),
                      ),

                      const SizedBox(width: 10),

                      // Value text
                      Text(
                        widget.value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: widget.color,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Label text
                      Expanded(
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Hover effect bar
                if (isClickable)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: _isHovered ? 3 : 0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.color, widget.color.withOpacity(0.6)],
                        ),
                      ),
                    ),
                  ),

                // Ripple overlay
                if (isClickable)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onTap,
                        borderRadius: BorderRadius.circular(15),
                        splashColor: widget.color.withOpacity(0.1),
                        highlightColor: widget.color.withOpacity(0.05),
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
}
