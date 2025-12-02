import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:streamapp/features/home/widgets/category_filter_widget.dart';
import 'package:streamapp/features/home/widgets/content_row_widget.dart';
import 'package:streamapp/features/home/widgets/hero_carousel_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        const SizedBox(height: 20),
          const CategoryFilterWidget(),
          const SizedBox(height: 24),
          const HeroCarouselWidget(),
          const SizedBox(height: 40),
          ContentRowWidget(title: 'popular'.tr()),
          const SizedBox(height: 32),
          ContentRowWidget(title: 'continue_watching'.tr()),
          const SizedBox(height: 32),
          ContentRowWidget(title: 'new_releases'.tr()),
          const SizedBox(height: 32),
          ContentRowWidget(title: 'trending_now'.tr()),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
