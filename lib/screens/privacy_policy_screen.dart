import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DDC4000 Browser Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2c3e50),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Effective Date: January 6, 2025',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24),
            
            _SectionTitle('What We Collect'),
            _SectionContent(
              '• Connection settings (IP addresses, protocols)\n'
              '• Saved presets for quick access\n'
              '• App preferences and settings\n'
              '• Screenshots (saved to your device gallery)'
            ),
            
            _SectionTitle('What We DON\'T Collect'),
            _SectionContent(
              '• No personal information\n'
              '• No usage tracking or analytics\n'
              '• No device identifiers\n'
              '• No location data\n'
              '• No access to contacts or personal files'
            ),
            
            _SectionTitle('Data Storage'),
            _SectionContent(
              'All data is stored locally on your device only. We do not store any information on remote servers or in the cloud. Your data never leaves your device except for direct connections to your DDC4000 devices.'
            ),
            
            _SectionTitle('Network Connections'),
            _SectionContent(
              'The app only connects directly to DDC4000 devices on your local network using the IP addresses you configure. We do not connect to any analytics, advertising, or data collection services.'
            ),
            
            _SectionTitle('Your Control'),
            _SectionContent(
              'You have complete control over your data:\n\n'
              '• Delete presets anytime in the app\n'
              '• Uninstall the app to remove all data\n'
              '• Manage screenshots through your device gallery\n'
              '• Clear app data through Android settings'
            ),
            
            _SectionTitle('Permissions'),
            _SectionContent(
              'The app requests permissions only for core functionality:\n\n'
              '• Internet: Connect to DDC4000 devices\n'
              '• Storage: Save screenshots to gallery\n'
              '• Network State: Check connectivity status'
            ),
            
            _SectionTitle('Professional Use'),
            _SectionContent(
              'This app is designed for professional building automation use and is not intended for children under 13.'
            ),
            
            SizedBox(height: 32),
            
            Center(
              child: Text(
                'Questions? Contact support through the app store.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF34495e),
        ),
      ),
    );
  }
}

class _SectionContent extends StatelessWidget {
  final String content;
  
  const _SectionContent(this.content);

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: Color(0xFF5a6c7d),
      ),
    );
  }
}