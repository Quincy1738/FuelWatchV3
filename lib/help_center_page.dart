import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Add url_launcher to pubspec.yaml

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  final List<Map<String, String>> faqs = const [
    {
      'question': 'How to update Tank info?',
      'answer': 'Go to the dashboard and enter the liters and price per liters.'
    },
    {
      'question': 'How to enable dark mode?',
      'answer': 'Navigate to Settings and toggle the Dark Mode switch.'
    },
    {
      'question': 'How to enable or disable notifications?',
      'answer': 'In Settings, tap Notifications and choose to turn them on or off.'
    },
    {
      'question': 'How to reset my password?',
      'answer': 'Go to the login page and tap "Forgot Password" to reset your password.'
    },
    // Add more FAQs as needed
  ];

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@example.com', // Replace with your support email
      queryParameters: {
        'subject': 'App Support Request',
      },
    );
    if (!await launchUrl(emailUri)) {
      // Could not launch email app
      throw 'Could not open the email app.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Frequently Asked Questions',
              style: theme.textTheme.titleLarge,
            ),
          ),
          ...faqs.map((faq) => ExpansionTile(
            title: Text(faq['question']!),
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text(faq['answer']!),
              ),
            ],
          )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.contact_mail_outlined),
            title: const Text('Contact Support'),
            subtitle: const Text('Get in touch with our support team'),
            onTap: () async {
              try {
                await _launchEmail();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not open email app.'),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              '© 2025 FuelWatch',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
