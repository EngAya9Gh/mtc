import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  factory AppText.displayLarge(String text, {Color? color}) => AppText(
        text,
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
      );

  factory AppText.displayMedium(String text, {Color? color}) => AppText(
        text,
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
      );

  factory AppText.titleLarge(String text, {Color? color}) => AppText(
        text,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color),
      );

  factory AppText.bodyLarge(String text, {Color? color}) => AppText(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: color),
      );

  factory AppText.bodyMedium(String text, {Color? color}) => AppText(
        text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: color),
      );
}
