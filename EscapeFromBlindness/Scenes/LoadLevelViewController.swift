//
//  Created by Michael Martinez on 21/04/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import UIKit
import os

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
    private static let subtitleKey = "level_selection_subtitle"
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "LevelSelection")

    var subtitle: String {
        return L10n.levelSelectionSubtitle
    }

    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .custom(style: .lucioleRegular, size: 17))
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.accessibilityTraits.insert(.header)
        label.accessibilityIdentifier = "levelSelectionSubtitle"
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
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.headerReferenceSize = CGSize(width: collectionView.bounds.width, height: 80)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        LoadLevelViewController.logger.debug("Level selection displayed, subtitle shown")
        let indexPath = IndexPath(item: self.currentLevelIndex, section: self.currentChapterIndex - 1)
        if isRunningTest {
            EscapeFromBlindnessAccessibility.shared.post(notification: .layoutChanged, argument: self.collectionView.cellForItem(at: indexPath))
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
                EscapeFromBlindnessAccessibility.shared.post(notification: .layoutChanged, argument: self.collectionView.cellForItem(at: indexPath))
            }
        }
    }
    
    private func setupSubtitle() {
        let key = LoadLevelViewController.subtitleKey
        if Bundle(for: LoadLevelViewController.self).localizedString(forKey: key, value: nil, table: "Localizable") == key {
            LoadLevelViewController.logger.error("Missing localization for key \(key, privacy: .public)")
        }
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
