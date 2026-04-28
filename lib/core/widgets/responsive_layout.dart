import 'package:flutter/material.dart';

class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;
}

/// Adaptive layout for mobile/tablet/desktop
/// 
/// Usage:
/// ```dart
/// ResponsiveLayout(
///   mobileChild: MobileWidget(),
///   tabletChild: TabletWidget(),
///   desktopChild: DesktopWidget(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileChild;
  final Widget? tabletChild;
  final Widget? desktopChild;

  const ResponsiveLayout({
    required this.mobileChild,
    this.tabletChild,
    this.desktopChild,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return mobileChild;
        } else if (constraints.maxWidth < AppBreakpoints.tablet) {
          return tabletChild ?? mobileChild;
        } else {
          return desktopChild ?? tabletChild ?? mobileChild;
        }
      },
    );
  }
}

/// Centered responsive column for desktop
/// 
/// On mobile: regular column with padding
/// On tablet/desktop: centered column with max width constraint
class ResponsiveColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double maxWidth;
  final EdgeInsets padding;

  const ResponsiveColumn({
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.maxWidth = 800,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppBreakpoints.mobile;

        if (isMobile) {
          return Padding(
            padding: padding,
            child: Column(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              children: children,
            ),
          );
        }

        // Desktop: center with max width
        return Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: padding,
                child: Column(
                  mainAxisAlignment: mainAxisAlignment,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Grid that adapts column count based on screen size
/// 
/// Default: 1 column mobile, 2 tablet, 3 desktop
/// Customizable via constructor parameters
class ResponsiveGrid extends StatelessWidget {
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final List<Widget> children;
  final double spacing;
  final double childAspectRatio;

  const ResponsiveGrid({
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16,
    this.childAspectRatio = 1,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        late int crossAxisCount;
        if (constraints.maxWidth < 600) {
          crossAxisCount = mobileColumns;
        } else if (constraints.maxWidth < 1200) {
          crossAxisCount = tabletColumns;
        } else {
          crossAxisCount = desktopColumns;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
          children: children,
        );
      },
    );
  }
}