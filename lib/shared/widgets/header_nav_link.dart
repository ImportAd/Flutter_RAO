import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';

class HeaderNavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  const HeaderNavLink({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color,
  });

  @override
  State<HeaderNavLink> createState() => _HeaderNavLinkState();
}

class _HeaderNavLinkState extends State<HeaderNavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? AppColors.primary;
    final hoverColor = widget.color != null
        ? HSLColor.fromColor(baseColor).withLightness(
            (HSLColor.fromColor(baseColor).lightness - 0.15).clamp(0.0, 1.0),
          ).toColor()
        : AppColors.primaryDark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 16,
                  color: _isHovered ? hoverColor : baseColor,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: GoogleFonts.andika(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _isHovered ? hoverColor : baseColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}