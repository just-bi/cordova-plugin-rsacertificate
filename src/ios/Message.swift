import Foundation

class MessageScreenViewController: UIViewController {

  /**
   PROPERTIES
   **/
  @IBOutlet weak var lblTitle: UILabel!
  @IBOutlet weak var lblMessage: UILabel!



  /**
   OVERRIDES
   **/
  override func viewDidLoad() {
    super.viewDidLoad()
  }


  /**
   INIT
   Styling the View
   The look and feel of the view is driven from user parameters. This function is used to
   set the correct colors
   **/
  func setStyling(params : NSDictionary) {
    let messageTitle    = params["title"] as? String ?? "No Data"
    let messageText     = params["message"] as? String ?? "No data file provided.\nPlease use the 'Open in' functionality from your mail application in order to provide the data to this application."
    let textColor       = CommonService.hexStringToUIColor(hex: params["textColorHex"] as? String ?? "#000000" )
    let backgroundColor = CommonService.hexStringToUIColor(hex: params["backgroundColorHex"] as? String ?? "#FFFFFF" )

    self.view.backgroundColor = backgroundColor

    lblMessage.textColor = textColor
    lblTitle.textColor   = textColor
    lblTitle.text        = messageTitle
    lblMessage.text      = messageText
  }

}
