import 'package:flutter/material.dart';

final RegExp _imageWhitespace = RegExp(r'\s');

/// The existing Image.network/ImageCache convention, shared without adding an
/// HTTP client, disk cache, asset dependency or preloading the entire catalog.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
      {required this.url,
      required this.placeholder,
      this.fit = BoxFit.cover,
      super.key});

  final String? url;
  final Widget placeholder;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim() ?? '';
    final uri = Uri.tryParse(value);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        _imageWhitespace.hasMatch(value)) return placeholder;
    return Image.network(
      value,
      fit: fit,
      excludeFromSemantics: true,
      frameBuilder: (context, child, frame, synchronous) =>
          synchronous || frame != null ? child : placeholder,
      errorBuilder: (context, error, stackTrace) => KeyedSubtree(
        key: const ValueKey<String>('app_network_image_error'),
        child: placeholder,
      ),
    );
  }
}
