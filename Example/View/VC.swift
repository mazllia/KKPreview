import UIKit

class VC: UIViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
		view.previewDelegate = self
	}
}

extension VC: ViewDelegate {
	func view(_ view: UIView, modelAt point: CGPoint) -> KKPreviewModel? {
		.init(previewingViewController: PreviewVC(), commit: KKPreviewCommit(style: .show))
	}
}
