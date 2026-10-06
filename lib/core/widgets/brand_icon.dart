import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_assets.dart';

enum SocialProvider { apple, facebook, google }

/// Provider marks are loaded from the centralized brand asset catalog. The
/// button remains provider-agnostic because callers can still override the
/// `icon` with any widget or image.
class SocialProviderIcon extends StatelessWidget {
  const SocialProviderIcon({
    required this.provider,
    super.key,
    this.size = 20,
    this.color,
  });

  final SocialProvider provider;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).colorScheme;
    switch (provider) {
      case SocialProvider.apple:
        return SvgPicture.asset(
          AppAssets.apple,
          width: size,
          height: size,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(
            color ?? semantic.onSurface,
            BlendMode.srcIn,
          ),
        );
      case SocialProvider.facebook:
        return SvgPicture.asset(
          AppAssets.facebook,
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      case SocialProvider.google:
        return SvgPicture.asset(
          AppAssets.google,
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
    }
  }
}
