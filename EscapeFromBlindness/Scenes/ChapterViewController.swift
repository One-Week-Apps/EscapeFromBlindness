//
//  ChapterViewController.swift
//  EscapeFromBlindness
//
//  Created by Michael Martinez on 04/01/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

import UIKit

class ChapterViewController: UIViewController, Coordinated {
    var coordinator: AppCoordinatorProtocol?
    
    // MARK: Outlets
    var chapterLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.accessibilityTraits = .header
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFontMetrics.default.scaledFont(for: UIFont.custom(style: .montserratSemiBold, size: 16))
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    var continueButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(L10n.go, for: .normal)
        button.titleLabel?.font = UIFontMetrics.default.scaledFont(for: .custom(style: .montserratExtraBold, size: 40))
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        return button
    }()
    
    // MARK: Initialization
    private var chapter: Chapter? = nil
    
    convenience init(chapter: Chapter) {
        self.init()
        self.chapter = chapter
    }
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        
        let chapterTitle = presentChapterText(for: self.chapter)
        let chapterDescription = presentChapterDescription(for: self.chapter)
        self.chapterLabel.text = chapterTitle
        self.chapterLabel.accessibilityLabel = chapterTitle + "\n" + (chapterDescription ?? "")
        
        showVoiceOvertAlertIfNeeded()
    }
    
    // MARK: Actions
    @objc private func onContinueButtonTouched() {
        self.coordinator?.validateChapter()
    }
    
    // MARK: Private Methods
    private func setupView() {
        self.view.backgroundColor = .black
        
        self.view.addSubview(self.chapterLabel)
        self.view.addSubview(self.continueButton)
        
        self.chapterLabel.translatesAutoresizingMaskIntoConstraints = false
        self.chapterLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.chapterLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -50).isActive = true
        self.chapterLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 30).isActive = true
        
        self.continueButton.translatesAutoresizingMaskIntoConstraints = false
        self.continueButton.topAnchor.constraint(equalTo: self.chapterLabel.bottomAnchor, constant: 50).isActive = true
        // At least 100 pt, and grows with the text at large Dynamic Type sizes.
        let continueButtonMinimumSide: CGFloat = 100.0
        self.continueButton.widthAnchor.constraint(greaterThanOrEqualToConstant: continueButtonMinimumSide).isActive = true
        self.continueButton.heightAnchor.constraint(greaterThanOrEqualToConstant: continueButtonMinimumSide).isActive = true
        self.continueButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        
        self.continueButton.addTarget(self, action: #selector(onContinueButtonTouched), for: .touchUpInside)
    }
    
    private func presentChapterText(for chapter: Chapter?) -> String {
        guard let chapter = chapter else { return "\(L10n.chapter): " }
        
        var chapterText = "\(L10n.chapter) \(chapter.index): "
        if let title = chapter.title {
            chapterText += "\n" + title
        }
        return chapterText
    }
    
    private func presentChapterDescription(for chapter: Chapter?) -> String? {
        guard let chapter = chapter else { return nil }
        
        var chapterDescription: String? = nil
        if let description = chapter.chapterDescription {
            chapterDescription = description
        }
        return chapterDescription
    }
    
    private func showVoiceOvertAlertIfNeeded() {
        let isVoiceOverRunning = EscapeFromBlindnessAccessibility.shared.isVoiceOverRunning
        
        #if DEBUG
        // UI tests: the simulator runs without VoiceOver; keep the end-of-chapter screen visible for its capture.
        let isChapterCapture = ProcessInfo.processInfo.arguments.contains("-UITestChapter")
        #else
        let isChapterCapture = false
        #endif

        if !isVoiceOverRunning && !isChapterCapture {
            coordinator?.showActivateVoiceOverAlert()
        }
    }
    
}
