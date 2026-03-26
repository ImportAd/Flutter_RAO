import 'package:flutter/material.dart';
import '../../app/theme.dart';

class HeaderNavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const HeaderNavLink({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  State<HeaderNavLink> createState() => _HeaderNavLinkState();
}

class _HeaderNavLinkState extends State<HeaderNavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _isHovered
                      ? AppColors.primaryDark
                      : AppColors.primary,
                ),
          ),
        ),
      ),
    );
  }
}