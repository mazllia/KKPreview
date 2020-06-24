import UIKit

class TVC: UITableViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.indexedPreviewDelegate = self
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		500
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
		cell.textLabel?.text = indexPath.row.description
		cell.detailTextLabel?.text = UUID().uuidString
		return cell
	}
}

extension TVC: IndexedViewDelegate {
	func indexedView(_ indexedView: UIView, modelOn indexPath: IndexPath, at pointInCell: CGPoint) -> KKPreviewModel? {
		.init(previewingViewController: PreviewVC(), commit: KKPreviewCommit(style: .show))
	}
}
