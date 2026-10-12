import 'package:flutter/material.dart';

class VendorPendingScreen extends StatelessWidget {
  final String storeName;
  final String? rejectionReason;

  const VendorPendingScreen({
    super.key,
    required this.storeName,
    this.rejectionReason,
  });

  bool get isRejected => rejectionReason != null;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isRejected
                    ? Colors.red.shade50
                    : Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRejected ? Icons.cancel_outlined : Icons.hourglass_top,
                size: 50,
                color: isRejected ? Colors.red.shade600 : Colors.amber.shade800,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isRejected ? 'Application Rejected' : 'Application Received',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isRejected ? Colors.red.shade700 : const Color(0xFF0A3D7C),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isRejected
                  ? 'Your vendor application for "$storeName" was not approved.\n\n$rejectionReason'
                  : 'Your application for "$storeName" is under review.\n\nWe usually respond within 24–48 hours.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}