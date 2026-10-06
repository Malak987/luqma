import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import 'auth_background.dart';

/// Common shell for login, register, reset-password, OTP, and verification.
/// It owns safe areas, scrolling, responsive constraints, and the background;
/// feature pages only provide their composed content.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final mediaQuery = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: colors.background,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: colors.background,
        resizeToAvoidBottomInset: true,
        body: AuthBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth >= 700
                    ? AppSpacing.xxxl
                    : AppSpacing.xl;
                final outerPadding = padding ??
                    EdgeInsetsDirectional.fromSTEB(
                      horizontalPadding,
                      AppSpacing.xxxl,
                      horizontalPadding,
                      AppSpacing.md,
                    );
                final minHeight = mediaQuery.size.height -
                    mediaQuery.padding.vertical -
                    AppSpacing.md * 2;
                final safeMinHeight = minHeight < 0 ? 0.0 : minHeight;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: outerPadding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: safeMinHeight),
                    child: Align(
                      alignment: AlignmentDirectional.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSizes.authContentMaxWidth,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
