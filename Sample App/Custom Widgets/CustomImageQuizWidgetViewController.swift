//
//  CustomImageQuizWidgetViewController.swift
//  Sample App
//
//  Created by Mike Moloksher on 1/12/21.
//  Copyright © 2021 LiveLike. All rights reserved.
//

import EngagementSDK
import Lottie
import UIKit

class CustomImageQuizWidgetViewController: Widget, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let model: QuizWidgetModel

    private var timer: Timer = Timer()

    private var selectedChoice: QuizWidgetModel.Choice?

    private var choices = [CustomImageOptionCell]()

    private var lottieView: AnimationView = AnimationView()

    private var widgetView: CustomWidgetOptionsView = CustomWidgetOptionsView()

    // MARK: - Lifecycle

    override init(model: QuizWidgetModel) {
        self.model = model
        super.init(model: model)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        model.delegate = self

        widgetView = CustomWidgetOptionsView(title: model.question,
                                             widgetType: "Image Quiz",
                                             optionAmount: model.choices.count)
        widgetView.choicesCollectionView.delegate = self
        widgetView.choicesCollectionView.dataSource = self
        widgetView.widgetBarTimer.play(duration: model.interactionTimeInterval)

        timer = Timer.scheduledTimer(withTimeInterval: model.interactionTimeInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if let selectedChoice = self.selectedChoice {
                self.model.lockInAnswer(choiceID: selectedChoice.id) { result in
                    switch result {
                    case .success:
                        self.widgetView.bodyView.isUserInteractionEnabled = false

                        // Optimistically start showing result graph
                        // from local data prior to the delegate data
                        self.showResultsFromWidgetOptions()
                    case let .failure(error):
                        print("Error: \(error)")
                    }
                }
            }

            // Notify presenter that the widget can be remove from view stack
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                self.delegate?.widgetDidEnterState(widget: self, state: .finished)
            }
        }
        model.registerImpression()
        view = widgetView
    }

    // MARK: - UI Helpers

    /// Shows stale data that already exists in the current objects
    private func showResultsFromWidgetOptions() {
        let quizResults = model.choices
        var totalVoteCount = model.totalAnswerCount

        for cell in choices {
            guard let optionData = self.model.choices.first(where: { $0.id == cell.choiceID }) else {
                return
            }

            var answerCount = quizResults.first(where: { $0.id == cell.choiceID })?.answerCount ?? 0
            if let selectedChoice = selectedChoice {
                if selectedChoice.id == cell.choiceID {
                    answerCount += 1
                    totalVoteCount += 1
                }
            }

            let votePercentage: CGFloat = totalVoteCount > 0 ? CGFloat(answerCount) / CGFloat(totalVoteCount) : 0

            cell.setMode(mode: .showResults)

            if optionData.isCorrect {
                cell.setProgress(progress: votePercentage, color: CustomImageOptionCell.ProgressColors.green.color)
            } else {
                cell.setProgress(progress: votePercentage)

                if cell.choiceID == selectedChoice?.id {
                    cell.setProgress(progress: votePercentage, color: CustomImageOptionCell.ProgressColors.red.color)
                }
            }
        }

        // Play win/lose animation
        if let selectedChoice = selectedChoice {
            let animationFilepath: String = {
                if selectedChoice.isCorrect {
                    return self.theme.lottieFilepaths.win.first!
                } else {
                    return self.theme.lottieFilepaths.lose.first!
                }
            }()

            playOverlayAnimation(animationFilepath: animationFilepath) {}
        }
    }

    /// Plays a Lottie animation
    private func playOverlayAnimation(animationFilepath: String, completion: (() -> Void)?) {
        lottieView = AnimationView(filePath: animationFilepath)
        lottieView.isUserInteractionEnabled = false
        lottieView.contentMode = .scaleAspectFit
        lottieView.backgroundBehavior = .pauseAndRestore
        lottieView.sizeToFit()
        lottieView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        view.clipsToBounds = false
        view.addSubview(lottieView)

        lottieView.play { finished in
            if finished {
                UIView.animate(withDuration: 0.33, animations: {
                    self.lottieView.alpha = 0.0
                }, completion: { _ in
                    self.lottieView.removeFromSuperview()
                    completion?()
                })
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.choices.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "myCell", for: indexPath) as? CustomImageOptionCell {
            cell.configure(choice: model.choices[indexPath.row])
            choices.append(cell)
            return cell
        } else {
            return UICollectionViewCell()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(
            width: (collectionView.frame.size.width / 2) - (15 / 2),
            height: 60
        )
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Reset all selected cells
        choices.forEach { $0.setMode(mode: .unselected) }

        // Mark a cell selected
        guard let pressedCell = collectionView.cellForItem(at: indexPath) as? CustomImageOptionCell else { return }
        pressedCell.setMode(mode: .selected)
        selectedChoice = model.choices.first(where: { $0.id == pressedCell.choiceID })
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 15
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}

extension CustomImageQuizWidgetViewController: QuizWidgetModelDelegate {
    func quizWidgetModel(_ model: QuizWidgetModel, answerCountDidChange answerCount: Int, forChoice choiceID: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Update vote counts and statistics on the screen
            guard let optionView = self.choices.first(where: { $0.choiceID == choiceID }) else { return }
            guard model.totalAnswerCount > 0 else { return }
            guard let selectedChoice = self.selectedChoice else {
                optionView.setMode(mode: .showResults)
                optionView.setProgress(progress: CGFloat(answerCount) / CGFloat(model.totalAnswerCount))
                return
            }

            if optionView.choiceID == selectedChoice.id {
                optionView.setMode(mode: .showResults)
                optionView.setProgress(progress: CGFloat(answerCount) / CGFloat(model.totalAnswerCount),
                                       color: selectedChoice.isCorrect ? CustomImageOptionCell.ProgressColors.green.color : CustomImageOptionCell.ProgressColors.red.color)
            } else {
                optionView.setMode(mode: .showResults)
                optionView.setProgress(progress: CGFloat(answerCount) / CGFloat(model.totalAnswerCount))
            }
        }
    }
}

