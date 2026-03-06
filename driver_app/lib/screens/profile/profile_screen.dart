import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import '../../providers/vehicle_type_provider.dart';
import '../../services/driver_service.dart';
import '../../services/auth_service.dart';
import '../../models/driver_model.dart';
import '../../core/app_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _locationSharing = true;

  @override
  Widget build(BuildContext context) {
    final vehicleType = ref.watch(vehicleTypeProvider);
    final isDark = ref.watch(themeProvider);
    final driverProfile = ref.watch(driverProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Profile header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, left: 20, right: 20, bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark ? vehicleType.accentColor.withOpacity(0.15) : const Color(0xFFE3F2FD),
                    Theme.of(context).scaffoldBackgroundColor
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: driverProfile.when(
                data: (driver) => Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [vehicleType.accentColor, vehicleType.accentColor.withValues(alpha: 0.5)])),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            backgroundImage: (driver?.profilePic != null && driver!.profilePic!.isNotEmpty) ? NetworkImage(driver!.profilePic!) : null,
                            child: (driver?.profilePic == null || driver!.profilePic!.isEmpty) ? Icon(Icons.person, color: vehicleType.accentColor, size: 46) : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: InkWell(
                            onTap: () {
                              if (driver != null) {
                                Navigator.pushNamed(context, AppRouter.editProfile, arguments: driver);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: AppTheme.neonGreen, shape: BoxShape.circle),
                              child: const Icon(Icons.edit, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(driver?.name ?? 'Complete Profile', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(driver?.phoneNumber ?? 'No Phone Number', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statPill(Icons.star, '${driver?.rating ?? '0.0'}', AppTheme.earningsAmber),
                        const SizedBox(width: 12),
                        _statPill(Icons.directions_car, '${driver?.totalRides ?? 0} Trips', vehicleType.accentColor),
                        const SizedBox(width: 12),
                        _statPill(Icons.verified, driver?.onboardingComplete == true ? 'Verified' : 'Pending', driver?.onboardingComplete == true ? AppTheme.neonGreen : AppTheme.earningsAmber),
                      ],
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle card
                  _buildSectionHeader('My Vehicle'),
                  driverProfile.when(
                    data: (driver) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: vehicleType.accentColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: vehicleType.accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                            child: Icon(vehicleType.icon, color: vehicleType.accentColor, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(driver?.vehicleModel ?? 'Vehicle Model', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: Theme.of(context).dividerColor)),
                                      child: Text(driver?.vehicleNumberPlate ?? 'NO PLATE', style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 11, fontFamily: 'monospace')),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${driver?.vehicleYear ?? '2024'} • ${vehicleType.label}', style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 11)),
                                  ]),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (driver != null) {
                                Navigator.pushNamed(context, AppRouter.editProfile, arguments: driver);
                              }
                            },
                            icon: Icon(Icons.edit_outlined, color: vehicleType.accentColor, size: 20),
                          ),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                    error: (_, __) => const Text('Error loading vehicle'),
                  ),
                  const SizedBox(height: 20),

                  // Documents
                  _buildSectionHeader('Documents'),
                  driverProfile.when(
                    data: (driver) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        children: [
                          _buildDocRow(
                            'Email Verified', 
                            'Email Verified', 
                            driver?.isEmailVerified ?? false,
                            isVerified: driver?.isEmailVerified ?? false
                          ),
                          const Divider(height: 20),
                          _buildDocRow(
                            'Driving License', 
                            driver?.drivingLicenseNumber ?? 'Action Required', 
                            driver?.licenseUrl != null,
                            isVerified: driver?.drivingLicenseVerified ?? false
                          ),
                          const Divider(height: 20),
                          _buildDocRow(
                            'Aadhar Card', 
                            driver?.aadharCardNumber ?? 'Action Required', 
                            driver?.aadhaarUrl != null,
                            isVerified: driver?.aadharVerified ?? false
                          ),
                          const Divider(height: 20),
                          _buildDocRow(
                            'PAN Card', 
                            driver?.panCardNumber ?? 'Action Required', 
                            driver?.panUrl != null || (driver?.panCardNumber != null && driver!.panCardNumber!.isNotEmpty),
                            isVerified: driver?.panVerified ?? false
                          ),
                          const Divider(height: 20),
                          _buildDocRow(
                            'Signature', 
                            driver?.signatureUrl != null ? 'Uploaded' : 'Action Required', 
                            driver?.signatureUrl != null
                          ),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox(height: 80),
                    error: (_, __) => const Text('Error loading documents'),
                  ),
                  const SizedBox(height: 20),

                  // Settings
                  _buildSectionHeader('Settings'),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        _buildToggle('Dark Mode', Icons.dark_mode_outlined, AppTheme.earningsAmber, isDark, (v) => ref.read(themeProvider.notifier).toggle()),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildToggle('Push Notifications', Icons.notifications_outlined, AppTheme.neonGreen, _notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildToggle('Location Sharing', Icons.location_on_outlined, AppTheme.cabBlue, _locationSharing, (v) => setState(() => _locationSharing = v)),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildArrowTile(Icons.language, 'Language', 'English', AppTheme.busPurple),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildArrowTile(Icons.help_outline, 'Support & Help', '', AppTheme.earningsAmber),
                        const Divider(color: AppTheme.darkDivider, height: 1, indent: 16, endIndent: 16),
                        _buildArrowTile(Icons.policy_outlined, 'Terms & Privacy', '', AppTheme.darkTextSecondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, AppRouter.auth, (r) => false);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.offlineRed,
                        side: BorderSide(color: AppTheme.offlineRed.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(25), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
    );
  }

  Widget _buildDocRow(String name, String status, bool? uploaded, {bool isVerified = false}) {
    final color = isVerified ? AppTheme.neonGreen : (uploaded == true ? AppTheme.earningsAmber : AppTheme.offlineRed);
    final icon = isVerified ? Icons.verified : (uploaded == true ? Icons.check_circle : Icons.pending);
    final statusText = isVerified ? 'Verified' : status;

    return Row(
      children: [
        Icon(Icons.description_outlined, color: AppTheme.darkTextSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(statusText, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildToggle(String label, IconData icon, Color color, bool value, Function(bool) onChanged) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: color),
    );
  }

  Widget _buildArrowTile(IconData icon, String label, String sub, Color color) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (sub.isNotEmpty) Text(sub, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: AppTheme.darkDivider, size: 18),
      ]),
      onTap: () {},
    );
  }
}
