import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/snack_bar_manager.dart';
import '../services/firebase_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carte EcoMap')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildStatsCard(),
            //const SizedBox(height: 30),
            //_buildSettingsSection(),
            const SizedBox(height: 30),
            _buildSuggestionSection(context),
            const SizedBox(height: 30),
            _buildAppInfoSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/images/grandmother.png'),
          ),
          const SizedBox(height: 15),
          const Text(
            'Contributeur EcoMap',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 5),
          StreamBuilder<Map<String, dynamic>>(
            stream: FirebaseService.getUserStats(),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? {};
              final lastUpdated = stats['lastUpdated'] as Timestamp?;
              String memberSince = 'Nouveau contributeur';

              if (lastUpdated != null) {
                memberSince =
                    'Membre depuis ${DateFormat('MMM yyyy').format(lastUpdated.toDate())}';
              }

              return Text(
                memberSince,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              );
            },
          ),
          const SizedBox(height: 20),
          /*Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton('assets/icons/twitter.svg'),
              const SizedBox(width: 15),
              _buildSocialButton('assets/icons/facebook.svg'),
              const SizedBox(width: 15),
              _buildSocialButton('assets/icons/instagram.svg'),
            ],
          ),*/
        ],
      ),
    );
  }

  Widget _buildSocialButton(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: SvgPicture.asset(
        assetPath,
        height: 20,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildStatsCard() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: FirebaseService.getUserStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final addedBins = stats['addedBins'] ?? 0;
        final deletedBins = stats['deletedBins'] ?? 0;
        final totalContributions = addedBins + deletedBins;

        // Calculer le nombre de badges (exemple simple)
        int badges = 0;
        if (addedBins >= 10) badges++;
        if (addedBins >= 50) badges++;
        if (totalContributions >= 100) badges++;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(addedBins.toString(), 'Ajoutées'),
                  _buildStatItem(
                    totalContributions.toString(),
                    'Contributions',
                  ),
                  _buildStatItem(badges.toString(), 'Badges'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  /*Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Préférences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildSettingTile(
            icon: Icons.notifications,
            title: 'Notifications',
            trailing: Switch(value: true, onChanged: (val) {}),
          ),
          _buildSettingTile(
            icon: Icons.dark_mode,
            title: 'Mode sombre',
            trailing: Switch(value: false, onChanged: (val) {}),
          ),
          _buildSettingTile(
            icon: Icons.language,
            title: 'Langue',
            trailing: const Text('Français'),
          ),
        ],
      ),
    );
  }*/

  Widget _buildSuggestionSection(BuildContext context) {
    final TextEditingController suggestionController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggestions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: suggestionController,
            decoration: InputDecoration(
              hintText: 'Entrez votre suggestion pour améliorer EcoMap...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.textSecondary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () async {
                if (suggestionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez entrer une suggestion valide.'),
                    ),
                  );
                  return;
                }

                try {
                  // Récupérer l'ID du device (optionnel)
                  final deviceInfo = DeviceInfoPlugin();
                  String? deviceId;
                  try {
                    final androidInfo = await deviceInfo.androidInfo;
                    deviceId = androidInfo.id; // Ou autre propriété unique
                  } catch (e) {
                    deviceId = 'unknown';
                  }

                  // Récupérer la version de l'app
                  final packageInfo = await PackageInfo.fromPlatform();
                  final appVersion = packageInfo.version;

                  // Envoyer la suggestion à Firestore
                  await FirebaseFirestore.instance
                      .collection('suggestions')
                      .add({
                        'text': suggestionController.text.trim(),
                        'timestamp': DateTime.now().toIso8601String(),
                        'deviceId': deviceId,
                        'appVersion': appVersion,
                      });

                  suggestionController.clear();
                  SnackBarManager.showSuccessSnackBar(
                    'Suggestion envoyée avec succès !',
                  );
                } catch (e) {
                  SnackBarManager.showErrorSnackBar(
                    'Erreur lors de l\'envoi de la suggestion.',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Envoyer'),
            ),
          ),
        ],
      ),
    );
  }

  /*Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title),
      trailing: trailing,
      onTap: () {},
    );
  }*/

  Widget _buildAppInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'À propos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              String version = 'Chargement...';
              if (snapshot.hasData) {
                version = snapshot.data!.version;
              } else if (snapshot.hasError) {
                version = 'Erreur';
              }
              return _buildInfoTile(
                context: context,
                icon: Icons.info,
                title: 'Version',
                subtitle: version,
                onTap: () {},
              );
            },
          ),
          /*_buildInfoTile(
            icon: Icons.star,
            title: 'Notez l\'appli',
            subtitle: 'Donnez-nous votre avis',
          ),
          _buildInfoTile(
            icon: Icons.share,
            title: 'Partager',
            subtitle: 'Recommander à un ami',
          ),*/
          _buildInfoTile(
            context: context,
            icon: Icons.privacy_tip,
            title: 'Politique de confidentialité',
            subtitle: 'Lire nos engagements',
            onTap: () => context.go(AppRouter.privacyPolicy),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap, // Utilisez le callback
    );
  }
}
