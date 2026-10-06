import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_logo.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({required this.brandName, required this.tagline, super.key});

  final String brandName;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    return AppLogo(brandName: brandName, tagline: tagline);
  }
}
