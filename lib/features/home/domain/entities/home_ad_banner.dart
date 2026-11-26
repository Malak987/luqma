import 'package:equatable/equatable.dart';

/// One promotional banner supplied by an ads source.
///
/// Nothing here is derived from store or menu data: an ad exists only when a
/// source returns it. The widget layer never invents a banner, a percentage or
/// a call to action — every field is optional except the artwork itself.
class HomeAdBanner extends Equatable {
  const HomeAdBanner({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.ctaLabel,
    this.targetUrl,
  });

  final String id;

  /// Absolute `http`/`https` image URL. Banners without a usable image are not
  /// rendered by the carousel.
  final String imageUrl;

  final String? title;
  final String? subtitle;
  final String? ctaLabel;
  final String? targetUrl;

  @override
  List<Object?> get props =>
      <Object?>[id, imageUrl, title, subtitle, ctaLabel, targetUrl];
}
