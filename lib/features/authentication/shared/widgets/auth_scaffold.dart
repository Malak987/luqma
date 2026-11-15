import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import 'auth_background.dart';

/// Common shell for login, register, reset-password and verification.
///
/// It owns safe areas, scrolling, keyboard avoidance and responsive sizing:
/// content is centred vertically when it fits, scrolls when it does not, and
/// is capped to a readable column on tablets and the web.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final isDark = theme.brightness == Brightness.dark;

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
                final padding = _paddingFor(constraints);

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: padding,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppSizes.authContentMaxWidth,
                          ),
                          child: child,
                        ),
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

  EdgeInsets _paddingFor(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final horizontal = width < AppSizes.compactWidth
        ? AppSpacing.md
        : width < AppSizes.mediumWidth
            ? AppSpacing.xl
            : AppSpacing.xxxl;
    final vertical =
        constraints.maxHeight < 600 ? AppSpacing.md : AppSpacing.xxl;

    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }
}
