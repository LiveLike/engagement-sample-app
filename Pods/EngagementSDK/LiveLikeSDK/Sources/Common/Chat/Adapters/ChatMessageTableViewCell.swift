//
//  ChatMessageTableViewCell.swift
//  EngagementSDK
//
//  Created by Mike Moloksher on 10/26/20.
//

import UIKit

class ChatMessageTableViewCell: UITableViewCell, Selectable {

    var selectableView: SelectableView!
    private weak var messageViewModel: MessageViewModel?
    weak var cellView: ChatMessageView?

    func configure(config: ChatViewHandlerConfig) {
        guard
            let cellView = Bundle(for: ChatMessageTableViewCell.self)
            .loadNibNamed("ChatMessageView", owner: self, options: nil)?
            .first
            as? ChatMessageView
        else {
            fatalError("Couldn't get view from *ChatMessageView.xib* as a `ChatMessageView`, "
                + "please fix file")
        }
        
        self.messageViewModel = config.messageViewModel
        self.cellView = cellView
        self.selectableView = cellView
        cellView.configure(for: config.messageViewModel,
                           indexPath: config.indexPath,
                           timestampFormatter: config.timestampFormatter,
                           shouldDisplayDebugVideoTime: config.shouldDisplayDebugVideoTime,
                           shouldDisplayAvatar: config.shouldDisplayAvatar,
                           theme: config.theme)

        self.contentView.addSubview(cellView)
        self.contentView.clipsToBounds = false
        cellView.constraintsFill(to: self.contentView)
        
        self.accessibilityLabel = config.messageViewModel.accessibilityLabel
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
       super.init(coder: aDecoder)
    }
    
    func resetForReuse() {
        super.prepareForReuse()
        
        messageViewModel = nil
        cellView?.removeFromSuperview()
        
        self.contentView.subviews.forEach { $0.removeFromSuperview() }
        self.backgroundColor = UIColor.clear
        self.selectionStyle = .none
    }
    
    func releaseImageData() {
        cellView?.prepareForReuse()
    }
}
