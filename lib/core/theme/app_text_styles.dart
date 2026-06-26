import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padbro/core/theme/app_colors.dart';

/// Centralized text styles for the PadBro app
/// Use these instead of defining text styles inline
class AppTextStyles {
  AppTextStyles._();

  // ============================================
  // HEADINGS
  // ============================================

  /// Large page title (24px, extra bold)
  /// Usage: Main page titles, user display name
  static TextStyle get heading1 => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  /// Section title (20px, bold)
  /// Usage: Section headers, greeting text
  static TextStyle get heading2 => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Card title (18px, extra bold)
  /// Usage: Court names, booking titles, section headers
  static TextStyle get heading3 => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  /// Small card title (16px, bold)
  /// Usage: Featured court names, smaller card titles
  static TextStyle get heading4 => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Mini title (15px, bold)
  /// Usage: Coach names, list item titles
  static TextStyle get heading5 => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  // ============================================
  // BODY TEXT
  // ============================================

  /// Body large semibold (14px, semibold)
  /// Usage: Prices, important information
  static TextStyle get bodyLargeSemibold => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Body large (14px, regular)
  /// Usage: Regular body text, descriptions
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  /// Body medium semibold (13px, semibold)
  /// Usage: "See All", "View All" links, tab labels
  static TextStyle get bodySemibold => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Body medium (13px, regular)
  /// Usage: Secondary text, location info, descriptions
  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // ============================================
  // CAPTIONS & LABELS
  // ============================================

  /// Caption semibold (12px, semibold)
  /// Usage: Timestamps, category labels, small info
  static TextStyle get captionSemibold => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Caption (12px, regular)
  /// Usage: Metadata, time info, secondary details
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  /// Small caption bold (11px, bold)
  /// Usage: Badge text, court count, very small labels
  static TextStyle get captionSmallBold => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Small caption (11px, regular)
  /// Usage: Very small secondary text
  static TextStyle get captionSmall => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  /// Tiny text (10px, bold)
  /// Usage: Material badges, tiny labels
  static TextStyle get tiny => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.0,
      );

  // ============================================
  // BUTTON TEXT
  // ============================================

  /// Button large (16px, extra bold)
  /// Usage: Primary CTA buttons
  static TextStyle get buttonLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  /// Button medium (15px, bold)
  /// Usage: Secondary buttons, dialog buttons
  static TextStyle get buttonMedium => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Button small (13px, bold)
  /// Usage: Small buttons, inline actions
  static TextStyle get buttonSmall => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Button tiny (12px, semibold)
  /// Usage: Very small buttons, "Book Now" on cards
  static TextStyle get buttonTiny => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ============================================
  // SPECIAL STYLES
  // ============================================

  /// Error text (14px, medium)
  static TextStyle get error => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.error,
      );

  /// Link text (14px, semibold)
  static TextStyle get link => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      );

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Create a copy with a different color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Create a white version of a style
  static TextStyle white(TextStyle style) {
    return style.copyWith(color: Colors.white);
  }

  /// Create a secondary (gray) version of a style
  static TextStyle secondary(TextStyle style) {
    return style.copyWith(color: AppColors.textSecondary);
  }
}
