import 'package:flutter/material.dart';

import 'look.dart';

/// The frame for the number caller, my tickets and print screens: the wooden
/// table, a top bar with a back button, and scrolling content.
class ToolScaffold extends StatelessWidget {
  const ToolScaffold({super.key, required this.title, required this.children, this.actions = const []});
  final String title;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Palette.wood3,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D0F05),
        foregroundColor: Palette.cream,
        title: Text(
          title,
          style: const TextStyle(fontFamily: Fonts.display, color: Palette.brass, fontSize: 22, letterSpacing: .5),
        ),
        actions: actions,
      ),
      body: WoodBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + bottom),
          children: [
            for (final c in children)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Padding(padding: const EdgeInsets.only(bottom: 18), child: c),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A sheet of paper holding a section of a tool screen.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.title});
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-.2, -1),
          end: Alignment(.2, 1),
          colors: [Color(0xFFFBF6E8), Palette.paper, Color(0xFFEFE4C7)],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: tableShadow,
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(fontFamily: Fonts.display, color: Palette.ticketRed, fontSize: 22),
              ),
              const SizedBox(height: 10),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// A note in small print on a panel.
class Note extends StatelessWidget {
  const Note(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(fontSize: 13, height: 1.45, color: Palette.ink.withValues(alpha: .75)));
}
