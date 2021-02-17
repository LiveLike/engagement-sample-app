//
//  CustomImgPredictionFollowUpWidgetVC.swift
//  Sample App
//
//  Created by Mike Moloksher on 1/12/21.
//  Copyright © 2021 LiveLike. All rights reserved.
//

import EngagementSDK
import Lottie
import UIKit

class CustomImgPredictionFollowUpWidgetVC: Widget, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let model: PredictionFollowUpWidgetModel

    private var widgetView: CustomWidgetOptionsView = CustomWidgetOptionsView()

    private var timer: Timer = Timer()

    private var selectedChoice: PredictionWidgetModel.Option?

    private var choices = [CustomImageOptionCell]()

    private var lottieView: AnimationView = AnimationView()

    // MARK: - Lifecycle

    override init(model: PredictionFollowUpWidgetModel) {
        self.model = model
        super.init(model: model)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // model.delegate = self

        widgetView = CustomWidgetOptionsView(title: model.question,
                                             widgetType: "Image Prediction Follow Up",
                                             optionAmount: model.options.count)
        widgetView.choicesCollectionView.delegate = self
        widgetView.choicesCollectionView.dataSource = self
        widgetView.widgetBarTimer.play(duration: model.interactionTimeInterval)

        timer = Timer.scheduledTimer(withTimeInterval: model.interactionTimeInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            // Notify presenter that the widget can be remove from view stack
            Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                self.delegate?.widgetDidEnterState(widget: self, state: .finished)
            }
        }

        model.registerImpression()
        view = widgetView
    }

    // MARK: - UI Helpers

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
        return model.options.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "myCell", for: indexPath) as? CustomImageOptionCell {
            cell.configure(option: model.options[indexPath.row])
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

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 15
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if model.options.count == indexPath.row + 1 {
            model.getVote { [weak self] result in
                guard let self = self else { return }

                switch result {
                case let .success(vote):

                    for cell in self.choices {
                        guard let option = self.model.options.first(where: { $0.id == cell.choiceID }) else { return }

                        let totalVoteCount = self.model.options.map { $0.voteCount }.reduce(0, +)
                        let voteCount = self.model.options.first(where: { $0.id == cell.choiceID })?.voteCount ?? 0
                        let votePercentage: CGFloat = totalVoteCount > 0 ? CGFloat(voteCount) / CGFloat(totalVoteCount) : 0

                        if option.id == vote.optionID {
                            cell.setMode(mode: .selected)
                        }
                        cell.setMode(mode: .showResults)

                        if option.isCorrect {
                            cell.setProgressAndColor(progress: votePercentage, color: CustomImageOptionCell.ProgressColors.green.color)
                            self.playOverlayAnimation(animationFilepath: self.theme.lottieFilepaths.win.first!, completion: nil)
                        } else {
                            cell.setProgress(progress: votePercentage)

                            if option.id == vote.optionID {
                                cell.setProgressAndColor(progress: votePercentage, color: CustomImageOptionCell.ProgressColors.red.color)
                                self.playOverlayAnimation(animationFilepath: self.theme.lottieFilepaths.lose.first!, completion: nil)
                            }
                        }
                    }

                case let .failure(error):
                    print(error)
                    self.delegate?.widgetStateCanComplete(widget: self, state: .results)
                }
            }
        }
    }
}

