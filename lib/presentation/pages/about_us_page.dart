import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/service/remote_config_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  static const _orgName = 'Nexio Technologies';

  static const _description =
      'We provide the digital backbone for modern organizations. NexioTech Cloud specializes in optimizing your workflow through tailored cloud solutions and forward-thinking IT services. Our mission is to bridge the gap between advanced technology and daily efficiency, creating a seamless digital environment where your business can thrive.';

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open the link')));
    }
  }

  Widget _headerCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _orgName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/logo-light-full.png',
                    height: 72,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => Image.asset(
                      'assets/logo-light-full.png',
                      height: 72,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) =>
                          Icon(Icons.business, size: 56, color: cs.primary),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            Text(
              _description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _linkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.t('settings_about_us_title'))),
      body: SafeArea(
        child: Padding(
          padding: screenPadding,
          child: FutureBuilder<AppRemoteConfig>(
            future: RemoteConfigService.instance.getConfig(),
            builder: (context, snapshot) {
              final cfg = snapshot.data ?? AppRemoteConfig.defaults;

              return ListView(
                children: [
                  _headerCard(context),
                  const SizedBox(height: 12),
                  _sectionCard(
                    context,
                    title: 'Links',
                    children: [
                      _linkTile(
                        context,
                        icon: Icons.language,
                        title: 'Website',
                        subtitle: cfg.orgWebsiteLink,
                        onTap: () =>
                            _launchUri(context, Uri.parse(cfg.orgWebsiteLink)),
                      ),
                      _linkTile(
                        context,
                        icon: Icons.help_outline,
                        title: 'Help',
                        subtitle: cfg.orgHelpMail,
                        onTap: () => _launchUri(
                          context,
                          Uri(scheme: 'mailto', path: cfg.orgHelpMail),
                        ),
                      ),
                      _linkTile(
                        context,
                        icon: Icons.connect_without_contact,
                        title: 'Connect',
                        subtitle: cfg.orgConnectMail,
                        onTap: () => _launchUri(
                          context,
                          Uri(scheme: 'mailto', path: cfg.orgConnectMail),
                        ),
                      ),
                      _linkTile(
                        context,
                        icon: Icons.call,
                        title: 'Call',
                        subtitle: cfg.orgContactNumber,
                        onTap: () => _launchUri(
                          context,
                          Uri(scheme: 'tel', path: cfg.orgContactNumber),
                        ),
                      ),
                      _linkTile(
                        context,
                        icon: Icons.code,
                        title: 'GitHub Organization',
                        subtitle: cfg.orgGithubLink,
                        onTap: () =>
                            _launchUri(context, Uri.parse(cfg.orgGithubLink)),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
