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
