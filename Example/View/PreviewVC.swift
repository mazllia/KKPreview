import class UIKit.UIViewController
import class UIKit.UIColor
final class PreviewVC: UIViewController {
	static let colors: [UIColor] = [.blue, .brown, .cyan, .green, .lightGray, .magenta, .orange, .purple, .red, .yellow]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = Self.colors.randomElement()
		preferredContentSize = .init(width: 200, height: 400)
	}
}
