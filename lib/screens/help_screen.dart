import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Help Center', style: TextStyle(color: kInk)),
        iconTheme: const IconThemeData(color: kInk),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kPaper,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kLine),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kSoftBronze,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.help_outline, color: kBronze, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How can we help?',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Find answers to common questions and guides below.',
                              style: TextStyle(fontSize: 12.5, color: kMuted, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _HelpSection(
              title: 'Getting Started',
              items: [
                _HelpItem(
                  question: 'What is Mizan?',
                  answer: 'Mizan is a private journal for tracking your acts of goodness, charity, dhikr, and prayers. It helps you build a gentle rhythm of giving without comparison or public feeds. Your data stays private on your device.',
                ),
                _HelpItem(
                  question: 'How do I create an account?',
                  answer: 'Tap "Create account" on the welcome screen. Enter your name, email, and a strong password (at least 8 characters with a letter and a number). We\'ll send a verification email to confirm your address.',
                ),
                _HelpItem(
                  question: 'How do I verify my email?',
                  answer: 'After signing up, check your inbox for a verification email from Mizan. Tap the link in the email to verify your address. If you don\'t see it, check your spam folder or tap "Resend verification email" on the verification screen.',
                ),
                _HelpItem(
                  question: 'How do I add an act of sadaqah?',
                  answer: 'Tap the + button at the bottom of the home screen. Choose the type of act, add an optional note, and tap "Add to my jar". Your jar fills up as you add more acts.',
                ),
                _HelpItem(
                  question: 'What is the sadaqah jar?',
                  answer: 'The jar is a visual representation of your monthly acts of goodness. Each act adds a "star" to your jar. When the jar is full, you have reached your intention for the month.',
                ),
                _HelpItem(
                  question: 'What are the different act types?',
                  answer: 'Mizan tracks several types of good deeds: Money (charity, donations), Food (feeding others), Kindness (helping people), Dhikr (remembrance of Allah), Prayer (du\'a and salah), Remove harm (clearing obstacles), Smile (spreading joy), and Time (volunteering your time).',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _HelpSection(
              title: 'Family & Sharing',
              items: [
                _HelpItem(
                  question: 'How do I create a family jar?',
                  answer: 'Go to the Family tab and tap "Create a jar". Give it a name and share the invite code with your family members so they can join.',
                ),
                _HelpItem(
                  question: 'How do I join a family jar?',
                  answer: 'Tap "Join with code" in the Family tab and enter the invite code shared by the family owner. You\'ll be added to the family and can start participating in shared goals and prayers.',
                ),
                _HelpItem(
                  question: 'Can I set goals for my family?',
                  answer: 'Yes! Inside a family jar, tap on the goals section to create shared intentions. Your family can work together toward these goals and track progress.',
                ),
                _HelpItem(
                  question: 'How do prayer requests work?',
                  answer: 'Prayer requests let your family support each other through du\'a. You can create a prayer request, and family members can respond with Ameen, May Allah grant ease, or May Allah accept. You can also mark your own prayer as answered.',
                ),
                _HelpItem(
                  question: 'How do reflections work?',
                  answer: 'Reflections are a way to share your spiritual thoughts and experiences with your family. You can post a reflection and family members can encourage you with messages like Ameen, Barakallahu feek, or May Allah increase.',
                ),
                _HelpItem(
                  question: 'Can I leave a family jar?',
                  answer: 'Yes. Go to the family jar details and tap "Leave family". You can rejoin anytime with the invite code.',
                ),
                _HelpItem(
                  question: 'How do I manage family members?',
                  answer: 'Family owners and admins can manage members by changing roles, removing members, or creating new invitations. Go to the family jar details and tap on the members section.',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _HelpSection(
              title: 'Books & Reading',
              items: [
                _HelpItem(
                  question: 'How do I read a book?',
                  answer: 'Go to the Journey tab and browse the available books. Tap on any book to see its chapters and start reading. Your reading progress is automatically saved.',
                ),
                _HelpItem(
                  question: 'Can I add my own books?',
                  answer: 'Admins can add new books through the Admin Portal. If you have a book suggestion, please reach out to your family admin or contact support.',
                ),
                _HelpItem(
                  question: 'How do I track my reading progress?',
                  answer: 'Mizan automatically tracks which chapters you\'ve read. You can view your last reading progress in the Journey section.',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _HelpSection(
              title: 'Charities & Giving',
              items: [
                _HelpItem(
                  question: 'How do I find verified charities?',
                  answer: 'Go to the Charities section in the app. All listed charities are verified and active. You can browse by category or search for specific causes.',
                ),
                _HelpItem(
                  question: 'How do I donate to a charity?',
                  answer: 'Tap on a charity to view its details and website. Use the website link to make a donation directly to the charity.',
                ),
                _HelpItem(
                  question: 'Are the charities verified?',
                  answer: 'Yes. All charities in Mizan are verified by our team to ensure they are legitimate and active organizations.',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _HelpSection(
              title: 'Account & Privacy',
              items: [
                _HelpItem(
                  question: 'Is my data private?',
                  answer: 'Yes. Mizan is designed as a private space. Your reflections and personal acts are not shared publicly. Family sharing is opt-in and controlled by you. All data is stored locally on your device.',
                ),
                _HelpItem(
                  question: 'How do I change my password?',
                  answer: 'Go to Settings > Privacy > Change password. Enter your current password and choose a new one.',
                ),
                _HelpItem(
                  question: 'How do I change my email?',
                  answer: 'Go to Settings > Edit profile. Update your email address. You\'ll need to verify the new email before it takes effect.',
                ),
                _HelpItem(
                  question: 'How do I delete my account?',
                  answer: 'Go to Settings > Privacy and tap "Delete account". This will permanently remove all your data from this device.',
                ),
                _HelpItem(
                  question: 'How do I enable notifications?',
                  answer: 'Go to Settings > Notifications and toggle on Friday reminders. You\'ll also need to enable notification permissions on your device.',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _HelpSection(
              title: 'Evidence & Sources',
              items: [
                _HelpItem(
                  question: 'What is the Evidence section?',
                  answer: 'The Evidence section provides verified sources and references for acts of sadaqah. Each act is supported by authentic Islamic sources with Arabic text, English translation, and scholarly grading.',
                ),
                _HelpItem(
                  question: 'How do I search for evidence?',
                  answer: 'Use the search bar in the Journey tab to find evidence by keyword, source type, or reference.',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _HelpSection(
              title: 'Troubleshooting',
              items: [
                _HelpItem(
                  question: 'I forgot my password',
                  answer: 'Tap "Forgot password" on the sign-in screen. Enter your email and we\'ll send you a reset link.',
                ),
                _HelpItem(
                  question: 'I didn\'t receive the verification email',
                  answer: 'Check your spam or junk folder. You can also tap "Resend verification email" on the verification screen. If you still don\'t receive it, make sure your email address is correct.',
                ),
                _HelpItem(
                  question: 'The app is running slowly',
                  answer: 'Try closing other apps and restarting Mizan. Make sure your device has enough storage space. If the issue persists, please contact support.',
                ),
                _HelpItem(
                  question: 'My data is not syncing',
                  answer: 'Mizan stores data locally on your device. If you\'re using family features, make sure you have a stable internet connection. Pull down to refresh the screen.',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _HelpSection(
              title: 'Still need help?',
              items: [
                _HelpItem(
                  question: 'Contact us',
                  answer: 'If you have any questions, feedback, or need assistance, please reach out to us. We\'d love to hear from you.',
                  onTap: () async {
                    final uri = Uri(scheme: 'mailto', queryParameters: {
                      'subject': 'Mizan Help Request',
                      'body': 'Please describe your issue:',
                    });
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.items});

  final String title;
  final List<_HelpItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: kBronze,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: kPaper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kLine),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  if (index > 0)
                    const Divider(height: 1, color: kLine, indent: 16, endIndent: 16),
                  _buildItem(item),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(_HelpItem item) {
    return StatefulBuilder(
      builder: (context, setState) {
        var expanded = false;
        return Column(
          children: [
            InkWell(
              onTap: item.onTap ?? () => setState(() => expanded = !expanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.question,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kInk),
                      ),
                    ),
                    Icon(
                      expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: kMutedLight,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  item.answer,
                  style: const TextStyle(fontSize: 13, color: kMuted, height: 1.5),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HelpItem {
  const _HelpItem({required this.question, required this.answer, this.onTap});

  final String question;
  final String answer;
  final VoidCallback? onTap;
}