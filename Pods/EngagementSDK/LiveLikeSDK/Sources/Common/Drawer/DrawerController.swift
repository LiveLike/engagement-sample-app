//
//  DrawerController.swift
//  EngagementSDK
//
//  Created by Heinrich Dahms on 2019-04-01.
//

// This class was originally made to insert a widgetVC inside the
// ChatViewController. I've renamed it to better fit the new plan for it,
// but functionality has not been updated.
//
// HOWEVER, the gestures and view placement should be close to perfect. Leaving this here until this comes up again.

/*

 import UIKit

 public class DrawerController: UIViewController {
 // MARK: Public Properties

 /// Chat Adapter docs here
 public var chatAdapter: ChatAdapter? {
     didSet {
         internalChatController?.chatAdapter = chatAdapter
     }
 }

 /// session docs here
 public weak var session: ContentSession? {
     didSet {
         internalChatController?.session = session
     }
 }

 /// A Boolean value indicating whether the recommend size restrictions
 /// for the `ChatViewController` will be respected.
 ///
 /// The default value for this property is `false`. The recommended width for
 /// `ChatViewController` is **292** points. Normally, if the `ChatViewController`
 /// width does not exceed this value the view will be hidden and an error logged to
 /// the console. If this property is set to `true`, the `ChatViewController` will
 /// be displayed for any width. However, the correctness of the layout is not supported.
 public var ignoreSizeRestrictions = false

 /// widget controller docs here.
 public var widgetController: WidgetViewController?

 /// The direction the view should animate in.
 ///
 /// By default the view will animate down in portrait and to the right in landscape.
 /// Setting this value will override the defaults.
 public var animationDirection: Direction?

 // MARK: Internal Properties

 var internalChatController: ChatController? {
     didSet {
         internalChatController?.chatAdapter = chatAdapter
         internalChatController?.session = session
         if let theme = theme {
             internalChatController?.setTheme(theme: theme)
         }
     }
 }

 // MARK: Private Properties

 private let recognitionHeight = CGFloat(45)

 private var theme: Theme?
 private var isOnScreen = true
 private var chatViewPosition = CGPoint(x: 0, y: 0)

 private var defaultAnimationDirection: Direction {
     switch UIDevice.current.orientation {
     case .landscapeLeft, .landscapeRight:
         return .right
     default:
         return .down
     }
 }

 private var _direction: Direction {
     return animationDirection ?? defaultAnimationDirection
 }

 // MARK: Lifecycle

 public override func viewDidLoad() {
     super.viewDidLoad()
     addGestures()
 }

 public override func addChild(_ childController: UIViewController) {
     super.addChild(childController)

     if let vc = childController as? ChatController {
         internalChatController = vc
     }
 }

 public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
     super.viewWillTransition(to: size, with: coordinator)
     if !isOnScreen {
         internalChatController?.view.alpha = 0
     }
     coordinator.animate(alongsideTransition: nil) { _ in
         self.resetChatViewPosition()
     }
 }

 // MARK: Setters

 public func setTheme(theme: Theme) {
     self.theme = theme
     internalChatController?.setTheme(theme: theme)
 }

 // MARK: Chat View

 public func toggle() {
     animate(out: isOnScreen, direction: _direction)
 }

 private func animate(out: Bool, direction: Direction) {
     let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut)
     let position = offScreenPoint(out: out, direction: direction)

     animator.addAnimations {
         self.internalChatController?.view.frame.origin.x = position.x
         self.internalChatController?.view.frame.origin.y = position.y
     }

     animator.startAnimation()
     isOnScreen = !out
 }

 private func addGestures() {
     let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
     panGestureRecognizer.delegate = self
     view.addGestureRecognizer(panGestureRecognizer)
 }

 private func offScreenPoint(out: Bool, direction: Direction) -> CGPoint {
     guard let window = UIApplication.shared.keyWindow?.subviews.last else {
         return CGPoint(x: 0, y: 0)
     }
     var newXPos = CGFloat(0)
     var newYPos = CGFloat(0)

     if out {
         switch direction {
         case .up:
             let convertToPointOnWindow = window.convert(CGPoint(x: 0, y: 0), to: view)
             let newOrigin = CGPoint(x: convertToPointOnWindow.x - view.bounds.size.width, y: convertToPointOnWindow.y - view.bounds.size.height)
             newYPos = newOrigin.y

         case .down:
             let convertToPointOnWindow = window.convert(CGPoint(x: 0, y: UIScreen.main.bounds.height), to: view)
             newYPos = convertToPointOnWindow.y

         case .left:
             let convertToPointOnWindow = window.convert(CGPoint(x: 0, y: 0), to: view)
             let newOrigin = CGPoint(x: convertToPointOnWindow.x - view.bounds.size.width, y: convertToPointOnWindow.y - view.bounds.size.height)
             newXPos = newOrigin.x

         case .right:
             let convertToPointOnWindow = window.convert(CGPoint(x: UIScreen.main.bounds.width, y: 0), to: view)
             newXPos = convertToPointOnWindow.x
         }
     }
     return CGPoint(x: newXPos, y: newYPos)
 }

 private func resetChatViewPosition() {
     if isOnScreen {
         return
     }
     internalChatController?.view.frame.origin = offScreenPoint(out: true, direction: _direction)
     internalChatController?.view.alpha = 1
 }
 }

 extension DrawerController: UIGestureRecognizerDelegate {
 public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
     let touchPoint = gestureRecognizer.location(in: view)
     let recognitionArea = recognitionRect(is: isOnScreen, direction: _direction)
     return recognitionArea.contains(touchPoint)
 }

 public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
     return true
 }

 @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
     switch recognizer.state {
     case .began:
         internalChatController?.messageVC?.tableView.isScrollEnabled = false
         chatViewPosition = internalChatController?.view.frame.origin ?? CGPoint(x: 0, y: 0)

     case .changed:
         if let chatView = internalChatController?.view {
             switch _direction {
             case .up:
                 chatView.frame.origin.y = chatViewPosition.y + recognizer.translation(in: view).y
             case .down:
                 chatView.frame.origin.y = max(chatViewPosition.y + recognizer.translation(in: view).y, 0)
             case .left:
                 chatView.frame.origin.x = chatViewPosition.x + recognizer.translation(in: view).x
             case .right:
                 chatView.frame.origin.x = max(chatViewPosition.x + recognizer.translation(in: view).x, 0)
             }
         }

     case .ended:
         internalChatController?.messageVC?.tableView.isScrollEnabled = true
         if let chatView = internalChatController?.view {
             animate(out: isPastSnapPoint(chatView: chatView, direction: _direction), direction: _direction)
         }

     default:
         break
     }
 }

 private func recognitionRect(is onScreen: Bool, direction: Direction) -> CGRect {
     let origin = recognitionOrigin(is: onScreen, direction: direction)

     switch direction {
     case .up:
         return CGRect(x: origin.x, y: origin.y, width: view.bounds.width, height: recognitionHeight)
     case .down:
         let specialHeight = onScreen ? recognitionHeight : recognitionHeight * 2
         return CGRect(x: origin.x, y: origin.y, width: view.bounds.width, height: specialHeight)
     case .left:
         return CGRect(x: origin.x, y: origin.y, width: recognitionHeight, height: view.bounds.height)
     case .right:
         return CGRect(x: origin.x, y: origin.y, width: recognitionHeight, height: view.bounds.height)
     }
 }

 private func recognitionOrigin(is onScreen: Bool, direction: Direction) -> CGPoint {
     switch direction {
     case .up:
         return onScreen ? CGPoint(x: 0, y: view.bounds.height - recognitionHeight) : CGPoint(x: 0, y: 0)
     case .down:
         let specialHeight = onScreen ? recognitionHeight : recognitionHeight * 2
         return onScreen ? CGPoint(x: 0, y: 0) : CGPoint(x: 0, y: view.bounds.height - specialHeight)
     case .left:
         return onScreen ? CGPoint(x: view.bounds.width - recognitionHeight, y: 0) : CGPoint(x: 0, y: 0)
     case .right:
         return onScreen ? CGPoint(x: 0, y: 0) : CGPoint(x: view.bounds.width - recognitionHeight, y: 0)
     }
 }

 private func isPastSnapPoint(chatView: UIView, direction: Direction) -> Bool {
     switch direction {
     case .up, .down:
         return abs(chatView.frame.origin.y) >= (chatView.bounds.height - recognitionHeight) / 2
     case .left, .right:
         return abs(chatView.frame.origin.x) >= (chatView.bounds.width - recognitionHeight) / 2
     }
 }
 }

 // public extension DrawerController {
 //    static func instantiate() -> DrawerController? {
 //        let storyboard = UIStoryboard(name: "LiveLikeChat", bundle: Bundle(for: self))
 //        guard let vc = storyboard.instantiateInitialViewController() as? DrawerController else {
 //            return nil
 //        }
 //        return vc
 //    }
 // }

 */
