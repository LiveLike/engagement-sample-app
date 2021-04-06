import EngagementSDK
import UIKit

class ImagePredictionFollowUpResultsViewController: Widget, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let model: PredictionFollowUpWidgetModel

    private var widgetView: CustomWidgetOptionsView!

    // MARK: - Lifecycle

    override init(model: PredictionFollowUpWidgetModel) {
        self.model = model
        super.init(model: model)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        widgetView = CustomWidgetOptionsView(
            title: model.question,
            widgetType: "Image Prediction",
            optionAmount: model.options.count
        )

        view = widgetView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        widgetView.choicesCollectionView.delegate = self
        widgetView.choicesCollectionView.dataSource = self
        model.registerImpression()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.options.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "myCell", for: indexPath) as? CustomImageOptionCell {
            let option = model.options[indexPath.row]
            cell.configure(option: option)
            cell.setMode(mode: .showResults)
            let totalVoteCount = model.options.map { $0.voteCount }.reduce(0, +)
            let progress = totalVoteCount > 0 ? CGFloat(option.voteCount) / CGFloat(totalVoteCount) : 0
            if option.isCorrect {
                cell.setProgressAndColor(
                    progress: progress,
                    color: WidgetViewHelpers.colors.green
                )
            } else {
                cell.setProgressAndColor(
                    progress: progress,
                    color: WidgetViewHelpers.colors.gray
                )
            }
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
}
