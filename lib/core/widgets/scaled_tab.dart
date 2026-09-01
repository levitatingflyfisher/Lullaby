import 'package:flutter/material.dart';

/// A [Tab] whose height grows with the text scale.
///
/// A text-only Tab is a fixed 46dp, so at large text the label is laid out
/// taller than the tab and its glyphs are cropped top and bottom. This one
/// measures its label with the current text scaler and is never shorter
/// than Material's 46dp. It returns a real [Tab] so that [TabBar] (and an
/// AppBar's `bottom`) size themselves from its height.
Tab scaledTab(BuildContext context, String text) =>
    Tab(text: text, height: scaledTabHeight(context, text));

/// Height for a tab showing [text] in [context]'s tab label style.
double scaledTabHeight(BuildContext context, String text) {
  const materialHeight = 46.0;
  final theme = Theme.of(context);
  final style = theme.tabBarTheme.labelStyle ?? theme.textTheme.titleSmall;
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final needed = painter.height + 16;
  return needed > materialHeight ? needed : materialHeight;
}
