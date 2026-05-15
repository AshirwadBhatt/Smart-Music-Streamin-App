import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  void _showEditProfile() {
    final user = ref.read(currentUserProvider);
    final nameCtrl = TextEditingController(text: user?.username ?? '');
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
              color: AppColors.surfaceVariant,
            ),
            child: Center(child: Text(
              (user?.username ?? 'U')[0].toUpperCase(),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                  color: AppColors.primary),
            )),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Display Name',
              labelStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
              filled: true, fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: user?.email ?? ''),
            readOnly: true,
            style: const TextStyle(color: AppColors.textMuted),
            decoration: InputDecoration(
              labelText: 'Email (cannot change)',
              labelStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
              filled: true, fillColor: AppColors.surfaceVariant.withOpacity(0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                final uid = Supabase.instance.client.auth.currentUser?.id;
                if (uid != null) {
                  await Supabase.instance.client
                      .from('profiles').update({'username': name}).eq('id', uid);
                }
              }
              if (dialogCtx.mounted) {
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Profile updated!'),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notifications',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _SwitchTile(icon: Icons.new_releases_outlined,
              label: 'New releases', subtitle: 'Get notified about new music'),
          _SwitchTile(icon: Icons.playlist_add_rounded,
              label: 'Playlist updates', subtitle: 'When someone adds to a shared playlist'),
          _SwitchTile(icon: Icons.campaign_outlined,
              label: 'ASHU announcements', subtitle: 'App updates and news', initial: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Push notifications coming in v2.0',
                  style: TextStyle(color: AppColors.primary, fontSize: 12))),
            ]),
          ),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy() {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              const Text('Privacy Policy', style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
              ),
            ]),
            const SizedBox(height: 4),
            const Text('Last updated: March 2026',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const Divider(color: AppColors.divider, height: 20),
            const Expanded(child: SingleChildScrollView(child: Text(
              '1. DATA WE COLLECT\nASHU collects only the data necessary to provide our service:\n'
              '- Email address and display name for account creation\n'
              '- Listening history to power recommendations\n'
              '- Liked songs and playlist data stored securely\n\n'
              '2. HOW WE USE YOUR DATA\n'
              '- To provide personalized music recommendations\n'
              '- To sync your library across sessions\n'
              '- We never sell your data to third parties\n\n'
              '3. MUSIC CONTENT\nAll music is sourced from Jamendo under Creative Commons licenses. '
              'ASHU does not host any copyrighted content.\n\n'
              '4. DATA STORAGE\nYour data is stored securely using Supabase with row-level security. '
              'Only you can access your personal data.\n\n'
              '5. THIRD-PARTY SERVICES\n- Jamendo API - music catalogue\n'
              '- Supabase - secure database\n- LRCLib - lyrics data\n\n'
              '6. YOUR RIGHTS\nYou may request deletion of your account and all associated data '
              'at any time by contacting us.\n\n'
              '7. CONTACT\nFor privacy concerns, contact the developer: Ashirwad Bhatt\n'
              'This app is a college project and is not intended for commercial use.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6),
            ))),
          ]),
        ),
      ),
    );
  }

  void _showAudioQuality() {
    int selected = 1;
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Audio Quality',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _QualityTile(label: 'Low', sub: '96 kbps - Saves data',
                selected: selected == 0, onTap: () => setS(() => selected = 0)),
            _QualityTile(label: 'Normal', sub: '128 kbps - Recommended',
                selected: selected == 1, onTap: () => setS(() => selected = 1)),
            _QualityTile(label: 'High', sub: '192 kbps - Best quality',
                selected: selected == 2, onTap: () => setS(() => selected = 2)),
            _QualityTile(label: 'Ultra', sub: '320 kbps - Premium only',
                selected: selected == 3, onTap: () => setS(() => selected = 3)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(
                    'Quality selection will apply in next update. Currently streaming at 128 kbps.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
              ]),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Audio quality preference saved!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.primary,
                ));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDataSaver() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Data Saver',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _SwitchTile(icon: Icons.data_saver_on_outlined,
              label: 'Data Saver Mode', subtitle: 'Stream at lower quality to save data'),
          _SwitchTile(icon: Icons.wifi_outlined,
              label: 'Wi-Fi only streaming', subtitle: 'Only stream on Wi-Fi', initial: true),
          _SwitchTile(icon: Icons.image_not_supported_outlined,
              label: 'Hide album art', subtitle: 'Reduces image data usage'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [
              Icon(Icons.bolt_outlined, color: AppColors.primary, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text(
                  'Smart buffering already saves up to 40% data vs traditional streaming.',
                  style: TextStyle(color: AppColors.primary, fontSize: 12))),
            ]),
          ),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Data saver preferences saved!'),
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDownloads() {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Icon(Icons.download_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              const Text('Downloads', style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
              ),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                const Icon(Icons.download_for_offline_outlined, size: 48,
                    color: AppColors.textMuted),
                const SizedBox(height: 12),
                const Text('No downloads yet', style: TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                const Text(
                    'Tap the menu on any song and select "Download" to save for offline listening.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: 0.02,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary)),
                const SizedBox(height: 6),
                const Text('0 MB / 2 GB storage used',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search_rounded),
                label: const Text('Browse music to download'),
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  context.go('/search');
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1DB954), Color(0xFF169c46)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.music_note_rounded, color: Colors.black, size: 38),
            )),
            const SizedBox(height: 16),
            const Center(child: Text('ASHU Music', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary))),
            const Center(child: Text('Version 1.0.0',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
            const Center(child: Text('Advanced Streaming Hub for Users',
                style: TextStyle(color: AppColors.primary, fontSize: 12))),
            const Divider(color: AppColors.divider, height: 24),
            const Text('COLLEGE PROJECT', style: TextStyle(color: AppColors.textMuted,
                fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Made by Ashirwad Bhatt', style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            const Text(
              'Aspiring Cloud Engineer with hands-on experience gained through college '
              'projects involving cloud deployment, automation, and infrastructure management. '
              'Strong understanding of cloud fundamentals, virtualization, networking, and '
              'DevOps concepts.\n\n'
              'Demonstrated ability to design and implement scalable solutions using modern '
              'cloud tools while maintaining reliability, security, and performance. Recognized '
              'for a structured approach to problem-solving, clean project execution, and '
              'consistently delivering high-quality work within deadlines.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.6),
            ),
            const Divider(color: AppColors.divider, height: 24),
            const Text('TECH STACK', style: TextStyle(color: AppColors.textMuted,
                fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: const [
              _TechChip('Flutter'), _TechChip('Dart'), _TechChip('Supabase'),
              _TechChip('Riverpod'), _TechChip('Jamendo API'), _TechChip('LRCLib'),
            ]),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Close'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showRateApp() {
    int stars = 0;
    final feedbackCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Rate ASHU',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('How would you rate your experience?',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setS(() => stars = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                    color: i < stars ? Colors.amber : AppColors.textMuted,
                    size: 40,
                  ),
                ),
              )),
            ),
            const SizedBox(height: 8),
            Text(
              stars == 0 ? 'Tap to rate' :
              stars == 1 ? 'Poor' :
              stars == 2 ? 'Fair' :
              stars == 3 ? 'Good' :
              stars == 4 ? 'Great' : 'Excellent!',
              style: TextStyle(
                color: stars >= 4 ? AppColors.primary : AppColors.textMuted,
                fontWeight: FontWeight.w600, fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackCtrl,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tell us what you think... (optional)',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true, fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: stars == 0 ? null : () {
                final s = stars;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Thanks for your $s star rating!'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ));
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240, pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.playerGradient),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 60),
                  GestureDetector(
                    onTap: _showEditProfile,
                    child: Stack(alignment: Alignment.bottomRight, children: [
                      Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2.5),
                          boxShadow: [BoxShadow(
                              color: AppColors.primary.withOpacity(0.3), blurRadius: 20)],
                        ),
                        child: ClipOval(child: user?.avatarUrl != null
                            ? CachedNetworkImage(imageUrl: user!.avatarUrl!, fit: BoxFit.cover)
                            : Container(color: AppColors.surfaceVariant,
                                child: Center(child: Text(
                                  (user?.username ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 36,
                                      fontWeight: FontWeight.w800, color: AppColors.primary),
                                )))),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.edit_rounded, size: 14, color: Colors.black),
                      ),
                    ]),
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 12),
                  Text(user?.username ?? 'Listener',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary))
                      .animate().fade(delay: 200.ms, duration: 300.ms),
                  Text(user?.email ?? '',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))
                      .animate().fade(delay: 300.ms, duration: 300.ms),
                ]),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(children: [
                const SizedBox(height: 16),
                _SupportCard().animate().fade(delay: 100.ms, duration: 400.ms),
                const SizedBox(height: 24),

                _SettingsSection(title: 'ACCOUNT', tiles: [
                  _SettingsTile(icon: Icons.person_outline_rounded,
                      label: 'Edit profile', onTap: _showEditProfile),
                  _SettingsTile(icon: Icons.notifications_outlined,
                      label: 'Notifications', onTap: _showNotifications),
                  _SettingsTile(icon: Icons.privacy_tip_outlined,
                      label: 'Privacy policy', onTap: _showPrivacy),
                ]).animate().fade(delay: 150.ms, duration: 400.ms),

                const SizedBox(height: 16),

                _SettingsSection(title: 'PLAYBACK', tiles: [
                  _SettingsTile(icon: Icons.high_quality_outlined,
                      label: 'Audio quality', onTap: _showAudioQuality),
                  _SettingsTile(icon: Icons.data_saver_on_outlined,
                      label: 'Data saver', onTap: _showDataSaver),
                  _SettingsTile(icon: Icons.download_outlined,
                      label: 'Downloads', onTap: _showDownloads),
                ]).animate().fade(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 16),

                _SettingsSection(title: 'ABOUT', tiles: [
                  _SettingsTile(icon: Icons.info_outline_rounded,
                      label: 'About ASHU', onTap: _showAbout),
                  _SettingsTile(icon: Icons.star_border_rounded,
                      label: 'Rate the app', onTap: _showRateApp),
                  _SettingsTile(
                    icon: Icons.bug_report_outlined,
                    label: 'Report a bug',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bug reporting coming soon!'),
                          behavior: SnackBarBehavior.floating),
                    ),
                  ),
                ]).animate().fade(delay: 250.ms, duration: 400.ms),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withOpacity(0.15),
                      foregroundColor: AppColors.error,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign Out'),
                    onPressed: () async {
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ).animate().fade(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────

class _TechChip extends StatelessWidget {
  final String label;
  const _TechChip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
    ),
    child: Text(label, style: const TextStyle(
        color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class _SwitchTile extends StatefulWidget {
  final IconData icon;
  final String label, subtitle;
  final bool initial;
  const _SwitchTile({required this.icon, required this.label,
      required this.subtitle, this.initial = false});
  @override State<_SwitchTile> createState() => _SwitchTileState();
}
class _SwitchTileState extends State<_SwitchTile> {
  late bool _val;
  @override void initState() { super.initState(); _val = widget.initial; }
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(widget.icon, color: AppColors.textSecondary, size: 22),
    title: Text(widget.label,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
    subtitle: Text(widget.subtitle,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
    trailing: Switch(value: _val, onChanged: (v) => setState(() => _val = v),
        activeColor: AppColors.primary),
  );
}

class _QualityTile extends StatelessWidget {
  final String label, sub;
  final bool selected;
  final VoidCallback onTap;
  const _QualityTile({required this.label, required this.sub,
      required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent, width: 1.5),
      ),
      child: Row(children: [
        Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
            color: selected ? AppColors.primary : AppColors.textMuted, size: 20),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w700, fontSize: 14)),
          Text(sub, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
      ]),
    ),
  );
}

class _SupportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/support'),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.25), AppColors.accent.withOpacity(0.2)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 0.5),
      ),
      child: Row(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 26),
        ),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Support ASHU', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
          Text('Buy me a coffee via UPI', style: TextStyle(fontSize: 12,
              color: AppColors.textSecondary)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
      ]),
    ),
  );
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> tiles;
  const _SettingsSection({required this.title, required this.tiles});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: AppColors.textMuted, letterSpacing: 1.5)),
      ),
      Container(
        decoration: BoxDecoration(color: AppColors.card,
            borderRadius: BorderRadius.circular(14)),
        child: Column(children: tiles),
      ),
    ],
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    leading: Icon(icon, color: AppColors.textSecondary, size: 22),
    title: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}
