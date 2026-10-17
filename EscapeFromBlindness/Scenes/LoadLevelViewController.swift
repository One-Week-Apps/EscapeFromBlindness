//
//  Created by Michael Martinez on 21/04/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import UIKit
import os

/// Libellés de l'écran de sélection des niveaux. Ne dépend ni de l'appareil ni de la taille de l'écran.
struct LevelSelectionViewModel {
    static let subtitleKey = "level_selection_subtitle"
    static let subtitleFallback = "Choisis ton niveau"

    let subtitle: String
    let chapterCount: Int
    let levelCount: Int
    /// « Version – » quand la version est introuvable.
    let versionText: String
    let versionAccessibilityText: String

    init(chapters: [Chapter],
         bundle: Bundle = Bundle(for: LoadLevelViewController.self),
         infoDictionary: [String: Any]? = Bundle.main.infoDictionary) {
        self.subtitle = LevelSelectionViewModel.localizedSubtitle(in: bundle)
        self.chapterCount = chapters.count
        self.levelCount = chapters.reduce(0) { $0 + $1.levels.count }
        let appVersion = AppVersion.from(infoDictionary: infoDictionary)
        self.versionText = appVersion?.displayText ?? AppVersion.fallbackText
        self.versionAccessibilityText = appVersion?.accessibilityText ?? AppVersion.fallbackText
    }

    private static func localizedSubtitle(in bundle: Bundle) -> String {
        let key = subtitleKey
        guard bundle.localizedString(forKey: key, value: nil, table: "Localizable") != key else {
            let language = bundle.preferredLocalizations.first ?? Locale.current.identifier
            LoadLevelViewController.logger.error("Missing translation for key \(key, privacy: .public) in language \(language, privacy: .public)")
            return subtitleFallback
        }
        return L10n.levelSelectionSubtitle
    }
}

class LoadLevelViewController: UIViewController, Coordinated {
    var coordinator: AppCoordinatorProtocol?
    private var chapters: [Chapter] = []
    private var currentChapterIndex: Int = 0
    private var currentLevelIndex: Int = 0
    private static let headerReuseId = "header"
    private static let columns: CGFloat = 3
    private static let spacing: CGFloat = 20
    private static let maxTileSide: CGFloat = 100
    private static let sideMargin: CGFloat = 16
    private static let subtitleTopSpacing: CGFloat = 8
    private static let subtitleBottomSpacing: CGFloat = 16
    private static let versionSpacing: CGFloat = 8
    private static let chapterTitleIdentifierPrefix = "levelSelection.chapterTitle."
    fileprivate static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "LevelSelection")
    private static let homeLogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Accueil")

    private var infoDictionary: [String: Any]? = Bundle.main.infoDictionary
    private lazy var viewModel = LevelSelectionViewModel(chapters: chapters, infoDictionary: infoDictionary)

    var subtitle: String {
        return viewModel.subtitle
    }

    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .custom(style: .lucioleRegular, size: 17))
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.accessibilityTraits.insert(.header)
        label.accessibilityIdentifier = "levelSelectionSubtitle"
        return label
    }()

    let versionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        // Le fond de l'accueil reste noir quel que soit le mode : on résout `secondaryLabel` dans sa variante sombre pour garder un contraste ≥ 4,5:1.
        label.overrideUserInterfaceStyle = .dark
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.isUserInteractionEnabled = false
        label.accessibilityTraits = .staticText
        label.accessibilityIdentifier = "homeVersionLabel"
        return label
    }()

    var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.minimumLineSpacing = spacing
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: spacing, right: 0)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .black
        return collectionView
    }()
    
    convenience init(chapters: [Chapter],
                     currentChapterIndex: Int,
                     currentLevelIndex: Int,
                     infoDictionary: [String: Any]? = Bundle.main.infoDictionary) {
        self.init()
        self.chapters = chapters
        self.currentChapterIndex = currentChapterIndex
        self.currentLevelIndex = currentLevelIndex
        self.infoDictionary = infoDictionary
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubtitle()
        setupCollectionView()
        setupVersionLabel()
        logVersion()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.headerReferenceSize = CGSize(width: collectionView.bounds.width, height: 80)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        LoadLevelViewController.logger.debug("Level selection displayed with \(self.viewModel.chapterCount) chapters and \(self.viewModel.levelCount) levels")
        let indexPath = IndexPath(item: self.currentLevelIndex, section: self.currentChapterIndex - 1)
        if isRunningTest {
            EscapeFromBlindnessAccessibility.shared.post(notification: .layoutChanged, argument: self.collectionView.cellForItem(at: indexPath))
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.scrollToCurrentLevel(at: indexPath)
                EscapeFromBlindnessAccessibility.shared.post(notification: .layoutChanged, argument: self.collectionView.cellForItem(at: indexPath))
            }
        }
    }
    
    /// Fait défiler jusqu'au niveau courant en gardant le titre de son chapitre au-dessus, quand les deux tiennent à l'écran.
    private func scrollToCurrentLevel(at indexPath: IndexPath) {
        guard self.chapters.indices.contains(indexPath.section),
              self.chapters[indexPath.section].levels.indices.contains(indexPath.item) else {
            LoadLevelViewController.logger.error("Cannot scroll to level \(indexPath.item) in section \(indexPath.section): out of range")
            return
        }
        let layout = self.collectionView.collectionViewLayout
        guard let item = layout.layoutAttributesForItem(at: indexPath) else { return }
        let header = layout.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: indexPath.section))

        let insets = self.collectionView.adjustedContentInset
        let visibleHeight = self.collectionView.bounds.height - insets.top - insets.bottom
        var targetY = item.frame.minY
        if let header = header, item.frame.maxY - header.frame.minY <= visibleHeight {
            targetY = header.frame.minY
        }
        let minOffsetY = -insets.top
        let maxOffsetY = max(minOffsetY, self.collectionView.contentSize.height + insets.bottom - self.collectionView.bounds.height)
        let offsetY = min(max(targetY - insets.top, minOffsetY), maxOffsetY)
        self.collectionView.setContentOffset(CGPoint(x: self.collectionView.contentOffset.x, y: offsetY), animated: true)
    }

    private func setupSubtitle() {
        self.subtitleLabel.text = self.subtitle

        self.view.addSubview(self.subtitleLabel)
        self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        let safeArea = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            self.subtitleLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: LoadLevelViewController.subtitleTopSpacing),
            self.subtitleLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: LoadLevelViewController.sideMargin),
            self.subtitleLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -LoadLevelViewController.sideMargin)
        ])
    }

    private func setupCollectionView() {
        self.collectionView.register(LoadLevelCollectionViewCellHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: LoadLevelViewController.headerReuseId)
        self.collectionView.dataSource = self
        self.collectionView.delegate = self

        self.view.backgroundColor = .black
        self.view.addSubview(self.collectionView)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        let safeArea = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            self.collectionView.topAnchor.constraint(equalTo: self.subtitleLabel.bottomAnchor, constant: LoadLevelViewController.subtitleBottomSpacing),
            self.collectionView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: LoadLevelViewController.sideMargin),
            self.collectionView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -LoadLevelViewController.sideMargin)
        ])
    }

    /// Ajouté en dernier : VoiceOver lit la version après la grille, sans changer l'ordre existant.
    private func setupVersionLabel() {
        self.versionLabel.text = viewModel.versionText
        self.versionLabel.accessibilityLabel = viewModel.versionAccessibilityText

        self.view.addSubview(self.versionLabel)
        self.versionLabel.translatesAutoresizingMaskIntoConstraints = false
        let safeArea = self.view.safeAreaLayoutGuide
        let spacing = LoadLevelViewController.versionSpacing
        NSLayoutConstraint.activate([
            // La grille s'arrête au-dessus de la version : aucune case n'est recouverte.
            self.collectionView.bottomAnchor.constraint(equalTo: self.versionLabel.topAnchor, constant: -spacing),
            self.versionLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: LoadLevelViewController.sideMargin),
            self.versionLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -LoadLevelViewController.sideMargin),
            self.versionLabel.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -spacing)
        ])
    }

    private func logVersion() {
        for key in AppVersion.missingKeys(in: infoDictionary) {
            LoadLevelViewController.homeLogger.error("Clé \(key, privacy: .public) absente ou vide dans Info.plist, repli d'affichage appliqué")
        }
        LoadLevelViewController.homeLogger.debug("Version affichée : \(self.viewModel.versionText, privacy: .public)")
    }

}

extension LoadLevelViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.chapters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.chapters[section].levels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns = LoadLevelViewController.columns
        let available = collectionView.bounds.width - LoadLevelViewController.spacing * (columns - 1)
        let side = min(LoadLevelViewController.maxTileSide, floor(available / columns))
        return CGSize(width: side, height: side)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: LoadLevelViewController.headerReuseId,
                for: indexPath
            ) as! LoadLevelCollectionViewCellHeader
            
            let chapter = self.chapters[indexPath.section]
            header.titleLabel.text = "\(L10n.chapter) \(chapter.index): \(chapter.title ?? "")"
            header.titleLabel.textColor = .white
            header.titleLabel.font = .custom(style: .montserratExtraBold, size: 20.0)
            header.titleLabel.accessibilityTraits = .header
            header.titleLabel.accessibilityIdentifier = "\(LoadLevelViewController.chapterTitleIdentifierPrefix)\(chapter.index)"
            header.setNeedsLayout()
            return header
        default:
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: LoadLevelCollectionViewCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
        
        let candidateChapterIndex = indexPath.section
        let candidateLevelIndex = indexPath.item
        let state = getLevelState(candidateChapterIndex, candidateLevelIndex)
        
        cell.configure(chapterIndex: indexPath.section, levelIndex: indexPath.row, state: state)
        return cell
    }
    
    private func getLevelState(_ candidateChapterIndex: Int, _ candidateLevelIndex: Int) -> LoadLevelCollectionViewCell.State {
        let state: LoadLevelCollectionViewCell.State
        if candidateChapterIndex < (currentChapterIndex - 1) {
            state = .completed
        } else if candidateChapterIndex > (currentChapterIndex - 1) {
            state = .locked
        } else {
            if candidateLevelIndex < currentLevelIndex {
                state = .completed
            } else if candidateLevelIndex > currentLevelIndex {
                state = .locked
            } else {
                state = .unlocked
            }
        }
        return state
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let chapterIndex = indexPath.section
        let levelIndex = indexPath.item
        
        if getLevelState(chapterIndex, levelIndex) != .locked {
            coordinator?.loadLevel(chapterIndex, levelIndex: levelIndex)
        }
    }
    
}
