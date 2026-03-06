import 'package:flutter/material.dart';
import '../../domain/models/driver_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/network_avatar.dart';

class DriverProfileDetails extends StatelessWidget {
  final Driver driver;

  const DriverProfileDetails({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColorDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Verification Documents",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Viewing documents for ${driver.name}",
              style: const TextStyle(color: AppTheme.textMutedLight, fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            _buildDocItem("Driver Photo", driver.imageUrl),
            _buildDocItem("Aadhar Card", driver.aadharCardPhoto),
            _buildDocItem("Driving License", driver.drivingLicensePhoto),
            _buildDocItem("PAN Card", driver.panCardPhoto),
            _buildDocItem("Signature", driver.signatureUrl),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDocItem(String label, String? url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColorDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderDark),
            ),
            child: url != null && url.isNotEmpty
                ? NetworkAvatarBox(
                    imageUrl: url,
                    name: label,
                    size: 200,
                    shape: BoxShape.rectangle,
                    fallback: const Center(
                      child: Icon(Icons.broken_image_outlined, color: AppTheme.textMutedLight, size: 40),
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_outlined, color: AppTheme.textMutedLight, size: 40),
                        SizedBox(height: 8),
                        Text("Not Uploaded", style: TextStyle(color: AppTheme.textMutedLight)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
