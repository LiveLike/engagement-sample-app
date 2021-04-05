import EngagementSDK
import UIKit

class CustomCheerMeterWidgetViewController: Widget {
    private let model: CheerMeterWidgetModel

    private var cheerMeterWidgetView: CustomCheerMeterWidgetView!

    let timer: CustomWidgetBarTimer = {
        let timer = CustomWidgetBarTimer()
        timer.translatesAutoresizingMaskIntoConstraints = false
        return timer
    }()

    let winnerView: CustomCheerMeterWinnerView = {
        let winnerView = CustomCheerMeterWinnerView()
        winnerView.translatesAutoresizingMaskIntoConstraints = false
        winnerView.isHidden = true
        return winnerView
    }()

    override init(model: CheerMeterWidgetModel) {
        self.model = model
        super.init(model: model)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let cheerMeterView = CustomCheerMeterWidgetView()

        cheerMeterView.titleLabel.text = model.title

        cheerMeterView.optionLabelA.text = model.options[0].text
        cheerMeterView.optionViewA.button.addTarget(self, action: #selector(optionViewASelected), for: .touchUpInside)
        cheerMeterView.optionViewA.progressBar.backgroundColor = UIColor(red: 0/255, green: 150/255, blue: 255/255, alpha: 1.0)
        do {
            let imageData = try Data(contentsOf: model.options[0].imageURL)
            cheerMeterView.optionViewA.imageView.image = UIImage(data: imageData)
        } catch {
            print(error)
        }

        cheerMeterView.optionLabelB.text = model.options[1].text
        cheerMeterView.optionViewB.button.addTarget(self, action: #selector(optionViewBSelected), for: .touchUpInside)
        cheerMeterView.optionViewB.progressBar.backgroundColor = UIColor(red: 237/255, green: 23/255, blue: 75/255, alpha: 1.0)
        do {
            let imageData = try Data(contentsOf: model.options[1].imageURL)
            cheerMeterView.optionViewB.imageView.image = UIImage(data: imageData)
        } catch {
            print(error)
        }

        cheerMeterView.addSubview(timer)
        timer.bottomAnchor.constraint(equalTo: cheerMeterView.topAnchor).isActive = true
        timer.leadingAnchor.constraint(equalTo: cheerMeterView.leadingAnchor).isActive = true
        timer.trailingAnchor.constraint(equalTo: cheerMeterView.trailingAnchor).isActive = true
        timer.heightAnchor.constraint(equalToConstant: 5).isActive = true

        cheerMeterView.addSubview(winnerView)
        NSLayoutConstraint.activate([
            winnerView.topAnchor.constraint(equalTo: cheerMeterView.topAnchor),
            winnerView.leadingAnchor.constraint(equalTo: cheerMeterView.leadingAnchor),
            winnerView.trailingAnchor.constraint(equalTo: cheerMeterView.trailingAnchor),
            winnerView.bottomAnchor.constraint(equalTo: cheerMeterView.bottomAnchor)
        ])
        cheerMeterWidgetView = cheerMeterView

        view = cheerMeterView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        model.delegate = self
        cheerMeterWidgetView.versusAnimationView.play()
        timer.play(duration: model.interactionTimeInterval)
        DispatchQueue.main.asyncAfter(deadline: .now() + model.interactionTimeInterval) {
            let winnerImage = self.model.options[0].voteCount >= self.model.options[1].voteCount ? self.cheerMeterWidgetView.optionViewA.imageView.image : self.cheerMeterWidgetView.optionViewB.imageView.image

            self.winnerView.winnerImageView.image = winnerImage
            self.winnerView.winnerAnimationView.play()
            UIView.animate(withDuration: 1.0) {
                self.cheerMeterWidgetView.bodyView.alpha = 0.3
                self.winnerView.isHidden = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                self.delegate?.widgetDidEnterState(widget: self, state: .finished)
            }
        }
        model.markAsInteractive()
        model.registerImpression()
    }

    @objc func optionViewASelected() {
        model.submitVote(optionID: model.options[0].id)
    }

    @objc func optionViewBSelected() {
        model.submitVote(optionID: model.options[1].id)
    }
}

extension CustomCheerMeterWidgetViewController: CheerMeterWidgetModelDelegate {
    func cheerMeterWidgetModel(
        _ model: CheerMeterWidgetModel,
        voteCountDidChange voteCount: Int,
        forOption optionID: String
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let totalVotes = model.options.map { $0.voteCount }.reduce(0, +)
            let votePercentage = totalVotes > 0 ? CGFloat(voteCount) / CGFloat(totalVotes) : 0
            if optionID == model.options[0].id {
                self.cheerMeterWidgetView.optionViewA.updateProgress(percent: votePercentage)
            } else if optionID == model.options[1].id {
                self.cheerMeterWidgetView.optionViewB.updateProgress(percent: votePercentage)
            }
        }
    }

    func cheerMeterWidgetModel(_ model: CheerMeterWidgetModel, voteRequest: CheerMeterWidgetModel.VoteRequest, didComplete result: Result<CheerMeterWidgetModel.Vote, Error>) {}
}
