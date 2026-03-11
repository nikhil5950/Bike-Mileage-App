import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ImageCaptureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? imagePath;
  final bool isLoading;
  final String? error;
  final VoidCallback onTap;

  const ImageCaptureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.imagePath,
    this.isLoading = false,
    this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppTheme.surfaceElevated;
    if (isLoading) borderColor = AppTheme.primary;
    if (imagePath != null && error == null) borderColor = AppTheme.success;
    if (error != null) borderColor = AppTheme.warning;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imagePath != null && File(imagePath!).existsSync())
                Image.file(File(imagePath!), fit: BoxFit.cover)
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: AppTheme.primary, size: 32),
                    const SizedBox(height: 8),
                    Text(title,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppTheme.textHint, fontSize: 10),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Tap to capture',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              if (imagePath != null)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              if (imagePath != null)
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center),
                ),
              if (isLoading)
                Container(
                  color: Colors.black.withOpacity(0.6),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                            color: AppTheme.primary, strokeWidth: 2.5),
                      ),
                      SizedBox(height: 8),
                      Text('Extracting...',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              if (imagePath != null && !isLoading && error == null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: AppTheme.success, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              if (error != null && imagePath != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: AppTheme.warning, shape: BoxShape.circle),
                    child: const Icon(Icons.warning_rounded,
                        color: Colors.black, size: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
