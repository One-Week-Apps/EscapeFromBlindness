protocol Router {
    func routeToChapter(_ chapter: Chapter, isNewChapter: Bool)
    func routeToLevel(_ level: Level)
    func routeToResults()
    func routeToWrongAnswer()
}

protocol GameFlowProtocol {
    func getCurrentChapterIndex() -> Int
    func getChapters() -> [Chapter]
    func getTitleForChapter(chapterIndex: Int?) -> String?
    func getCurrentLevelIndex(levelIndex: Int?) -> Int
    func start()
    func loadLevel(_ chapterIndex: Int, _ levelIndex: Int)
    func replayFromStart()
    func validate(_ answers: [Level.Answer])
    func validateChapter()
}

extension GameFlowProtocol {
    func getTitleForChapter(chapterIndex: Int? = nil) -> String? {
        self.getTitleForChapter(chapterIndex: chapterIndex)
    }
    
    func getCurrentLevelIndex(levelIndex: Int? = nil) -> Int {
        self.getCurrentLevelIndex(levelIndex: levelIndex)
    }
}

class GameFlow: GameFlowProtocol {
    private let chapters: [Chapter]
    private var currentChapterIndex: Int
    private var currentLevelIndex: Int
    
    func getChapters() -> [Chapter] {
        return self.chapters
    }
    
    private var currentChapter: Chapter? {
        return self.chapters[safe: max(0, self.currentChapterIndex - 1)]
    }
    private var currentLevel: Level? {
        return self.currentChapter?.levels[safe: self.currentLevelIndex]
    }

    /// Already solved level the player replays from the menu, without changing their progress.
    /// The chapter index follows the same convention as `currentChapterIndex` (starts at 1).
    private var replayPosition: (chapterIndex: Int, levelIndex: Int)?

    private var playedLevel: Level? {
        guard let replayPosition = self.replayPosition else { return self.currentLevel }
        return self.chapters[safe: replayPosition.chapterIndex - 1]?.levels[safe: replayPosition.levelIndex]
    }
    
    var router: Router?
    
    init(chapters: [Chapter], currentChapterIndex: Int, currentLevelIndex: Int) {
        self.chapters = chapters
        self.currentChapterIndex = currentChapterIndex
        self.currentLevelIndex = currentLevelIndex
    }
    
    func getCurrentChapterIndex() -> Int {
        return self.currentChapterIndex
    }
    
    func getTitleForChapter(chapterIndex: Int? = nil) -> String? {
        return chapterIndex == nil ? self.currentChapter?.title : self.chapters[safe: chapterIndex!]?.title
    }
    
    func getCurrentLevelIndex(levelIndex: Int? = nil) -> Int {
        return levelIndex == nil ? self.currentLevelIndex : levelIndex!
    }
    
    func start() {
        if let currentChapter = self.currentChapter {
            router?.routeToChapter(currentChapter, isNewChapter: false)
        }
    }
    
    func loadLevel(_ chapterIndex: Int, _ levelIndex: Int) {
        if let chapter = self.chapters[safe: chapterIndex], let level = chapter.levels[safe: levelIndex] {
            replay(chapterIndex: chapterIndex + 1, levelIndex: levelIndex)
            router?.routeToLevel(level)
        }
    }
    
    /// Plays the game again from chapter 1 without losing the progress: every level stays completed.
    func replayFromStart() {
        guard let firstChapter = self.chapters.first else { return }
        replay(chapterIndex: 1, levelIndex: 0)
        router?.routeToChapter(firstChapter, isNewChapter: false)
    }

    private func replay(chapterIndex: Int, levelIndex: Int) {
        let isCurrentProgress = chapterIndex == self.currentChapterIndex && levelIndex == self.currentLevelIndex
        self.replayPosition = isCurrentProgress ? nil : (chapterIndex, levelIndex)
    }
    
    func validate(_ answers: [Level.Answer]) {
        guard let level = self.playedLevel, level.isSolved(by: answers) else {
            router?.routeToWrongAnswer()
            return
        }

        if let replayPosition = self.replayPosition {
            advanceReplay(from: replayPosition)
        } else {
            advanceProgress()
        }
    }

    private func advanceReplay(from position: (chapterIndex: Int, levelIndex: Int)) {
        let levelsCount = self.chapters[safe: position.chapterIndex - 1]?.levels.count ?? 0

        if position.levelIndex + 1 < levelsCount {
            replay(chapterIndex: position.chapterIndex, levelIndex: position.levelIndex + 1)
            if let level = self.playedLevel {
                router?.routeToLevel(level)
            }
        } else if let nextChapter = self.chapters[safe: position.chapterIndex] {
            replay(chapterIndex: position.chapterIndex + 1, levelIndex: 0)
            router?.routeToChapter(nextChapter, isNewChapter: false)
        } else {
            self.replayPosition = nil
            router?.routeToResults()
        }
    }

    private func advanceProgress() {
        self.currentLevelIndex += 1

        if hasReachedNewChapter() {
            self.currentChapterIndex += 1
            let levelIndexSwap = self.currentLevelIndex
            self.currentLevelIndex = 0

            if let chapter = self.currentChapter {
                router?.routeToChapter(chapter, isNewChapter: true)
            } else {
                self.currentChapterIndex -= 1
                self.currentLevelIndex = levelIndexSwap
                router?.routeToResults()
            }
        } else if let level = self.currentLevel {
            router?.routeToLevel(level)
        }
    }

    private func hasReachedNewChapter() -> Bool {
        if let currentChapter = self.currentChapter {
            return self.currentLevelIndex >= currentChapter.levels.count
        } else {
            return false
        }
    }
    
    func validateChapter() {
        guard currentChapterIndex > 0 else {
            self.currentChapterIndex += 1
            guard let currentChapter = currentChapter else { return }
            router?.routeToChapter(currentChapter, isNewChapter: true)
            return
        }
        
        if let level = self.playedLevel {
            router?.routeToLevel(level)
        }
    }
    
}
