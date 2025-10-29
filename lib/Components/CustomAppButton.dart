import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

import '../utils/color_constants.dart';

class CustomAppButton1 extends StatelessWidget {
  final String text;
  final Color? textcolor;
  final double? width;
  final double? height;
  final double? textSize;
  final VoidCallback? onPlusTap;
  final IconData? icon;
  final bool isLoading;
  final int? radius;

  const CustomAppButton1({
    Key? key,
    required this.text,
    required this.onPlusTap,
    this.textcolor,
    this.height,
    this.width,
    this.textSize,
    this.isLoading = false,
    this.icon,
    this.radius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = width ?? MediaQuery.of(context).size.width;
    final double buttonHeight = height ?? 48;
    final int borderRadius = radius ?? 24;
    final Color textColor = textcolor ?? Colors.white;

    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPlusTap,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.toDouble()),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: kCommonGradient,
            borderRadius: BorderRadius.circular(borderRadius.toDouble()),
          ),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 1.5,
                    ),
                  )
                else
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'segeo',
                      fontSize: textSize??16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (!isLoading && icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: textColor, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final int radius;
  final bool isLoading;
  final IconData? icon;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;

  const CustomOutlinedButton({
    super.key,
    required this.text,
    required this.onTap,
    this.width,
    this.height,
    this.radius = 12,
    this.isLoading = false,
    this.icon,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius.toDouble());

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            height: 20, width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 1.5, color: Color(0xFF6D6BFF),
            ),
          )
        else
          Text(
            text,
            style: textStyle ??
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6D6BFF),
                ),
          ),
        if (!isLoading && icon != null) ...[
          const SizedBox(width: 8),
          Icon(icon, size: 18, color: const Color(0xFF6D6BFF)),
        ],
      ],
    );

    // Outer gradient -> inner white = gradient outline effect
    Widget button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: kCommonGradient,
        borderRadius: borderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(1), // outline thickness
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
          ),
          child: Padding(
            padding: height == null ? padding : EdgeInsets.zero,
            child: Center(child: content),
          ),
        ),
      ),
    );

    // Respect custom width/height only if provided
    if (width != null || height != null) {
      button = SizedBox(width: width, height: height, child: button);
    }

    // Ripple + tap
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: isLoading ? null : onTap,
        child: button,
      ),
    );
  }
}


class CustomOutlinedButton1 extends StatelessWidget {
  final String text;
  final Color? textColor;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isLoading;
  final int? radius;
  final Color? bgColor;
  final Color? borderColor;

  const CustomOutlinedButton1({
    Key? key,
    required this.text,
    required this.onTap,
    this.textColor,
    this.width,
    this.height,
    this.icon,
    this.isLoading = false,
    this.radius,
    this.bgColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double buttonWidth = width ?? MediaQuery.of(context).size.width;
    final double buttonHeight = height ?? 48;
    final int borderRadius = radius ?? 12;
    final Color finalTextColor = textColor ?? const Color(0xFF6D6BFF);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: kCommonGradient,
        borderRadius: BorderRadius.circular(borderRadius.toDouble()),
      ),
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact,padding: EdgeInsets.zero,
          backgroundColor:bgColor?? Colors.white,
          side: BorderSide(
            color: borderColor ?? Color(0xFF7B7F8C),
            width: 1.2,
          ),
          fixedSize: Size(buttonWidth, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.toDouble()),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
               SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFF6D6BFF),
                  strokeWidth: 1.5,
                ),
              )
            else
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: finalTextColor,
                ),
              ),
            if (!isLoading && icon != null) ...[
               SizedBox(width: 8),
              Icon(icon, color: finalTextColor, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}


class DashedOutlinedButton extends StatelessWidget {
  final double height;
  final double radius;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final String text;
  final VoidCallback onTap;
  final TextStyle? textStyle;
  final EdgeInsets padding;

  const DashedOutlinedButton({
    super.key,
    this.height = 36,
    this.radius = 24,
    this.bgColor = Colors.white,
    this.borderColor = const Color(0xFF999999),
    this.textColor = const Color(0xFF333333),
    required this.text,
    required this.onTap,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      color: borderColor,
      strokeWidth: 1.2,
      dashPattern: const [6, 4], // length of dash, gap
      borderType: BorderType.RRect,
      radius: Radius.circular(radius),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(radius),
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: (textStyle ??
                  TextStyle(
                    fontFamily: 'segeo',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
