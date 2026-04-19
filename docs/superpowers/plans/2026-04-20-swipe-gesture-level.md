# SwipeGestureLevel — Chapitre 5 "The Whispering Library" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajouter un nouveau type de niveau `SwipeGestureLevel` qui enseigne le swipe à 3 doigts VoiceOver (scroll vertical + navigation horizontale entre parchemins), incarné dans le chapitre 5 "The Whispering Library".

**Architecture:** Suit le pattern existant du projet : 1 modèle (`SwipeGestureLevel` sous-classe de `Level`) + 1 ViewController (`SwipeGestureViewController` sous-classe de `LevelBaseViewController`) + 1 method dans l'`AppCoordinator` + 1 case dans le switch `routeToLevel`. Le contenu narratif est ajouté dans les fichiers de localisation et dans `LocalLevelFactory`.

**Tech Stack:** Swift, UIKit, XCTest, CocoaPods workspace. Tests via `xcodebuild test`.

---

## File Map

| Fichier | Action | Responsabilité |
|---|---|---|
| `EscapeFromBlindness/Models/SwipeGestureLevel.swift` | Créer | Modèle + enum `SwipeDirection` |
| `EscapeFromBlindness/Scenes/Levels/SwipeGestureViewController.swift` | Créer | Vue scrollable + validation |
| `EscapeFromBlindness/Application/Coordinators/AppCoordinator.swift` | Modifier | Routing du nouveau type |
| `EscapeFromBlindnessTests/Test Doubles/AppCoordinatorSpy.swift` | Modifier | Spy pour le nouveau presenter |
| `EscapeFromBlindness/Resources/en.lproj/Localizable.strings` | Modifier | Strings chapitre 5 (EN) |
| `EscapeFromBlindness/Resources/fr.lproj/Localizable.strings` | Modifier | Strings chapitre 5 (FR) |
| `EscapeFromBlindness/Resources/Generated/Strings.swift` | Modifier | Entrées L10n chapitre 5 |
| `EscapeFromBlindness/Application/Factories/LocalLevelFactory.swift` | Modifier | Chapitre 5 avec 2 niveaux |
| `EscapeFromBlindnessTests/Level Types/SwipeGestureLevelTests.swift` | Créer | Tests modèle |
| `EscapeFromBlindnessTests/Level Types/SwipeGestureViewControllerTests.swift` | Créer | Tests vue |
| `EscapeFromBlindnessTests/AppCoordinatorTests.swift` | Modifier | Test routing |
| `EscapeFromBlindnessTests/LocalLevelFactoryTests.swift` | Modifier | Test chapitre 5 |

---

## Commande de test (à utiliser après chaque tâche)

```bash
xcodebuild test \
  -workspace EscapeFromBlindness.xcworkspace \
  -scheme EscapeFromBlindness \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  2>&1 | grep -E "(PASS|FAIL|error:|warning:)" | tail -30
```

---

### Task 1: SwipeGestureLevel model

**Goal:** Créer le modèle `SwipeGestureLevel` avec `SwipeDirection` et ses tests unitaires.

**Files:**
- Create: `EscapeFromBlindness/Models/SwipeGestureLevel.swift`
- Create: `EscapeFromBlindnessTests/Level Types/SwipeGestureLevelTests.swift`

**Acceptance Criteria:**
- [ ] `SwipeDirection` enum avec cases `.vertical` et `.horizontal`
- [ ] `SwipeGestureLevel` est une sous-classe de `Level`
- [ ] L'init accepte `instruction`, `swipeDirections`, `pages`, `validAnswer`, `hints`
- [ ] `validAnswers` hérité de `Level` est initialisé à `[validAnswer]`
- [ ] Les tests passent

**Verify:**
```bash
xcodebuild test \
  -workspace EscapeFromBlindness.xcworkspace \
  -scheme EscapeFromBlindness \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:EscapeFromBlindnessTests/SwipeGestureLevelTests \
  2>&1 | grep -E "(PASS|FAIL|error:)"
```
Expected: `** TEST SUCCEEDED **`

**Steps:**

- [ ] **Step 1: Écrire les tests du modèle (red)**

Créer `EscapeFromBlindnessTests/Level Types/SwipeGestureLevelTests.swift` :

```swift
import XCTest
@testable import EscapeFromBlindness

class SwipeGestureLevelTests: XCTestCase {

    func test_init_vertical_shouldSetProperties() {
        let level = SwipeGestureLevel(
            instruction: "Scroll down to find the word",
            swipeDirections: [.vertical],
            pages: [["Section 1", "Secret"]],
            validAnswer: "Secret"
        )

        XCTAssertEqual(level.instruction, "Scroll down to find the word")
        XCTAssertEqual(level.swipeDirections, [.vertical])
        XCTAssertEqual(level.pages, [["Section 1", "Secret"]])
        XCTAssertEqual(level.validAnswer, "Secret")
        XCTAssertEqual(level.validAnswers, ["Secret"])
    }

    func test_init_verticalAndHorizontal_shouldSetProperties() {
        let level = SwipeGestureLevel(
            instruction: "Navigate parchments",
            swipeDirections: [.vertical, .horizontal],
            pages: [["p1s1", "p1s2"], ["p2s1", "ANSWER"]],
            validAnswer: "ANSWER"
        )

        XCTAssertEqual(level.swipeDirections, [.vertical, .horizontal])
        XCTAssertEqual(level.pages.count, 2)
        XCTAssertEqual(level.validAnswers, ["ANSWER"])
    }

    func test_init_withHints_shouldPassHintsToParent() {
        let level = SwipeGestureLevel(
            instruction: "Find it",
            swipeDirections: [.vertical],
            pages: [["Section 1"]],
            validAnswer: "Section 1",
            hints: ["Hint 1", "Hint 2"]
        )

        XCTAssertEqual(level.hints, ["Hint 1", "Hint 2"])
    }
}
```

- [ ] **Step 2: Vérifier que les tests échouent (compile error attendue)**

```bash
xcodebuild test \
  -workspace EscapeFromBlindness.xcworkspace \
  -scheme EscapeFromBlindness \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:EscapeFromBlindnessTests/SwipeGestureLevelTests \
  2>&1 | grep -E "(error:|FAIL)"
```
Expected: erreur de compilation `cannot find type 'SwipeGestureLevel'`

- [ ] **Step 3: Implémenter le modèle**

Créer `EscapeFromBlindness/Models/SwipeGestureLevel.swift` :

```swift
import Foundation

enum SwipeDirection: Equatable {
    case vertical
    case horizontal
}

class SwipeGestureLevel: Level {
    let instruction: String
    let swipeDirections: [SwipeDirection]
    // pages[i] = sections verticales du parchemin i
    // count == 1 si uniquement .vertical ; count > 1 si .horizontal inclus
    let pages: [[String]]
    let validAnswer: String

    init(
        instruction: String,
        swipeDirections: [SwipeDirection],
        pages: [[String]],
        validAnswer: String,
        hints: [String] = []
    ) {
        self.instruction = instruction
        self.swipeDirections = swipeDirections
        self.pages = pages
        self.validAnswer = validAnswer
        super.init(answers: [], validAnswers: [validAnswer], hints: hints)
    }
}
```

- [ ] **Step 4: Vérifier que les tests passent (green)**

```bash
xcodebuild test \
  -workspace EscapeFromBlindness.xcworkspace \
  -scheme EscapeFromBlindness \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:EscapeFromBlindnessTests/SwipeGestureLevelTests \
  2>&1 | grep -E "(PASS|FAIL|error:)"
```
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Ajouter le fichier au projet Xcode**

Le fichier doit être ajouté via Xcode (drag & drop dans le groupe `Models`) ou via `project.pbxproj`. Si tu travailles en CLI, ouvre Xcode, ajoute le fichier au target `EscapeFromBlindness`, puis relance les tests.

- [ ] **Step 6: Committer**

```bash
git add EscapeFromBlindness/Models/SwipeGestureLevel.swift \
        EscapeFromBlindnessTests/Level\ Types/SwipeGestureLevelTests.swift
git commit -m "feat: add SwipeGestureLevel model and SwipeDirection enum"
```

---

### Task 2: Routing — AppCoordinatorProtocol + AppCoordinator + Spy + test

**Goal:** Enregistrer `SwipeGestureLevel` dans le système de routing pour que `routeToLevel` sache quelle vue présenter.

**Files:**
- Modify: `EscapeFromBlindness/Application/Coordinators/AppCoordinator.swift`
- Modify: `EscapeFromBlindnessTests/Test Doubles/AppCoordinatorSpy.swift`
- Modify: `EscapeFromBlindnessTests/AppCoordinatorTests.swift`

**Acceptance Criteria:**
- [ ] `AppCoordinatorProtocol` déclare `presentSwipeGestureController(_ level: Level)`
- [ ] `AppCoordinator` implémente la méthode et l'appelle depuis `routeToLevel`
- [ ] `AppCoordinatorSpy` implémente le protocole mis à jour
- [ ] Le test `test_routeToLevel_withSwipeGestureLevel_shouldCallPresentSwipeGestureController` passe

**Verify:**
```bash
xcodebuild test \
  -workspace EscapeFromBlindness.xcworkspace \
  -scheme EscapeFromBlindness \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:EscapeFromBlindnessTests/AppCoordinatorTests \
  2>&1 | grep -E "(PASS|FAIL|error:)"
```
Expected: `** TEST SUCCEEDED **`

**Steps:**

- [ ] **Step 1: Écrire le test de routing (red)**

Dans `EscapeFromBlindnessTests/AppCoordinatorTests.swift`, ajouter à la fin de la classe :

```swift
func test_routeToLevel_withSwipeGestureLevel_shouldCallPresentSwipeGestureController() {
    sut.start(window: UIWindow())

    let title = "test title"
    gameFlowMock.expectedChapterTitle = title
    let level = SwipeGestureLevel(
        instruction: "Scroll",
        swipeDirections: [.vertical],
        pages: [["Section 1"]],
        validAnswer: "Section 1"
    )

    sut.presentSwipeGestureController(level)

    assertNavBar(chapterName: title, level: 1)
}
```

- [ ] **Step 2: Vérifier que le test échoue**

```bash
xcodebuild test \
  -workspace EscapeFromBlindness.xcworkspace \
  -scheme EscapeFromBlindness \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:EscapeFromBlindnessTests/AppCoordinatorTests \
  2>&1 | grep -E "(error:|FAIL)"
```
Expected: `error: value of type 'AppCoordinator' has no member 'presentSwipeGestureController'`

- [ ] **Step 3: Ajouter la méthode au protocole**

Dans `EscapeFromBlindness/Application/Coordinators/AppCoordinator.swift`, dans `protocol AppCoordinatorProtocol`, ajouter après `presentSearchQuestionController` :

```swift
func presentSwipeGestureController(_ level: Level)
```

- [ ] **Step 4: Implémenter dans AppCoordinator**

Dans `AppCoordinator`, dans la section `// MARK: - Game`, ajouter après `presentSearchQuestionController` :

```swift
func presentSwipeGestureController(_ level: Level) {
    guard let level = level as? SwipeGestureLevel else { return }
    let viewController = SwipeGestureViewController(level: level)
    viewController.coordinator = self
    resetNavigationStack(viewController)
}
```

Dans l'extension `AppCoordinator: Router`, dans `routeToLevel`, ajouter avant `default:` :

```swift
case is SwipeGestureLevel:
    presentSwipeGestureController(level)
```

- [ ] **Step 5: Mettre à jour AppCoordinatorSpy**

Dans `EscapeFromBlindnessTests/Test Doubles/AppCoordinatorSpy.swift`, ajouter après `presentSearchQuestionControllerCalled` :

```swift
var presentSwipeGestureControllerCalled = false

func presentSwipeGestureController(_ level: Level) {
    presentSwipeGestureControllerCalled = true
}
```

- [ ] **Step 6: Vérifier que les tests passent (green)**

```bash
xcodebuild test \
  -workspace EscapeFromBlindness.xcworkspace \
  -scheme EscapeFromBlindness \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:EscapeFromBlindnessTests/AppCoordinatorTests \
  2>&1 | grep -E "(PASS|FAIL|error:)"
```
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 7: Committer**

```bash
git add EscapeFromBlindness/Application/Coordinators/AppCoordinator.swift \
        EscapeFromBlindnessTests/Test\ Doubles/AppCoordinatorSpy.swift \
        EscapeFromBlindnessTests/AppCoordinatorTests.swift
git commit -m "feat: add SwipeGestureLevel routing to AppCoordinator"
```

---

### Task 3: SwipeGestureViewController

**Goal:** Créer la vue qui présente les parchemins scrollables et valide la réponse quand l'utilisateur active une section.

**Files:**
- Create: `EscapeFromBlindness/Scenes/Levels/SwipeGestureViewController.swift`
- Create: `EscapeFromBlindnessTests/Level Types/SwipeGestureViewControllerTests.swift`

**Acceptance Criteria:**
- [ ] `instructionLabel` affiche `level.instruction`
- [ ] Le `scrollView` contient autant de boutons que de sections dans `level.pages[0]`
- [ ] Activer un bouton appelle `coordinator?.validate([text])` avec le texte du bouton
- [ ] Pour un niveau avec `.horizontal`, le scrollView a `isPagingEnabled = true`
- [ ] Les tests passent

**Verify:**
```bash
xcodebuild test \
  -workspace EscapeFromBlindness.xcworkspace \
  -scheme EscapeFromBlindness \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:EscapeFromBlindnessTests/SwipeGestureViewControllerTests \
  2>&1 | grep -E "(PASS|FAIL|error:)"
```
Expected: `** TEST SUCCEEDED **`

**Steps:**

- [ ] **Step 1: Écrire les tests de la vue (red)**

Créer `EscapeFromBlindnessTests/Level Types/SwipeGestureViewControllerTests.swift` :

```swift
import XCTest
@testable import EscapeFromBlindness

class SwipeGestureViewControllerTests: XCTestCase {

    var sut: SwipeGestureViewController!
    var window: UIWindow!
    var coordinator: AppCoordinatorSpy!

    override func setUp() {
        super.setUp()
        window = UIWindow()
        coordinator = AppCoordinatorSpy()
    }

    override func tearDown() {
        window = nil
        super.tearDown()
    }

    private func loadView() {
        window.addSubview(sut.view)
        RunLoop.current.run(until: Date())
    }

    // MARK: - Display Tests

    func test_viewDidLoad_shouldDisplayInstruction() {
        let level = SwipeGestureLevel(
            instruction: "Scroll down to find the hidden word",
            swipeDirections: [.vertical],
            pages: [["Section 1", "Secret"]],
            validAnswer: "Secret"
        )
        sut = SwipeGestureViewController(level: level)
        sut.coordinator = coordinator

        loadView()

        XCTAssertEqual(sut.instructionLabel.text, "Scroll down to find the hidden word")
    }

    func test_viewDidLoad_verticalLevel_shouldCreateButtonsForEachSection() {
        let level = SwipeGestureLevel(
            instruction: "Scroll",
            swipeDirections: [.vertical],
            pages: [["Section 1", "Section 2", "Section 3"]],
            validAnswer: "Section 3"
        )
        sut = SwipeGestureViewController(level: level)
        sut.coordinator = coordinator

        loadView()

        let buttons = sut.scrollView.subviews.compactMap { $0 as? UIButton }
        XCTAssertEqual(buttons.count, 3)
    }

    func test_viewDidLoad_verticalLevel_scrollViewShouldNotHavePagingEnabled() {
        let level = SwipeGestureLevel(
            instruction: "Scroll",
            swipeDirections: [.vertical],
            pages: [["Section 1"]],
            validAnswer: "Section 1"
        )
        sut = SwipeGestureViewController(level: level)
        sut.coordinator = coordinator

        loadView()

        XCTAssertFalse(sut.scrollView.isPagingEnabled)
    }

    func test_viewDidLoad_horizontalLevel_scrollViewShouldHavePagingEnabled() {
        let level = SwipeGestureLevel(
            instruction: "Navigate parchments",
            swipeDirections: [.vertical, .horizontal],
            pages: [["p1s1"], ["p2s1"]],
            validAnswer: "p2s1"
        )
        sut = SwipeGestureViewController(level: level)
        sut.coordinator = coordinator

        loadView()

        XCTAssertTrue(sut.scrollView.isPagingEnabled)
    }

    // MARK: - Validation Tests

    func test_sectionActivated_shouldCallValidateOnCoordinator() {
        let level = SwipeGestureLevel(
            instruction: "Find it",
            swipeDirections: [.vertical],
            pages: [["Section 1", "Answer"]],
            validAnswer: "Answer"
        )
        sut = SwipeGestureViewController(level: level)
        sut.coordinator = coordinator

        loadView()

        let buttons = sut.scrollView.subviews.compactMap { $0 as? UIButton }
        buttons.first?.sendActions(for: .touchUpInside)

        XCTAssertEqual(coordinator.validateAnswers, ["Section 1"])
    }

    func test_validSectionActivated_shouldPassValidAnswerToCoordinator() {
        let level = SwipeGestureLevel(
            instruction: "Find it",
            swipeDirections: [.vertical],
            pages: [["Wrong", "Answer"]],
            validAnswer: "Answer"
        )
        sut = SwipeGestureViewController(level: level)
        sut.coordinator = coordinator

        loadView()

        let buttons = sut.scrollView.subviews.compactMap { $0 as? UIButton }
        buttons.last?.sendActions(for: .touchUpInside)

        XCTAssertEqual(coordinator.validateAnswers, ["Answer"])
    }
}
```

- [ ] **Step 2: Vérifier que les tests échouent**

```bash
xcodebuild test \
  -workspace EscapeFromBlindness.xcworkspace \
  -scheme EscapeFromBlindness \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:EscapeFromBlindnessTests/SwipeGestureViewControllerTests \
  2>&1 | grep -E "(error:|FAIL)"
```
Expected: `error: cannot find type 'SwipeGestureViewController'`

- [ ] **Step 3: Implémenter SwipeGestureViewController**

Créer `EscapeFromBlindness/Scenes/Levels/SwipeGestureViewController.swift` :

```swift
import UIKit

class SwipeGestureViewController: LevelBaseViewController {

    var instructionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.isAccessibilityElement = false
        return sv
    }()

    private var level: SwipeGestureLevel!

    convenience init(level: SwipeGestureLevel) {
        self.init()
        self.level = level
    }

    override func viewDidLoad() {
        setupHints()
        super.viewDidLoad()
        setupViews()
        buildContent()
    }

    private func setupHints() {
        self.hints = level.hints
    }

    private func setupViews() {
        view.addSubview(instructionLabel)
        view.addSubview(scrollView)

        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        instructionLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30).isActive = true
        instructionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 150).isActive = true

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 40).isActive = true
        scrollView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30).isActive = true

        instructionLabel.text = level.instruction

        if level.swipeDirections.contains(.horizontal) {
            scrollView.isPagingEnabled = true
        }
    }

    private func buildContent() {
        let screenWidth = UIScreen.main.bounds.width

        for (pageIndex, page) in level.pages.enumerated() {
            var previousAnchor = scrollView.topAnchor

            for (sectionIndex, text) in page.enumerated() {
                let button = makeButton(text: text)
                scrollView.addSubview(button)

                button.translatesAutoresizingMaskIntoConstraints = false
                button.topAnchor.constraint(equalTo: previousAnchor, constant: 20).isActive = true
                button.leftAnchor.constraint(
                    equalTo: scrollView.leftAnchor,
                    constant: CGFloat(pageIndex) * screenWidth + 30
                ).isActive = true
                button.widthAnchor.constraint(equalToConstant: screenWidth - 60).isActive = true

                if sectionIndex == page.count - 1 && !level.swipeDirections.contains(.horizontal) {
                    button.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20).isActive = true
                }

                previousAnchor = button.bottomAnchor
            }
        }
    }

    private func makeButton(text: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(text, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(sectionSelected(_:)), for: .touchUpInside)
        return button
    }

    @objc private func sectionSelected(_ sender: UIButton) {
        guard let text = sender.title(for: .normal) else { return }
        coordinator?.validate([text])
    }
}
```

- [ ] **Step 4: Ajouter les fichiers au projet Xcode**

Ouvrir Xcode et ajouter :
- `SwipeGestureViewController.swift` dans le groupe `Scenes/Levels`, target `EscapeFromBlindness`
- `SwipeGestureViewControllerTests.swift` dans le groupe `Level Types` des tests, target `EscapeFromBlindnessTests`

- [ ] **Step 5: Vérifier que les tests passent (green)**

```bash
xcodebuild test \
  -workspace EscapeFromBlindness.xcworkspace \
  -scheme EscapeFromBlindness \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:EscapeFromBlindnessTests/SwipeGestureViewControllerTests \
  2>&1 | grep -E "(PASS|FAIL|error:)"
```
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 6: Committer**

```bash
git add EscapeFromBlindness/Scenes/Levels/SwipeGestureViewController.swift \
        EscapeFromBlindnessTests/Level\ Types/SwipeGestureViewControllerTests.swift
git commit -m "feat: add SwipeGestureViewController with vertical and horizontal scroll support"
```

---

### Task 4: Chapitre 5 — Localisation + contenu + factory

**Goal:** Ajouter les strings du chapitre 5 en EN et FR, les entrées L10n correspondantes dans `Strings.swift`, et le chapitre 5 dans `LocalLevelFactory`.

**Files:**
- Modify: `EscapeFromBlindness/Resources/en.lproj/Localizable.strings`
- Modify: `EscapeFromBlindness/Resources/fr.lproj/Localizable.strings`
- Modify: `EscapeFromBlindness/Resources/Generated/Strings.swift`
- Modify: `EscapeFromBlindness/Application/Factories/LocalLevelFactory.swift`
- Modify: `EscapeFromBlindnessTests/LocalLevelFactoryTests.swift`

**Acceptance Criteria:**
- [ ] `LocalLevelFactory.build()` retourne 5 chapitres
- [ ] Le chapitre 5 contient exactement 2 niveaux de type `SwipeGestureLevel`
- [ ] Le niveau 1 a `swipeDirections: [.vertical]`
- [ ] Le niveau 2 a `swipeDirections: [.vertical, .horizontal]` et 3 parchemins
- [ ] Les tests `LocalLevelFactoryTests` passent

**Verify:**
```bash
xcodebuild test \
  -workspace EscapeFromBlindness.xcworkspace \
  -scheme EscapeFromBlindness \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:EscapeFromBlindnessTests/LocalLevelFactoryTests \
  2>&1 | grep -E "(PASS|FAIL|error:)"
```
Expected: `** TEST SUCCEEDED **`

**Steps:**

- [ ] **Step 1: Écrire les tests factory (red)**

Dans `EscapeFromBlindnessTests/LocalLevelFactoryTests.swift`, remplacer `expectedNumberOfLevels` et ajouter les assertions chapitre 5 :

```swift
class LocalLevelFactoryTests: XCTestCase {

    private let expectedNumberOfChapters = 5

    func test_build_shouldReturnCorrectNumberOfChapters() {
        let chapters = LocalLevelFactory.build()
        XCTAssertEqual(chapters.count, expectedNumberOfChapters)
    }

    func test_build_shouldReturnEqualNumberOfEachLevelTypes() {
        let chapters = LocalLevelFactory.build()

        XCTAssertEqual(chapters[0].levels.filter { $0 is ClosedQuestionLevel }.count, 4)
        XCTAssertEqual(chapters[1].levels.filter { $0 is RotorLevel }.count, 2)
        XCTAssertEqual(chapters[2].levels.filter { $0 is OpenQuestionLevel }.count, 4)
        XCTAssertEqual(chapters[3].levels.filter { $0 is SearchLevel }.count, 2)
        XCTAssertEqual(chapters[4].levels.filter { $0 is SwipeGestureLevel }.count, 2)
    }

    func test_build_chapter5Level1_shouldBeVerticalOnly() {
        let chapters = LocalLevelFactory.build()
        let level = chapters[4].levels[0] as! SwipeGestureLevel

        XCTAssertEqual(level.swipeDirections, [.vertical])
        XCTAssertEqual(level.pages.count, 1)
    }

    func test_build_chapter5Level2_shouldHaveVerticalAndHorizontal() {
        let chapters = LocalLevelFactory.build()
        let level = chapters[4].levels[1] as! SwipeGestureLevel

        XCTAssertTrue(level.swipeDirections.contains(.vertical))
        XCTAssertTrue(level.swipeDirections.contains(.horizontal))
        XCTAssertEqual(level.pages.count, 3)
    }
}
```

- [ ] **Step 2: Vérifier que les tests échouent**

```bash
xcodebuild test \
  -workspace EscapeFromBlindness.xcworkspace \
  -scheme EscapeFromBlindness \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -only-testing:EscapeFromBlindnessTests/LocalLevelFactoryTests \
  2>&1 | grep -E "(FAIL|error:)"
```
Expected: `XCTAssertEqual failed: ("4") is not equal to ("5")`

- [ ] **Step 3: Ajouter les strings EN**

Dans `EscapeFromBlindness/Resources/en.lproj/Localizable.strings`, ajouter à la fin :

```
//======================================================
/* Chapter 5 */
"chapter5_description" = "You made your way through the Hidden Tomb and now discover a secret library, untouched for centuries. Ancient parchments hold the key to escape. When VoiceOver is turned on, scroll through content by swiping up or down with THREE fingers. Swipe left or right with THREE fingers to move between parchments.";

// Level 1
"chapter5_l1_instruction" = "A single parchment lies unrolled before you. Scroll it to find the hidden word.";
"chapter5_l1_s1" = "The first line reads: 'In the year of the great flood...'";
"chapter5_l1_s2" = "'...the priests hid their most sacred treasure...'";
"chapter5_l1_s3" = "'...behind the stone marked with the symbol of...'";
"chapter5_l1_answer" = "LOTUS";
"chapter5_l1_h1" = "Scroll down to find more text on the parchment.";
"chapter5_l1_h2" = "The answer is the last word on the parchment.";

// Level 2
"chapter5_l2_instruction" = "Three parchments lie before you. Navigate between them and scroll each one to find the secret passage word.";
"chapter5_l2_p1s1" = "Parchment I — 'The first scribe wrote of the mountains...'";
"chapter5_l2_p1s2" = "'...and the rivers that flow beneath the ancient stones.'";
"chapter5_l2_p2s1" = "Parchment II — 'The second scribe speaks of a hidden path...'";
"chapter5_l2_p2_answer" = "MOONGATE";
"chapter5_l2_p3s1" = "Parchment III — 'The third scribe warns of false passages...'";
"chapter5_l2_p3s2" = "'...do not be deceived by the golden door.'";
"chapter5_l2_h1" = "Swipe left or right with three fingers to navigate between parchments.";
```

- [ ] **Step 4: Ajouter les strings FR**

Dans `EscapeFromBlindness/Resources/fr.lproj/Localizable.strings`, ajouter à la fin :

```
//======================================================
/* Chapitre 5 */
"chapter5_description" = "Tu as traversé le Tombeau Caché et tu découvres maintenant une bibliothèque secrète, intacte depuis des siècles. D'anciens parchemins contiennent la clé pour s'échapper. Lorsque VoiceOver est activé, fais défiler le contenu en glissant vers le haut ou le bas avec TROIS doigts. Glisse vers la gauche ou la droite avec TROIS doigts pour passer d'un parchemin à l'autre.";

// Niveau 1
"chapter5_l1_instruction" = "Un unique parchemin est déroulé devant toi. Fais-le défiler pour trouver le mot caché.";
"chapter5_l1_s1" = "La première ligne dit : 'En l'an du grand déluge...'";
"chapter5_l1_s2" = "'...les prêtres cachèrent leur trésor le plus sacré...'";
"chapter5_l1_s3" = "'...derrière la pierre marquée du symbole de...'";
"chapter5_l1_answer" = "LOTUS";
"chapter5_l1_h1" = "Fais défiler vers le bas pour lire la suite du parchemin.";
"chapter5_l1_h2" = "La réponse est le dernier mot du parchemin.";

// Niveau 2
"chapter5_l2_instruction" = "Trois parchemins sont posés devant toi. Navigue entre eux et fais défiler chacun pour trouver le mot de passe secret.";
"chapter5_l2_p1s1" = "Parchemin I — 'Le premier scribe a écrit sur les montagnes...'";
"chapter5_l2_p1s2" = "'...et les rivières qui coulent sous les pierres anciennes.'";
"chapter5_l2_p2s1" = "Parchemin II — 'Le second scribe parle d'un chemin caché...'";
"chapter5_l2_p2_answer" = "MOONGATE";
"chapter5_l2_p3s1" = "Parchemin III — 'Le troisième scribe avertit des faux passages...'";
"chapter5_l2_p3s2" = "'...ne te laisse pas tromper par la porte dorée.'";
"chapter5_l2_h1" = "Glisse vers la gauche ou la droite avec trois doigts pour naviguer entre les parchemins.";
```

- [ ] **Step 5: Ajouter les entrées L10n dans Strings.swift**

Dans `EscapeFromBlindness/Resources/Generated/Strings.swift`, dans l'enum `L10n`, ajouter avant la fonction `tr` finale :

```swift
  // MARK: - Chapter 5
  static let chapter5Description = L10n.tr("Localizable", "chapter5_description")
  static let chapter5L1Instruction = L10n.tr("Localizable", "chapter5_l1_instruction")
  static let chapter5L1S1 = L10n.tr("Localizable", "chapter5_l1_s1")
  static let chapter5L1S2 = L10n.tr("Localizable", "chapter5_l1_s2")
  static let chapter5L1S3 = L10n.tr("Localizable", "chapter5_l1_s3")
  static let chapter5L1Answer = L10n.tr("Localizable", "chapter5_l1_answer")
  static let chapter5L1H1 = L10n.tr("Localizable", "chapter5_l1_h1")
  static let chapter5L1H2 = L10n.tr("Localizable", "chapter5_l1_h2")
  static let chapter5L2Instruction = L10n.tr("Localizable", "chapter5_l2_instruction")
  static let chapter5L2P1S1 = L10n.tr("Localizable", "chapter5_l2_p1s1")
  static let chapter5L2P1S2 = L10n.tr("Localizable", "chapter5_l2_p1s2")
  static let chapter5L2P2S1 = L10n.tr("Localizable", "chapter5_l2_p2s1")
  static let chapter5L2P2Answer = L10n.tr("Localizable", "chapter5_l2_p2_answer")
  static let chapter5L2P3S1 = L10n.tr("Localizable", "chapter5_l2_p3s1")
  static let chapter5L2P3S2 = L10n.tr("Localizable", "chapter5_l2_p3s2")
  static let chapter5L2H1 = L10n.tr("Localizable", "chapter5_l2_h1")
```

- [ ] **Step 6: Ajouter le chapitre 5 dans LocalLevelFactory**

Dans `EscapeFromBlindness/Application/Factories/LocalLevelFactory.swift`, dans `static let chapters`, ajouter après le Chapter 4 (avant le `]` fermant) :

```swift
        ,Chapter(
            index: 5,
            title: "The Whispering Library",
            description: L10n.chapter5Description,
            keywords: ["parchments", "scrolls", "library", "ancient text", "lotus", "moongate"],
            levels: [
                SwipeGestureLevel(
                    instruction: L10n.chapter5L1Instruction,
                    swipeDirections: [.vertical],
                    pages: [[
                        L10n.chapter5L1S1,
                        L10n.chapter5L1S2,
                        L10n.chapter5L1S3,
                        L10n.chapter5L1Answer
                    ]],
                    validAnswer: L10n.chapter5L1Answer,
                    hints: [L10n.chapter5L1H1, L10n.chapter5L1H2]
                ),
                SwipeGestureLevel(
                    instruction: L10n.chapter5L2Instruction,
                    swipeDirections: [.vertical, .horizontal],
                    pages: [
                        [L10n.chapter5L2P1S1, L10n.chapter5L2P1S2],
                        [L10n.chapter5L2P2S1, L10n.chapter5L2P2Answer],
                        [L10n.chapter5L2P3S1, L10n.chapter5L2P3S2]
                    ],
                    validAnswer: L10n.chapter5L2P2Answer,
                    hints: [L10n.chapter5L2H1]
                )
            ]
        )
```

- [ ] **Step 7: Vérifier que les tests passent (green)**

```bash
xcodebuild test \
  -workspace EscapeFromBlindness.xcworkspace \
  -scheme EscapeFromBlindness \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  2>&1 | grep -E "(PASS|FAIL|error:)" | tail -20
```
Expected: `** TEST SUCCEEDED **`

- [ ] **Step 8: Committer**

```bash
git add \
  EscapeFromBlindness/Resources/en.lproj/Localizable.strings \
  EscapeFromBlindness/Resources/fr.lproj/Localizable.strings \
  EscapeFromBlindness/Resources/Generated/Strings.swift \
  EscapeFromBlindness/Application/Factories/LocalLevelFactory.swift \
  EscapeFromBlindnessTests/LocalLevelFactoryTests.swift
git commit -m "feat: add chapter 5 The Whispering Library with SwipeGestureLevel content"
```
