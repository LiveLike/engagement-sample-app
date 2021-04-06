import EngagementSDK
import UIKit

class ImageQuizWidgetResultsViewController: Widget, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let model: QuizWidgetModel

    private var widgetView: CustomWidgetOptionsView!

    // MARK: - Lifecycle

    override init(model: QuizWidgetModel) {
        self.model = model
        super.init(model: model)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        widgetView = CustomWidgetOptionsView(
            title: model.question,
            widgetType: "Image Quiz",
            optionAmount: model.choices.count
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
        return model.choices.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "myCell", for: indexPath) as? CustomImageOptionCell {
            let choice = model.choices[indexPath.row]
            cell.configure(choice: choice)
            cell.setMode(mode: .showResults)
            let progress = model.totalAnswerCount > 0 ? CGFloat(choice.answerCount) / CGFloat(model.totalAnswerCount) : 0

            if choice.isCorrect {
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
