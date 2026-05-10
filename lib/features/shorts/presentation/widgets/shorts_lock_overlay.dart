import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class ShortsLockOverlay extends StatelessWidget {
  final VoidCallback onSubscribe;

  const ShortsLockOverlay({
    super.key,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE4B200),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: Responsive.padding(context, all: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: Responsive.iconSize(context, 84),
                  color: Colors.white,
                ),
                SizedBox(height: Responsive.spacing(context, 20)),
                Text(
                  'اشترك لفتح باقي الفيديوهات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: Responsive.fontSize(context, 21),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.spacing(context, 24)),
                SizedBox(
                  width: Responsive.width(context, 180),
                  height: Responsive.height(context, 48),
                  child: ElevatedButton(
                    onPressed: onSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'اشترك من هنا',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: Responsive.fontSize(context, 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
