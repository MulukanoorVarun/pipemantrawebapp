import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

FadeShimmer_box_elite(height, width, radius) {
  return Container(
    margin: EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Color(0xFF3D3D3D),
      borderRadius: BorderRadius.circular(radius),
    ),
    height: height,
    width: width,
  );
}

FadeShimmer_box_porter(height, width, radius) {
  return Container(
    margin: EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Color(0xFF959595),
      borderRadius: BorderRadius.circular(radius),
    ),
    height: height,
    width: width,
  );
}

shimmerCircle(double size, BuildContext context) {
  // Light mode colors
  final baseColor = Colors.grey[300]!;
  final highlightColor = Colors.grey[100]!;

  return Shimmer.fromColors(
    baseColor: baseColor,
    highlightColor: highlightColor,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
    ),
  );
}

Widget shimmerRectangle(double size, BuildContext context) {
  // Light mode colors
  final baseColor = Colors.grey[300]!;
  final highlightColor = Colors.grey[100]!;

  return Shimmer.fromColors(
    baseColor: baseColor,
    highlightColor: highlightColor,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}

shimmerDivider(double height, double width, BuildContext context) {
  final baseColor = Colors.grey[300]!;
  final highlightColor = Colors.grey[100]!;
  return Shimmer.fromColors(
    child: Container(
      height: height,
      width: width,
      decoration: BoxDecoration(color: Colors.white),
    ),
    baseColor: baseColor,
    highlightColor: highlightColor,
  );
}

shimmerContainer(
  double width,
  double height,
  BuildContext context, {
  bool isButton = false,
}) {
  // Light mode colors
  final baseColor = Colors.grey[300]!;
  final highlightColor = Colors.grey[100]!;

  return Shimmer.fromColors(
    baseColor: baseColor,
    highlightColor: highlightColor,
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isButton ? Colors.grey : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: isButton
          ? Center(child: shimmerText(80, 18, context))
          : SizedBox(),
    ),
  );
}

// Shimmer component for text
shimmerText(double width, double height, BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
  final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;
  return Shimmer.fromColors(
    baseColor: baseColor,
    highlightColor: highlightColor,
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color(0xffE6E8EB),
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  );
}

// Shimmer component for linear progress bar
shimmerLinearProgress(double height, BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
  final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;
  return Shimmer.fromColors(
    baseColor: baseColor,
    highlightColor: highlightColor,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: Color(0xffE6E8EB),
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  );
}
