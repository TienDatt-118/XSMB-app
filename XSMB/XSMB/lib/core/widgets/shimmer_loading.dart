import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerResultTable extends StatelessWidget {
  const ShimmerResultTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dummy Lottie animation that fails gracefully if file not found
        SizedBox(
          height: 80,
          child: Lottie.asset(
            'assets/animations/loading.json',
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        const SizedBox(height: 12),
        const ShimmerBox(width: double.infinity, height: 48, borderRadius: 12),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const ShimmerBox(width: 80, height: 24),
            ShimmerBox(width: MediaQuery.of(context).size.width * 0.6, height: 24),
          ],
        ),
        const Divider(height: 24),
        ...List.generate(7, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const ShimmerBox(width: 80, height: 32, borderRadius: 8),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(index == 0 ? 1 : (index == 5 ? 3 : 2), (i) {
                      return const ShimmerBox(width: 50, height: 24, borderRadius: 4);
                    }),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class ShimmerChartsLoading extends StatelessWidget {
  const ShimmerChartsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerBox(width: 150, height: 24),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            return ShimmerBox(width: 40, height: 120 + (index % 2 * 30), borderRadius: 6);
          }),
        ),
        const SizedBox(height: 24),
        const ShimmerBox(width: double.infinity, height: 160, borderRadius: 16),
      ],
    );
  }
}

class ShimmerListLoading extends StatelessWidget {
  const ShimmerListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              const ShimmerBox(width: 60, height: 60, borderRadius: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerBox(width: 120, height: 18),
                    const SizedBox(height: 8),
                    ShimmerBox(width: MediaQuery.of(context).size.width * 0.5, height: 14),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
