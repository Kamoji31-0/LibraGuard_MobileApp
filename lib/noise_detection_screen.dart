import 'package:flutter/material.dart';
import 'book_list_screen.dart';
import 'pc_reservation_rules_screen.dart';
import 'profile_screen.dart';
import 'widgets/app_bottom_nav.dart';

class NoiseDetectionScreen extends StatelessWidget {
  const NoiseDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.secondary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);
    final cardColor = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget ruleItem(String number, String text) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      );
    }

    Widget sectionTitle(IconData icon, String title, {Color? iconColor}) {
      return Row(
        children: [
          Icon(icon, color: iconColor ?? textColor, size: 24),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    Widget levelCard({
      required String emoji,
      required String label,
      required String description,
      required Color color,
    }) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: textColor.withOpacity(0.75),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Noise Detection',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ECHOGUARD SOUND MONITORING SYSTEM',
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.sensors,
                      color: textColor.withOpacity(0.8), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Reading Area & Computer Lab',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── How It Works Card ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle(Icons.hearing_outlined, 'How It Works'),
                    const SizedBox(height: 28),
                    ruleItem(
                      '01.',
                      'The library has EchoGuard sound sensors placed in the Reading Area and the Computer Lab to measure how loud it gets.',
                    ),
                    const SizedBox(height: 16),
                    ruleItem(
                      '02.',
                      'These sensors run 24/7 and help library staff keep the environment quiet and comfortable for everyone studying inside.',
                    ),
                    const SizedBox(height: 16),
                    ruleItem(
                      '03.',
                      'When a sensor picks up too much noise, it records the event and reports it automatically — no staff needed to be physically present.',
                    ),
                    const SizedBox(height: 16),
                    ruleItem(
                      '04.',
                      'The system then decides the noise level and responds right away with a beep or alarm depending on how serious it is.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Warning Levels Card ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle(Icons.warning_amber_rounded, 'Noise Levels',
                        iconColor: isDark ? Colors.white : textColor),
                    const SizedBox(height: 8),
                    Text(
                      'There are three possible noise levels the system reports:',
                      style: TextStyle(
                        color: textColor.withOpacity(0.65),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quiet
                    levelCard(
                      emoji: '🟢',
                      label: 'Quiet',
                      description:
                          'Everything is fine. The area is calm and within normal noise levels. No action is needed.',
                      color: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 12),

                    // Warning
                    levelCard(
                      emoji: '🟡',
                      label: 'Warning',
                      description:
                          'It is getting too loud. A short beep will sound to remind everyone to keep it down. This is automatically recorded in the system.',
                      color: const Color(0xFFF57F17),
                    ),
                    const SizedBox(height: 12),

                    // Violation
                    levelCard(
                      emoji: '🔴',
                      label: 'Violation',
                      description:
                          'The noise stayed loud even after the Warning beep. A longer alarm sounds and the incident is logged. Getting too many Violations may result in suspension of your library access.',
                      color: const Color(0xFFC62828),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Reminders Card ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle(
                        Icons.tips_and_updates_outlined, 'Tips to Stay Quiet'),
                    const SizedBox(height: 20),
                    ruleItem(
                      '01.',
                      'Use a whisper if you need to talk to someone nearby.',
                    ),
                    const SizedBox(height: 14),
                    ruleItem(
                      '02.',
                      'Set your phone to silent or vibrate before entering the library.',
                    ),
                    const SizedBox(height: 14),
                    ruleItem(
                      '03.',
                      'Use headphones when watching a video, listening to music, or joining an online class.',
                    ),
                    const SizedBox(height: 14),
                    ruleItem(
                      '04.',
                      'If a beep sounds in your area, stop and check if you or your group is being too loud.',
                    ),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Got it',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: -1,
        onItemTapped: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (r) => r.isFirst);
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BookListScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const PcReservationRulesScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
      ),
    );
  }
}
