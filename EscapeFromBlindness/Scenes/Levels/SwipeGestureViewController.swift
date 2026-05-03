//
//  Created by Michael Martinez on 04/01/2020.
//  Copyright © 2020 michael-martinez. All rights reserved.
//

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
    private var pageButtons: [[UIButton]] = []

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
        pageButtons = []

        if level.swipeDirections.contains(.horizontal) {
            buildHorizontalContent()
        } else {
            buildVerticalContent()
        }
    }

    private func buildVerticalContent() {
        let contentGuide = scrollView.contentLayoutGuide
        let frameGuide = scrollView.frameLayoutGuide

        guard let page = level.pages.first else { return }
        var previousAnchor = contentGuide.topAnchor

        for (index, text) in page.enumerated() {
            let button = makeButton(text: text)
            button.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(button)

            button.topAnchor.constraint(equalTo: previousAnchor, constant: 20).isActive = true
            button.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor, constant: 30).isActive = true
            button.widthAnchor.constraint(equalTo: frameGuide.widthAnchor, constant: -60).isActive = true

            if index == page.count - 1 {
                button.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor, constant: -20).isActive = true
            }

            previousAnchor = button.bottomAnchor
        }
    }

    private func buildHorizontalContent() {
        for page in level.pages {
            var buttons: [UIButton] = []
            for text in page {
                let button = makeButton(text: text)
                button.translatesAutoresizingMaskIntoConstraints = true
                scrollView.addSubview(button)
                buttons.append(button)
            }
            pageButtons.append(buttons)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if level.swipeDirections.contains(.horizontal) {
            layoutHorizontalContent()
        }
    }

    private func layoutHorizontalContent() {
        let pageWidth = scrollView.frame.width
        let pageHeight = scrollView.frame.height
        guard pageWidth > 0 else { return }

        scrollView.contentSize = CGSize(
            width: pageWidth * CGFloat(level.pages.count),
            height: pageHeight
        )

        for (pageIndex, buttons) in pageButtons.enumerated() {
            let sectionHeight: CGFloat = 44
            let spacing: CGFloat = 10
            var y: CGFloat = 20

            for button in buttons {
                button.frame = CGRect(
                    x: CGFloat(pageIndex) * pageWidth + 30,
                    y: y,
                    width: pageWidth - 60,
                    height: sectionHeight
                )
                y += sectionHeight + spacing
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
