import EngagementSDK
import UIKit

class CheerMeterWidgetResultsViewController: UIViewController {
    let model: CheerMeterWidgetModel

    var cheerMeterView: CustomCheerMeterWidgetView = {
        let cheerMeterView = CustomCheerMeterWidgetView()
        cheerMeterView.translatesAutoresizingMaskIntoConstraints = false
        return cheerMeterView
    }()

    let winnerView: CustomCheerMeterWinnerView = {
        let winnerView = CustomCheerMeterWinnerView()
        winnerView.translatesAutoresizingMaskIntoConstraints = false
        return winnerView
    }()

    init(model: CheerMeterWidgetModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cheerMeterView.titleLabel.text = model.title
        cheerMeterView.optionLabelA.text = model.options[0].text
        WidgetViewHelpers.setImage(model.options[0].imageURL, on: cheerMeterView.optionViewA.imageView)

        cheerMeterView.optionLabelB.text = model.options[1].text
        WidgetViewHelpers.setImage(model.options[1].imageURL, on: cheerMeterView.optionViewB.imageView)

        view.addSubview(cheerMeterView)
        NSLayoutConstraint.activate([
            cheerMeterView.topAnchor.constraint(equalTo: view.topAnchor),
            cheerMeterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cheerMeterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cheerMeterView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        view.addSubview(winnerView)
        NSLayoutConstraint.activate([
            winnerView.topAnchor.constraint(equalTo: view.topAnchor),
            winnerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            winnerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            winnerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        cheerMeterView.alpha = 0.2

        DispatchQueue.main.async {
            let totalVotes = self.model.options.map { $0.voteCount }.reduce(0, +)
            let optionAVotePercentage = totalVotes > 0 ? CGFloat(self.model.options[0].voteCount) / CGFloat(totalVotes) : 0
            let optionBVotePercentage = totalVotes > 0 ? CGFloat(self.model.options[1].voteCount) / CGFloat(totalVotes) : 0

            self.cheerMeterView.optionViewA.updateProgress(percent: optionAVotePercentage)
            self.cheerMeterView.optionViewB.updateProgress(percent: optionBVotePercentage)

            let winnerImageURL =
                self.model.options[0].voteCount >= self.model.options[1].voteCount ?
                self.model.options[0].imageURL :
                self.model.options[1].imageURL

            WidgetViewHelpers.setImage(winnerImageURL, on: self.winnerView.winnerImageView)
            self.winnerView.winnerAnimationView.play()
        }

        model.registerImpression()
    }
}
