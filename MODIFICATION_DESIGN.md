# Document de Conception de la Modification

## 1. Vue d'ensemble

Ce document décrit la modification de l'affichage des dépotoirs sur la carte Google Maps. L'objectif est de remplacer les marqueurs et cercles actuels par une visualisation en heatmap pour mieux représenter la densité des dépotoirs. De plus, l'interaction avec la carte sera améliorée : un appui sur une zone de la carte affichera les détails du dépotoir le plus proche dans une fenêtre modale animée (bottom sheet) avec un design professionnel.

## 2. Analyse Détaillée de l'Objectif et du Problème

### Problème Actuel
Actuellement, l'application utilise des marqueurs et des cercles individuels pour représenter chaque dépotoir sur la carte. Bien que fonctionnel, cette approche peut devenir encombrante et moins lisible lorsque de nombreux dépotoirs sont concentrés dans une petite zone. La visualisation de la densité des dépotoirs n'est pas optimale. Les détails des dépotoirs sont affichés dans une `Dialog` standard, qui manque d'animation et de flexibilité en termes de design.

### Objectif
1.  **Améliorer la visualisation de la densité** : Utiliser une heatmap pour montrer les zones où les dépotoirs sont les plus concentrés, offrant ainsi une meilleure compréhension de la situation globale.
2.  **Améliorer l'interaction utilisateur** : Permettre aux utilisateurs d'appuyer sur n'importe quelle zone de la carte pour obtenir des informations sur le dépotoir le plus proche.
3.  **Moderniser l'affichage des détails** : Remplacer la `Dialog` par une `showModalBottomSheet` animée et esthétique, présentant les informations du dépotoir de manière claire et professionnelle.

## 3. Alternatives Considérées

### 3.1 Implémentation de la Heatmap

*   **Option A : Utiliser les cercles existants avec des couleurs/tailles dynamiques**
    *   **Avantages** : Pas de nouvelle dépendance, réutilise le code existant.
    *   **Inconvénients** : Ne produit pas une véritable heatmap avec un dégradé de couleurs fluide et une interpolation. La performance pourrait être un problème avec un très grand nombre de cercles.
*   **Option B : Utiliser le support Heatmap intégré de `google_maps_flutter`**
    *   **Avantages** : Solution officielle, optimisée pour la performance, offre une véritable visualisation en heatmap.
    *   **Inconvénients** : Nécessite d'adapter les données `WasteDump` au format `WeightedLatLng` ou similaire.
*   **Option C : Utiliser un package tiers (`google_maps_flutter_heatmap`)**
    *   **Avantages** : Pourrait offrir des fonctionnalités supplémentaires.
    *   **Inconvénients** : Le package est en "Developer Preview", n'est pas stable et ne supporte pas la null safety.

    **Décision** : L'**Option B** est la meilleure approche. Le package officiel `google_maps_flutter` supporte désormais les heatmaps, offrant la meilleure performance et intégration.

### 3.2 Affichage des Détails du Dépotoir

*   **Option A : Conserver `showDialog`**
    *   **Avantages** : Simple à implémenter, déjà en place.
    *   **Inconvénients** : Ne répond pas au besoin d'animation "professionnelle" et de design moderne.
*   **Option B : Utiliser `showModalBottomSheet`**
    *   **Avantages** : Offre une animation fluide depuis le bas de l'écran, est très personnalisable en termes de contenu et de design (coins arrondis, hauteur variable via `DraggableScrollableSheet`).
    *   **Inconvénients** : Nécessite de recréer le contenu de la `Dialog` dans un nouveau widget.
*   **Option C : Utiliser un `Overlay` personnalisé**
    *   **Avantages** : Contrôle total sur l'animation et le positionnement.
    *   **Inconvénients** : Très complexe à implémenter et à maintenir.

    **Décision** : L'**Option B** est la meilleure option pour répondre aux exigences de design et d'animation. L'utilisation de `DraggableScrollableSheet` au sein de `showModalBottomSheet` permettra une expérience utilisateur riche.

## 4. Conception Détaillée de la Modification

### 4.1 Implémentation de la Heatmap

1.  **Mise à jour de `pubspec.yaml`** : S'assurer que `google_maps_flutter` est à une version qui supporte les heatmaps (généralement la dernière version stable).
2.  **Conversion des données** : Dans `_MapScreenState`, la liste des `WasteDump` récupérée via `wasteDumpsProvider` sera convertie en une liste de `WeightedLatLng` (ou `LatLng` si le poids n'est pas nécessaire ou est géré par la configuration de la heatmap). La `surfaceArea` du `WasteDump` pourra être utilisée comme poids pour la heatmap, rendant les dépotoirs plus grands plus "chauds".
3.  **Intégration dans `GoogleMap`** : Le widget `GoogleMap` sera mis à jour pour inclure un ensemble de `Heatmap`s. Les `circles` et `markers` actuels pour les dépotoirs seront supprimés.

    ```dart
    // Exemple de structure pour la heatmap
    gmaps.GoogleMap(
      // ... autres propriétés
      heatmaps: wasteDumpsAsync.when(
        data: (dumps) {
          return {
            gmaps.Heatmap(
              heatmapId: gmaps.HeatmapId('waste_dumps_heatmap'),
              points: dumps.map((dump) => gmaps.WeightedLatLng(
                latLng: gmaps.LatLng(dump.latitude, dump.longitude),
                intensity: dump.surfaceArea, // Utiliser la surface comme intensité
              )).toList(),
              radius: 50, // Rayon de la heatmap, à ajuster
              opacity: 0.7, // Opacité, à ajuster
              // gradient: gmaps.HeatmapGradient(...) // Personnaliser le dégradé de couleurs
            ),
          };
        },
        loading: () => {},
        error: (_, __) => {},
      ),
      // ...
    );
    ```

### 4.2 Gestion de l'Interaction (Tap sur la Carte)

1.  **`onTap` de `GoogleMap`** : Le callback `onTap` du widget `GoogleMap` sera utilisé pour détecter les appuis de l'utilisateur. Il fournira les coordonnées `gmaps.LatLng` du point de contact.
2.  **Recherche du dépotoir le plus proche** :
    *   Une fonction utilitaire sera créée pour calculer la distance entre deux points `LatLng`. `Geolocator.distanceBetween` sera utilisée pour une précision géographique.
    *   Cette fonction parcourra la liste des `WasteDump` (obtenue via `wasteDumpsProvider`) et identifiera le dépotoir dont les coordonnées sont les plus proches du point de contact.
    *   Un seuil de distance pourra être défini pour éviter d'afficher des détails si l'appui est trop éloigné de tout dépotoir.
3.  **Affichage des détails** : Une fois le dépotoir le plus proche identifié, la fonction `_showWasteDumpDetails` sera appelée avec ce dépotoir.

### 4.3 Affichage des Détails du Dépotoir (Bottom Sheet Animée)

1.  **Remplacement de `_showWasteDumpDetails`** : La méthode `_showWasteDumpDetails` sera modifiée pour utiliser `showModalBottomSheet`.
2.  **Widget `WasteDumpDetailsBottomSheet`** : Un nouveau widget `WasteDumpDetailsBottomSheet` sera créé pour encapsuler le contenu des détails du dépotoir. Ce widget recevra un objet `WasteDump` en paramètre.
3.  **Design du Bottom Sheet** :
    *   Utilisation de `DraggableScrollableSheet` pour permettre à l'utilisateur de redimensionner et de faire glisser la feuille.
    *   Coins arrondis en haut.
    *   Padding et marges appropriés.
    *   Affichage conditionnel de l'image (`photoUrl`) avec un `Image.network` et un `errorBuilder`.
    *   Utilisation de `Theme.of(context).textTheme` pour une typographie cohérente.
    *   Présentation claire des informations : `surfaceArea`, `timestamp`, `latitude`, `longitude`, `description`, `tags`.
    *   Un bouton "Fermer" ou une icône pour masquer la feuille.

#### Diagramme de Flux de Données et d'Interaction

```mermaid
graph TD
    A[map_screen.dart] --> B{ref.watch(wasteDumpsProvider)};
    B -- Liste de WasteDump --> C[GoogleMap Widget];
    C -- Conversion en WeightedLatLng --> D[Heatmap Layer];
    C -- onTap(LatLng tapCoords) --> E[Recherche du WasteDump le plus proche];
    E -- WasteDump le plus proche --> F[Appel _showWasteDumpDetails(WasteDump)];
    F --> G[showModalBottomSheet];
    G --> H[WasteDumpDetailsBottomSheet Widget];
    H -- Affiche les détails --> I[Interface Utilisateur];
```

#### Diagramme de la Structure du Bottom Sheet

```mermaid
graph TD
    A[showModalBottomSheet] --> B[DraggableScrollableSheet];
    B --> C[Container (avec coins arrondis)];
    C --> D[Column (Contenu)];
    D --> E[Image.network (photoUrl)];
    D --> F[Padding (Détails du dépotoir)];
    F --> G[Text (Surface, Date, Position, Description, Tags)];
    D --> H[Bouton Fermer];
```

## 5. Résumé de la Conception

La modification consistera à intégrer la fonctionnalité de heatmap native de `google_maps_flutter` pour une visualisation améliorée de la densité des dépotoirs. L'interaction sera gérée par un `onTap` sur la carte qui identifiera le dépotoir le plus proche. Les détails de ce dépotoir seront présentés dans un `showModalBottomSheet` stylisé et animé, utilisant `DraggableScrollableSheet` pour une meilleure expérience utilisateur.

## 6. Références de Recherche

*   [Google Maps Flutter Heatmap Documentation](https://pub.dev/packages/google_maps_flutter) (La documentation officielle du package `google_maps_flutter` sera consultée pour les détails spécifiques de l'API Heatmap).
*   [Flutter showModalBottomSheet Documentation](https://api.flutter.dev/flutter/material/showModalBottomSheet.html)
*   [Flutter DraggableScrollableSheet Documentation](https://api.flutter.dev/flutter/widgets/DraggableScrollableSheet-class.html)
*   [Geolocator distanceBetween Documentation](https://pub.dev/documentation/geolocator/latest/geolocator/Geolocator/distanceBetween.html)
