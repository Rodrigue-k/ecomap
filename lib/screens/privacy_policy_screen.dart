import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Politique de confidentialité')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Politique de confidentialité d\'EcoMap',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '''
Dernière mise à jour : 13 août 2025

EcoMap s'engage à protéger votre vie privée. Cette politique explique comment nous collectons, utilisons et protégeons vos données personnelles.

### 1. Données collectées
Nous collectons les données suivantes :
- **Localisation** : Utilisée pour localiser les poubelles publiques et ajouter de nouvelles poubelles via l'application.
- **Données de l'appareil** : Identifiant unique de l'appareil pour les suggestions envoyées.
- **Suggestions des utilisateurs** : Texte soumis via la section "Suggestions" pour améliorer l'application.

### 2. Utilisation des données
Les données collectées sont utilisées pour :
- Afficher les poubelles sur la carte interactive.
- Améliorer l'application grâce à vos suggestions.
- Analyser l'utilisation de l'application de manière anonyme.

### 3. Partage des données
Vos données ne sont pas vendues ni partagées avec des tiers, sauf :
- Avec votre consentement explicite.
- Pour se conformer aux obligations légales.

### 4. Sécurité
Nous utilisons Firebase pour stocker les données de manière sécurisée avec des mesures comme le chiffrement.

### 5. Vos droits
Vous pouvez demander l'accès, la correction ou la suppression de vos données en nous contactant à contact@ecomap.tg.

### 6. Contact
Pour toute question, contactez-nous à :
- Email : contact@ecomap.tg
- Site web : https://ecomap.tg

EcoMap est une initiative pour un environnement plus propre. Merci de votre confiance !
              ''',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
