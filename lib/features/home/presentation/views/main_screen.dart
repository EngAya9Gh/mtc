import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/release_car_cubit.dart';
import '../../../../core/common/widgets/app_text.dart';
import '../bloc/emergency_cubit.dart';
import '../../../../core/config/theme/color_scheme.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/locale/locale_cubit.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../data/providers/user_info_provider.dart';
import '../../../../core/services/di/di_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/latest_task_card.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations(Localizations.localeOf(context).languageCode);
    final isArabic = l.isArabic;
    final driverName = UserInfo().loginInfo != null ? 'Driver #${UserInfo().userId}' : 'Driver';

    return MultiBlocListener(
      listeners: [
        BlocListener<EmergencyCubit, EmergencyState>(
          listener: (context, state) {
            if (state is EmergencyLoading) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isArabic ? 'جاري الإرسال...' : 'Sending...')),
              );
            } else if (state is EmergencySuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.green),
              );
            } else if (state is EmergencyFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error), backgroundColor: Colors.red),
              );
            }
          },
        ),
        BlocListener<ReleaseCarCubit, ReleaseCarState>(
          listener: (context, state) {
            if (state is ReleaseCarLoading) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isArabic ? 'جاري إخلاء السيارة...' : 'Releasing car...')),
              );
            } else if (state is ReleaseCarSuccess) {
              UserInfo().logout(getIt<SharedPreferences>());
              context.go(AppRouter.login);
            } else if (state is ReleaseCarFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error), backgroundColor: Colors.red),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5FA),
        body: CustomScrollView(
          slivers: [
          // ─── Sliver App Bar ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 190,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                ),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            actions: [
              _NavAction(
                icon: Icons.emergency_outlined, 
                color: Colors.red.shade300, 
                onTap: () {
                  _showEmergencyConfirmDialog(context, isArabic);
                }
              ),
              _NavAction(icon: Icons.notifications_none_rounded, color: Colors.white, badge: true, onTap: () => context.push('/notifications')),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFF00838F)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: isArabic ? null : -30,
                      left: isArabic ? -30 : null,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 30,
                      right: isArabic ? null : 50,
                      left: isArabic ? 50 : null,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 90, 20, 24),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: const Icon(Icons.person_rounded, size: 32, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppText(
                                  isArabic ? 'مرحباً بعودتك ' : 'Welcome back ',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                  ),
                                ),
                                AppText(
                                  driverName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Language Toggle
                          _LanguageToggleButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Body Content ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Latest Task
                if (UserInfo().loginInfo?.latestTask != null) ...[
                  LatestTaskCard(task: UserInfo().loginInfo!.latestTask!),
                  const SizedBox(height: 28),
                ] else ...[
                  // Optional: Show "No active tasks" or just hide it
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: AppText(
                        l.isArabic ? 'لا توجد مهام نشطة حالياً' : 'No active tasks at the moment',
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Quick Actions Title
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AppText(
                      l.quickActions,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Actions Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.05,
                  children: [
                    _QuickActionCard(
                      title: l.medicalTasks,
                      subtitle: l.medicalTasksSubtitle,
                      icon: Icons.medical_services_rounded,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF00838F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onPressed: () => context.push(AppRouter.taskType),
                    ),
                    _QuickActionCard(
                      title: l.swap,
                      subtitle: l.swapSubtitle,
                      icon: Icons.swap_horiz_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onPressed: () => context.push('/swap_tasks'),
                    ),
                    _QuickActionCard(
                      title: l.pharmaTask,
                      subtitle: '',
                      icon: Icons.medication_liquid_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9E9E9E), Color(0xFF616161)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onPressed: () {}, // Disabled as per plan
                    ),
                    _QuickActionCard(
                      title: l.moneyTask,
                      subtitle: '',
                      icon: Icons.attach_money_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onPressed: () {},
                    ),

                  ],
                ),
                const SizedBox(height: 28),

                // Performance Banner
                _PerformanceBanner(l: l),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
      drawer: _MainDrawer(l: l),
      ),
    );
  }

  void _showEmergencyConfirmDialog(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: AppText(
            isArabic ? 'تأكيد حالة طوارئ' : 'Emergency Confirmation',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: AppText(
            isArabic 
                ? 'هل أنت متأكد من إرسال طلب طوارئ؟' 
                : 'Do you really want to make an emergency request?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: AppText(
                isArabic ? 'إلغاء' : 'Cancel',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.read<EmergencyCubit>().sendEmergencyRequest();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: AppText(
                isArabic ? 'إرسال' : 'Send',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Language Toggle Button ───────────────────────────────────────────────────
class _LanguageToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (ctx, locale) => GestureDetector(
        onTap: () => ctx.read<LocaleCubit>().toggleLanguage(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              AppText(
                locale.languageCode == 'ar' ? 'EN' : 'عر',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── NavAction ───────────────────────────────────────────────────────────────
class _NavAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool badge;
  final VoidCallback onTap;

  const _NavAction({required this.icon, required this.color, this.badge = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          if (badge)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
        ],
      ),
      onPressed: onTap,
    );
  }
}

// ─── Quick Action Card ────────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onPressed;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                AppText(
                  subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Performance Banner ───────────────────────────────────────────────────────
class _PerformanceBanner extends StatelessWidget {
  final AppLocalizations l;
  const _PerformanceBanner({required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF00838F)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  l.performanceGreat,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 3),
                AppText(
                  l.completedTasks,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppText(
              l.details,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Main Drawer ──────────────────────────────────────────────────────────────
class _MainDrawer extends StatelessWidget {
  final AppLocalizations l;
  const _MainDrawer({required this.l});

  @override
  Widget build(BuildContext context) {
    final isArabic = l.isArabic;
    final driverName = UserInfo().loginInfo != null ? 'Driver #${UserInfo().userId}' : 'Driver';
    return Drawer(
      backgroundColor: const Color(0xFFF2F5FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 36),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFF00838F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.green.shade400,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppText(
                  driverName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                AppText(
                  l.isArabic ? 'سائق نشط' : 'Active Driver',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _DrawerItem(icon: Icons.person_outline_rounded, title: l.profile, onTap: () => context.push('/profile')),
                _DrawerItem(icon: Icons.calendar_today_outlined, title: l.mySchedule, onTap: () => context.push('/schedule')),
                _DrawerItem(icon: Icons.assignment_outlined, title: isArabic ? 'الشروط والأحكام' : 'Terms & Conditions', onTap: () => context.push('/terms')),
                _DrawerItem(icon: Icons.directions_car_rounded, title: isArabic ? 'استلام السيارة' : 'Receive Car', onTap: () => context.push('/car_inspection')),
                _DrawerItem(
                  icon: Icons.time_to_leave_rounded, 
                  title: isArabic ? 'إخلاء السيارة' : 'Release Car', 
                  onTap: () {
                    _showReleaseCarConfirmDialog(context, isArabic);
                  },
                ),
                _DrawerItem(icon: Icons.privacy_tip_outlined, title: l.privacyPolicy, onTap: () => context.push('/privacy_policy')),
                _DrawerItem(
                  icon: Icons.share_rounded,
                  title: l.shareApp,
                  onTap: () {
                    Share.share(
                      isArabic 
                        ? 'جرّب تطبيق التوصيل: https://play.google.com/store/apps/details?id=com.blazma.logistics' 
                        : 'Try the delivery app: https://play.google.com/store/apps/details?id=com.blazma.logistics',
                    );
                  },
                ),
                _DrawerItem(icon: Icons.qr_code_scanner_rounded, title: l.scannerSettings, onTap: () => context.push('/scanner_settings')),
                _DrawerItem(
                  icon: Icons.bug_report_rounded,
                  title: isArabic ? 'سجل الأخطاء' : 'Crash Log',
                  onTap: () => context.push('/crash_log'),
                  color: Colors.orange,
                ),


                const SizedBox(height: 8),
                // Language toggle in drawer
                BlocBuilder<LocaleCubit, Locale>(
                  builder: (ctx, locale) => _DrawerItem(
                    icon: Icons.language_rounded,
                    title: l.language,
                    onTap: () => ctx.read<LocaleCubit>().toggleLanguage(),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AppText(
                        locale.languageCode == 'ar' ? 'EN' : 'عر',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(),
                ),
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  title: l.logout,
                  onTap: () {
                    UserInfo().logout(getIt<SharedPreferences>());
                    context.go(AppRouter.login);
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showReleaseCarConfirmDialog(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: AppText(
            isArabic ? 'إخلاء السيارة' : 'Release Car',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          content: AppText(
            isArabic 
                ? 'هل أنت متأكد من تسليم/إخلاء السيارة الخاصة بك لليوم؟ سيؤدي ذلك إلى تسجيل خروجك من التطبيق.' 
                : 'Are you sure you want to release your car for today? This will log you out.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: AppText(
                isArabic ? 'إلغاء' : 'Cancel',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.read<ReleaseCarCubit>().releaseCar();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: AppText(
                isArabic ? 'تأكيد الإخلاء' : 'Confirm Release',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;
  final Widget? trailing;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: c, size: 20),
        ),
        title: AppText(title, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: trailing ?? (color != null ? const Icon(Icons.chevron_right_rounded, color: Colors.red, size: 20) : const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20)),
        onTap: onTap,
      ),
    );
  }
}
