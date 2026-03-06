import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// A robust network image avatar that gracefully handles CORS errors and
/// load failures (common on Flutter Web) by showing a colored initials fallback.
class NetworkAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? borderColor;
  final double borderWidth;

  const NetworkAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 28,
    this.borderColor,
    this.borderWidth = 0,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  Color get _avatarColor {
    final colors = [
      const Color(0xFF135BEC),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFF43F5E),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFFEC4899),
    ];
    final index = name.isEmpty ? 0 : name.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  /// Rewrites problematic URLs for Web (like i.pravatar.cc which has CORS issues)
  String? _getResilientUrl(String? url) {
    if (!kIsWeb || url == null || !url.contains('pravatar.cc')) return url;
    
    // Rewrite pravatar.cc to ui-avatars.com which is CORS friendly
    final seed = url.contains('u=') ? url.split('u=').last : name;
    return "https://ui-avatars.com/api/?name=$seed&background=random&color=fff&size=200";
  }

  @override
  Widget build(BuildContext context) {
    final sanitizedUrl = _getResilientUrl(imageUrl);
    final hasUrl = sanitizedUrl != null && sanitizedUrl.isNotEmpty;

    Widget avatar;

    if (hasUrl) {
      avatar = Image.network(
        sanitizedUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildInitialsAvatar();
        },
      );
    } else {
      avatar = _buildInitialsAvatar();
    }

    if (borderColor != null && borderWidth > 0) {
      return Container(
        width: radius * 2 + borderWidth * 2,
        height: radius * 2 + borderWidth * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor!, width: borderWidth),
        ),
        child: ClipOval(child: avatar),
      );
    }

    return ClipOval(
      child: SizedBox(width: radius * 2, height: radius * 2, child: avatar),
    );
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: _avatarColor,
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.7,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// A network image in a DecorationImage context with error fallback widget.
/// Use this inside a [Stack] or [Container] when you need a [DecorationImage]-style layout.
class NetworkAvatarBox extends StatefulWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final BoxShape shape;
  final Color? borderColor;
  final double borderWidth;
  final Widget? fallback;

  const NetworkAvatarBox({
    super.key,
    this.imageUrl,
    required this.name,
    required this.size,
    this.shape = BoxShape.circle,
    this.borderColor,
    this.borderWidth = 0,
    this.fallback,
  });

  @override
  State<NetworkAvatarBox> createState() => _NetworkAvatarBoxState();
}

class _NetworkAvatarBoxState extends State<NetworkAvatarBox> {
  bool _hasError = false;

  String get _initials {
    final parts = widget.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  Color get _avatarColor {
    final colors = [
      const Color(0xFF135BEC),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFF43F5E),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFFEC4899),
    ];
    final index = widget.name.isEmpty ? 0 : widget.name.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  /// Rewrites problematic URLs for Web (like i.pravatar.cc which has CORS issues)
  String? _getResilientUrl(String? url) {
    if (!kIsWeb || url == null || !url.contains('pravatar.cc')) return url;
    
    // Rewrite pravatar.cc to ui-avatars.com which is CORS friendly
    final seed = url.contains('u=') ? url.split('u=').last : widget.name;
    return "https://ui-avatars.com/api/?name=$seed&background=random&color=fff&size=300";
  }

  @override
  Widget build(BuildContext context) {
    final sanitizedUrl = _getResilientUrl(widget.imageUrl);
    final hasUrl = sanitizedUrl != null && sanitizedUrl.isNotEmpty && !_hasError;

    final borderDecoration = widget.borderColor != null
        ? Border.all(color: widget.borderColor!, width: widget.borderWidth)
        : null;

    if (!hasUrl) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: widget.shape,
          color: _avatarColor,
          border: borderDecoration,
        ),
        child: Center(
          child: Text(
            _initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.size * 0.35,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: widget.shape == BoxShape.circle 
        ? ClipOval(child: _buildImage(sanitizedUrl))
        : _buildImage(sanitizedUrl),
    );
  }

  Widget _buildImage(String url) {
    return Image.network(
      url,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // On error (including CORS errors), switch to initials
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _hasError = true);
        });
        return Container(
          color: _avatarColor,
          child: Center(
            child: Text(
              _initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.size * 0.35,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
