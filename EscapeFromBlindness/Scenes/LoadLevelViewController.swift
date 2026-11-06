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

    init(chapters: [Chapter], bundle: Bundle = Bundle(for: LoadLevelViewController.self)) {
        self.subtitle = LevelSelectionViewModel.localizedSubtitle(in: bundle)
        self.chapterCount = chapters.count
        self.levelCount = chapters.reduce(0) { $0 + $1.levels.count }
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
    private static let minimumColumns: CGFloat = 3
    /// Grille de 8 pt : côté des tuiles, écart entre tuiles, marge intérieure autour du numéro.
    private static let gridUnit: CGFloat = 8
    private static let spacing: CGFloat = 16
    private static let tilePadding: CGFloat = 8
    private static let preferredTileSide: CGFloat = 96
    private static let minimumTouchTarget: CGFloat = 44
    private static let sideMargin: CGFloat = 16
    private static let subtitleTopSpacing: CGFloat = 8
    private static let subtitleBottomSpacing: CGFloat = 16
    private static let titleLineHeightMultiple: CGFloat = 1.2
    private static let chapterTitleIdentifierPrefix = "levelSelection.chapterTitle."
    fileprivate static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "LevelSelection")

    private lazy var viewModel = LevelSelectionViewModel(chapters: chapters)

    static func titleFont(compatibleWith traitCollection: UITraitCollection? = nil) -> UIFont {
        return UIFontMetrics(forTextStyle: .title1).scaledFont(for: .custom(style: .lucioleBold, size: 28), compatibleWith: traitCollection)
    }

    var subtitle: String {
        return viewModel.subtitle
    }

    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = LoadLevelViewController.titleFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.accessibilityTraits.insert(.header)
        label.accessibilityIdentifier = "levelSelectionSubtitle"
        return label
    }()

    var collectionView: UICollectionView = {
        let flowLayout = LoadLevelGridLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumInteritemSpacing = spacing
        flowLayout.minimumLineSpacing = spacing
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: spacing, right: 0)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .black
        return collectionView
    }()
    
    convenience init(chapters: [Chapter], currentChapterIndex: Int, currentLevelIndex: Int) {
        self.init()
        self.chapters = chapters
        self.currentChapterIndex = currentChapterIndex
        self.currentLevelIndex = currentLevelIndex
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubtitle()
        setupCollectionView()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            // Les en-têtes portent des polices calculées pour la taille de texte : on les reconstruit.
            collectionView.reloadData()
            collectionView.collectionViewLayout.invalidateLayout()
        }
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
        // Le point des « i » de Luciole Bold dépasse la hauteur de ligne déclarée par la fonte : sans marge, il est coupé.
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = LoadLevelViewController.titleLineHeightMultiple
        self.subtitleLabel.attributedText = NSAttributedString(string: self.subtitle, attributes: [.paragraphStyle: paragraph])
        // Texte attribué : VoiceOver lit le sous-titre tel quel, comme un en-tête.
        self.subtitleLabel.isAccessibilityElement = true
        self.subtitleLabel.accessibilityLabel = self.subtitle

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
        self.collectionView.register(LoadLevelCollectionViewCell.self)
        
        self.view.backgroundColor = .black
        self.view.addSubview(self.collectionView)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        let safeArea = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            self.collectionView.topAnchor.constraint(equalTo: self.subtitleLabel.bottomAnchor, constant: LoadLevelViewController.subtitleBottomSpacing),
            self.collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.collectionView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: LoadLevelViewController.sideMargin),
            self.collectionView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -LoadLevelViewController.sideMargin)
        ])
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
        let maxLevelCount = self.chapters.map(\.levels.count).max() ?? 1
        let minimumSide = LoadLevelViewController.minimumTileSide(maxLevelCount: maxLevelCount, traitCollection: self.traitCollection)
        let side = LoadLevelViewController.tileSide(forWidth: collectionView.bounds.width, minimumSide: minimumSide)
        return CGSize(width: side, height: side)
    }

    /// Plus petit côté où le numéro le plus long tient sur une ligne, à la taille de texte choisie, sans passer sous 44 pt.
    static func minimumTileSide(maxLevelCount: Int, traitCollection: UITraitCollection) -> CGFloat {
        let font = LoadLevelCollectionViewCell.levelFont(compatibleWith: traitCollection)
        let widestNumber = String(repeating: "0", count: String(max(maxLevelCount, 1)).count) as NSString
        let text = widestNumber.size(withAttributes: [.font: font])
        let side = max(text.width, font.lineHeight) + 2 * tilePadding
        return ceil(max(minimumTouchTarget, side) / gridUnit) * gridUnit
    }

    /// Côté commun à toutes les tuiles : autant de colonnes que la largeur en permet (au moins trois),
    /// moins si le texte agrandi ne tiendrait plus. Les colonnes remplissent la largeur : marges gauche et droite identiques.
    static func tileSide(forWidth width: CGFloat, minimumSide: CGFloat) -> CGFloat {
        guard width > 0 else { return minimumSide }
        func side(_ columns: CGFloat) -> CGFloat {
            // Arrondi au demi-point inférieur : le rang tient toujours, sans reste visible à droite.
            return floor((width - spacing * (columns - 1)) / columns * 2) / 2
        }
        var columns = max(minimumColumns, floor((width + spacing) / (preferredTileSide + spacing)))
        while columns > 1 && side(columns) < minimumSide {
            columns -= 1
        }
        return min(width, max(side(columns), minimumSide))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let width = collectionView.bounds.width
        let chapter = self.chapters[section]
        let height = LoadLevelCollectionViewCellHeader.height(number: chapterNumber(chapter), name: chapter.title ?? "", width: width, traitCollection: self.traitCollection)
        return CGSize(width: width, height: height)
    }

    /// « Chapitre 1 », espace insécable : le numéro ne se détache jamais du mot.
    private func chapterNumber(_ chapter: Chapter) -> String {
        return L10n.chapterNumber(chapter.index)
    }

    /// Libellé lu par VoiceOver en un seul élément : « Chapitre 1, Nom ».
    private func chapterHeading(_ chapter: Chapter) -> String {
        return L10n.chapterHeading(chapter.index, chapter.title ?? "")
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
            if chapter.title == nil {
                LoadLevelViewController.logger.error("Chapter \(chapter.index) has no title: its header shows the number only")
            }
            header.configure(number: chapterNumber(chapter), name: chapter.title ?? "", accessibilityLabel: chapterHeading(chapter))
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
