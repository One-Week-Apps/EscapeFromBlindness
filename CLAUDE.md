# EscapeFromBlindness — Règles du projet

## Stack

Swift, UIKit, XCTest, CocoaPods workspace (`EscapeFromBlindness.xcworkspace`).

## Commande de test

```bash
xcodebuild test \
  -workspace EscapeFromBlindness.xcworkspace \
  -scheme EscapeFromBlindness \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  2>&1 | grep -E "(PASS|FAIL|error:|TEST SUCCEEDED|TEST FAILED)" | tail -20
```

**Prérequis** : CocoaPods doit être installé (`pod install` depuis la racine du projet). Vérifier que le build de base fonctionne avant de commencer tout travail d'implémentation.

## Conventions de nommage des clés de localisation

Les clés Localizable.strings suivent la convention SwiftGen : chaque segment séparé par `_` devient un mot en camelCase avec la première lettre en majuscule.

**Règle** : chaque composant sémantique distinct doit avoir son propre `_`.

```
chapter5_l1_s1   → L10n.chapter5L1S1   ✅ (l, 1, s, 1 = segments distincts)
chapter5_l2_p1_s1 → L10n.chapter5L2P1S1 ✅
chapter5_l2_p1s1  → L10n.chapter5L2P1s1 ❌ (p1s1 = un seul mot, s pas capitalisé)
```

**Checklist avant d'ajouter de nouvelles clés :**
- [ ] Chaque composant (chapitre, niveau, page, section) a son propre `_`
- [ ] Vérifier la cohérence avec les clés existantes du même type
- [ ] Après ajout manuel dans `Strings.swift`, confirmer que le nom Swift généré correspond à ce qui est utilisé dans le code

## Architecture

Pattern Coordinator : `AppCoordinator` route vers les ViewControllers via `routeToLevel`.

Pour ajouter un nouveau type de niveau :
1. Modèle (`Level` subclass) dans `Models/`
2. ViewController (`LevelBaseViewController` subclass) dans `Scenes/Levels/`
3. Méthode `presentXxxController` dans `AppCoordinatorProtocol` + `AppCoordinator` + `AppCoordinatorSpy`
4. `case is XxxLevel` dans `routeToLevel`
5. Contenu dans `LocalLevelFactory` + strings EN/FR + `Strings.swift`
6. Ajouter les fichiers au `project.pbxproj` (groupe correct + target correct)
