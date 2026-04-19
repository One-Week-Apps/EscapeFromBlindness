# Design : Niveau Swipe Gesture — Chapitre 5 "The Whispering Library"

## Contexte

EscapeFromBlindness est un escape game pédagogique qui enseigne VoiceOver à travers des chapitres thématiques. Chaque chapitre introduit un geste VoiceOver distinct. Ce document spécifie l'ajout du chapitre 5 qui enseigne le swipe à 3 doigts (scroll de page VoiceOver).

## Objectif pédagogique

Apprendre à l'utilisateur à utiliser le **swipe à 3 doigts** sous VoiceOver :
- **Vertical** (haut/bas) : scroller le contenu d'une page
- **Horizontal** (gauche/droite) : naviguer entre plusieurs pages

## Narration

**Chapitre 5 : "The Whispering Library"**

L'explorateur découvre une bibliothèque ancienne népalaise. Des parchemins secrets contiennent les indices pour ouvrir la sortie. Il doit faire défiler les parchemins (verticalement et horizontalement) pour trouver le passage caché.

## Modèle : `SwipeGestureLevel`

Sous-classe de `Level`. Remplace `answers`/`validAnswers` hérités par une logique de navigation de contenu.

```swift
enum SwipeDirection {
    case vertical
    case horizontal
}

class SwipeGestureLevel: Level {
    let instruction: String
    let swipeDirections: [SwipeDirection]  // directions requises dans l'ordre
    let scrollableContent: [[String]]      // contenu par axe : [axe][page]
    let validAnswer: String                // réponse à trouver au bout du parcours

    init(
        instruction: String,
        swipeDirections: [SwipeDirection],
        scrollableContent: [[String]],
        validAnswer: String,
        hints: [String] = []
    )
}
```

**Invariant :** `swipeDirections.count == scrollableContent.count`

## Vue : `SwipeGestureViewController`

Sous-classe de `LevelBaseViewController`.

**Structure UI :**
- `UILabel` (instruction narrative) en haut
- `UIScrollView` pour l'axe vertical — enfants accessibles individuellement
- `UIPageViewController` imbriqué pour l'axe horizontal (activé si `.horizontal` est dans `swipeDirections`)
- Bouton "Valider" accessible qui appelle `coordinator?.validate([validAnswer])` quand l'utilisateur est sur le bon contenu

**Accessibilité :**
- Le `UIScrollView` a `isAccessibilityElement = false` — VoiceOver navigue dans ses enfants
- Chaque page/section est un `UILabel` avec `isAccessibilityElement = true`
- Le swipe à 3 doigts est natif à VoiceOver sur un `UIScrollView` — aucun gesture recognizer custom nécessaire

## Routing

**`AppCoordinatorProtocol`** — ajout :
```swift
func presentSwipeGestureController(_ level: Level)
```

**`AppCoordinator.routeToLevel`** — ajout du case :
```swift
case is SwipeGestureLevel:
    presentSwipeGestureController(level)
```

## Contenu : `LocalLevelFactory`

Nouveau chapitre 5 avec 2 niveaux :

**Niveau 1** — directions : `[.vertical]`
- Parchemin vertical à scroller pour trouver un mot caché en bas

**Niveau 2** — directions : `[.vertical, .horizontal]`
- Plusieurs parchemins (pages horizontales), chacun scrollable verticalement
- L'utilisateur doit naviguer au bon parchemin ET scroller au bon endroit

## Tests

Suivre le pattern existant (`ClosedQuestionLevelViewControllerTests`) :

- `SwipeGestureLevelTests` : validation du modèle (invariant directions/contenu)
- `SwipeGestureViewControllerTests` : affichage de l'instruction, appel `coordinator?.validate` au bon moment
- `AppCoordinatorTests` : `routeToLevel` avec un `SwipeGestureLevel` appelle `presentSwipeGestureController`
- `LocalLevelFactoryTests` : le chapitre 5 contient 2 niveaux de type `SwipeGestureLevel`
