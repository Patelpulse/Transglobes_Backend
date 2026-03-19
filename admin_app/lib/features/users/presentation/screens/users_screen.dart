import 'package:flutter/material.dart';
import '../widgets/admin_user_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/network_avatar.dart';
import '../../../../shared/widgets/community_card.dart';
import '../providers/user_provider.dart';
import '../../domain/models/user_model.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = ref.watch(filteredUsersProvider);
    final currentFilter = ref.watch(userFilterProvider);
    final usersAsyncValue = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'User Management',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 300,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                // Implement search logic if needed
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/users/new'),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterChips(currentFilter),
            Expanded(
              child: usersAsyncValue.when(
                data: (_) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(usersProvider);
                      ref.invalidate(systemLogsProvider);
                      ref.invalidate(platformOverviewProvider);
                    },
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      children: [
                        if (filteredUsers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                "No users found matching criteria.",
                                style: TextStyle(
                                  color: AppTheme.textMutedLight,
                                ),
                              ),
                            ),
                          )
                        else
                          ...filteredUsers.map(
                            (user) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildUserCard(user),
                            ),
                          ),
                        const SizedBox(height: 24),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            "PLATFORM OVERVIEW",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMutedLight,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        _buildPlatformOverviewGrid(),
                        const SizedBox(height: 16),
                        _buildSystemLogs(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.danger,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Failed to load user data.",
                        style: TextStyle(color: AppTheme.textPrimaryLight),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.invalidate(usersProvider);
                          ref.invalidate(systemLogsProvider);
                          ref.invalidate(platformOverviewProvider);
                        },
                        child: const Text(
                          "Retry",
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildFilterChips(UserFilter currentFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip("All Users", UserFilter.all, currentFilter),
          _buildChip("Personal", UserFilter.personal, currentFilter),
          _buildChip("Business", UserFilter.business, currentFilter),
          _buildChip("Active", UserFilter.active, currentFilter),
        ],
      ),
    );
  }

  Widget _buildChip(String label, UserFilter filter, UserFilter currentFilter) {
    final isSelected = filter == currentFilter;
    return GestureDetector(
      onTap: () {
        ref.read(userFilterProvider.notifier).setFilter(filter);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    return AdminUserCard(
      user: user,
      onViewProfile: () => _showUserDetails(context, user),
    );
  }

  void _showUserDetails(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppTheme.backgroundColorDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          NetworkAvatarBox(
                            imageUrl: user.imageUrl,
                            name: user.name,
                            size: 100,
                            shape: BoxShape.circle,
                            borderColor: AppTheme.primaryColor,
                            borderWidth: 3,
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: user.status == UserStatus.active
                                  ? AppTheme.success
                                  : AppTheme.textSecondaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.backgroundColorDark,
                                width: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textMutedLight,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Account Type",
                          style: TextStyle(
                            color: AppTheme.textMutedLight,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          user.type.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.borderDark, height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Wallet Balance",
                          style: TextStyle(
                            color: AppTheme.textMutedLight,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            symbol: '\$',
                          ).format(user.walletBalance),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.borderDark, height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Last Active",
                          style: TextStyle(
                            color: AppTheme.textMutedLight,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          user.lastActive ?? "N/A",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surfaceColorDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppTheme.borderDark),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Manage ${user.name}')),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Manage User Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlatformOverviewGrid() {
    final overviewAsync = ref.watch(platformOverviewProvider);

    return overviewAsync.when(
      data: (overview) {
        final totalFleets = overview['totalFleets'] as int;
        final fleetGrowth = overview['fleetGrowth'] as double;
        final supportTickets = overview['supportTickets'] as int;
        final urgentTickets = overview['urgentTickets'] as int;

        return Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TOTAL FLEETS",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat('#,###').format(totalFleets),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          fleetGrowth >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: fleetGrowth >= 0
                              ? AppTheme.success
                              : AppTheme.danger,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${(fleetGrowth * 100).toStringAsFixed(0)}% Inc.",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: fleetGrowth >= 0
                                ? AppTheme.success
                                : AppTheme.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColorDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "SUPPORT TICKETS",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMutedLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      supportTickets.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.priority_high,
                          color: AppTheme.warning,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$urgentTickets Urgent",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const Center(
        child: Text(
          "Error loading overview",
          style: TextStyle(color: AppTheme.danger),
        ),
      ),
    );
  }

  Widget _buildSystemLogs() {
    final logsAsync = ref.watch(systemLogsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColorDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "System Logs",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  "View All",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderDark),
          logsAsync.when(
            data: (logs) {
              return Column(
                children: [
                  for (final log in logs) ...[
                    _buildLogItem(log),
                    if (log != logs.last)
                      const Divider(height: 1, color: AppTheme.borderDark),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  "Error loading logs",
                  style: TextStyle(color: AppTheme.danger),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(SystemLog log) {
    IconData icon;
    Color iconColor;

    switch (log.iconType) {
      case 'cab':
        icon = Icons.local_taxi;
        iconColor = AppTheme.primaryColor;
        break;
      case 'ticket':
        icon = Icons.confirmation_number;
        iconColor = AppTheme.warning;
        break;
      case 'payout':
        icon = Icons.attach_money;
        iconColor = AppTheme.success;
        break;
      default:
        icon = Icons.info;
        iconColor = AppTheme.textMutedLight;
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                log.description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMutedLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
