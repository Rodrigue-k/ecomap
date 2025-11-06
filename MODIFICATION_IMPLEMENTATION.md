# Plan d'Implémentation de la Modification

Ce document détaille les étapes pour implémenter la nouvelle fonctionnalité de heatmap et de bottom sheet pour les détails des dépotoirs.

## Journal

*   **Phase 1**: Tests initiaux réussis. `map_screen.dart` a été refactorisé pour supprimer l'ancien affichage par marqueurs et cercles. Le widget placeholder `WasteDumpDetailsBottomSheet` a été créé et la méthode `_showWasteDumpDetails` a été mise à jour pour utiliser `showModalBottomSheet`. Une tentative a été faite pour corriger un avertissement d'analyse statique persistant (`use_build_context_synchronously`) dans un fichier non lié (`location_permission_service.dart`), mais sans succès. Pour ne pas bloquer l'avancement, il a été décidé de l'ignorer pour le moment. La phase s'est terminée par l'exécution des outils de formatage et d'analyse.

---

## Plan par Phases

### Phase 1 : Préparation et Refactoring Initial

L'objectif de cette phase est de préparer le code pour les nouvelles fonctionnalités en supprimant l'ancien affichage et en créant les nouveaux fichiers nécessaires.

- [x] Exécuter tous les tests pour s'assurer que le projet est dans un état stable avant de commencer les modifications.
- [x] Dans `lib/presentation/screens/map/map_screen.dart`, supprimer les propriétés `markers` et `circles` du widget `GoogleMap`.
- [x] Créer un nouveau fichier pour le widget du bottom sheet : `lib/presentation/widgets/waste_dump_details_bottom_sheet.dart`.
- [x] Dans ce nouveau fichier, créer la structure de base du widget `WasteDumpDetailsBottomSheet` (un `StatelessWidget` qui accepte un `WasteDump`).
- [x] Dans `lib/presentation/screens/map/map_screen.dart`, modifier la méthode `_showWasteDumpDetails` pour qu'elle utilise `showModalBottomSheet` et affiche le nouveau widget `WasteDumpDetailsBottomSheet`.

**Après cette phase :**
- [x] Créer/modifier les tests unitaires pertinents.
- [x] Exécuter `dart fix --apply`.
- [x] Exécuter l'analyseur de code et corriger les problèmes.
- [x] Exécuter tous les tests pour vérifier qu'il n'y a pas de régressions.
- [x] Exécuter `dart format .`.
- [x] Mettre à jour la section "Journal" de ce document.
- [ ] Préparer le message de commit pour les changements, le présenter pour approbation, et attendre l'approbation avant de commettre.

### Phase 2 : Implémentation de la Heatmap

L'objectif est d'afficher les données des dépotoirs sous forme de heatmap.

- [ ] S'assurer que la version de `google_maps_flutter` dans `pubspec.yaml` est suffisamment récente pour supporter les heatmaps. Si non, la mettre à jour.
- [ ] Dans `lib/presentation/screens/map/map_screen.dart`, transformer la liste de `WasteDump` en une liste de `gmaps.WeightedLatLng`. L'intensité (`intensity`) sera basée sur la `surfaceArea`.
- [ ] Ajouter la propriété `heatmaps` au widget `GoogleMap` et lui fournir les données générées.
- [ ] Ajuster les propriétés de la heatmap (`radius`, `opacity`, `gradient`) pour obtenir le meilleur rendu visuel.

**Après cette phase :**
- [ ] Créer/modifier les tests unitaires pertinents.
- [ ] Exécuter `dart fix --apply`.
- [ ] Exécuter l'analyseur de code et corriger les problèmes.
- [ ] Exécuter tous les tests pour vérifier qu'il n'y a pas de régressions.
- [ ] Exécuter `dart format .`.
- [ ] Mettre à jour la section "Journal" de ce document.
- [ ] Préparer le message de commit pour les changements, le présenter pour approbation, et attendre l'approbation avant de commettre.

### Phase 3 : Interaction avec la Carte (On Tap)

L'objectif est de détecter un appui sur la carte et d'identifier le dépotoir le plus proche.

- [ ] Implémenter le callback `onTap` sur le widget `GoogleMap`.
- [ ] Dans le `onTap`, récupérer la liste actuelle des `WasteDump` depuis le `wasteDumpsProvider`.
- [ ] Créer une fonction pour trouver le `WasteDump` le plus proche des coordonnées de l'appui, en utilisant `Geolocator.distanceBetween`.
- [ ] Ajouter un seuil de distance (par exemple, 200 mètres) pour ne déclencher l'affichage que si l'appui est suffisamment proche d'un dépotoir.
- [ ] Appeler la méthode `_showWasteDumpDetails` avec le dépotoir trouvé.

**Après cette phase :**
- [ ] Créer/modifier les tests unitaires pertinents.
- [ ] Exécuter `dart fix --apply`.
- [ ] Exécuter l'analyseur de code et corriger les problèmes.
- [ ] Exécuter tous les tests pour vérifier qu'il n'y a pas de régressions.
- [ ] Exécuter `dart format .`.
- [ ] Mettre à jour la section "Journal" de ce document.
- [ ] Préparer le message de commit pour les changements, le présenter pour approbation, et attendre l'approbation avant de commettre.

### Phase 4 : Conception et Finalisation du Bottom Sheet

L'objectif est de finaliser le design et le comportement du bottom sheet pour qu'il soit professionnel et informatif.

- [ ] Dans `lib/presentation/widgets/waste_dump_details_bottom_sheet.dart`, implémenter un `DraggableScrollableSheet` pour rendre la feuille redimensionnable.
- [ ] Appliquer un design soigné : coins supérieurs arrondis, espacements corrects, et une poignée de glissement (`drag handle`).
- [ ] Intégrer l'affichage de l'image (`Image.network`) avec un `loadingBuilder` et un `errorBuilder`.
- [ ] Afficher toutes les informations pertinentes du `WasteDump` (`surfaceArea`, `timestamp`, `description`, etc.) en utilisant une typographie claire et hiérarchisée.
- [ ] S'assurer que le layout est responsive et s'adapte bien aux différentes tailles d'écran.

**Après cette phase :**
- [ ] Créer/modifier les tests unitaires pertinents.
- [ ] Exécuter `dart fix --apply`.
- [ ] Exécuter l'analyseur de code et corriger les problèmes.
- [ ] Exécuter tous les tests pour vérifier qu'il n'y a pas de régressions.
- [ ] Exécuter `dart format .`.
- [ ] Mettre à jour la section "Journal" de ce document.
- [ ] Préparer le message de commit pour les changements, le présenter pour approbation, et attendre l'approbation avant de commettre.

### Phase 5 : Finalisation

L'objectif est de s'assurer que le projet est propre et que la documentation est à jour.

- [ ] Mettre à jour le fichier `README.md` du projet si des changements importants ont été apportés qui nécessitent une documentation.
- [ ] Demander à l'utilisateur d'inspecter la fonctionnalité et de confirmer si elle répond à ses attentes.
- [ ] Une fois la satisfaction confirmée, effectuer le commit final pour l'ensemble de la fonctionnalité, comme demandé.