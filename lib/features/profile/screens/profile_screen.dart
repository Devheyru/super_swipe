import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_swipe/core/theme/app_theme.dart';
import 'package:super_swipe/features/auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAnonymous = user?.isAnonymous == true;
    final displayName = isAnonymous
        ? 'Guest User'
        : (authState.displayName ?? user?.displayName ?? 'User');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. User Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryLight,
                      border:
                          Border.all(color: AppTheme.primaryColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(displayName),
                        style: const TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // 2. Stats
            Row(
              children: [
                Expanded(child: _buildStat('24', 'Items', Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildStat('12', 'Cooked', Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildStat('5', 'Saved', Colors.red)),
              ],
            ),

            const SizedBox(height: AppTheme.spacingL),

            // 3. Dietary Preferences
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dietary Preferences',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('Vegetarian', true),
                      _buildFilterChip('Vegan', false),
                      _buildFilterChip('Gluten-Free', false),
                      _buildFilterChip('Keto', false),
                      _buildAddChip(),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingL),

            // 4. Menu Options
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  _buildMenuItem(Icons.favorite_border_rounded, 'My Favorites'),
                  _buildDivider(),
                  _buildMenuItem(Icons.shopping_bag_outlined, 'Shopping List'),
                  _buildDivider(),
                  _buildMenuItem(Icons.help_outline_rounded, 'Help & Support'),
                ],
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.13),

            // 5. Sign Out
            TextButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                backgroundColor: AppTheme.surfaceColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Sign Out',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color.shade700)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color.shade700,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildAddChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.add, size: 16, color: Colors.grey),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: () {},
    );
  }

  Widget _buildDivider() {
    return const Divider(
        height: 1, indent: 70, endIndent: 20, color: Color(0xFFF5F5F5));
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    return name[0].toUpperCase();
  }
}
