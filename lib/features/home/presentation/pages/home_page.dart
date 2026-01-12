import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../widgets/explore_section.dart';
import '../widgets/home_background.dart';
import '../widgets/quick_link_grid.dart';
import '../widgets/search_card_section.dart';

@Preview()
Widget previewHomePage() => const HomePage();

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const SearchCardSection(),
              const SizedBox(height: 24),
              const QuickLinkGrid(),
              const SizedBox(height: 40), // Spacer before center content
              ExploreSection(),
              const SizedBox(height: 120), // Spacer to clear BottomNavBar
            ],
          ),
        ),
      ),
    );
  }
}
