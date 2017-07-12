import Foundation

class AlertService {

  /**
   Display a message with a cancel and retry button
   **/
  public static func showCancelRetryMessage(
    viewController  : UIViewController,
    title           : String,
    message         : String,
    onRetry         : @escaping ((_ : UIAlertAction) -> Void),
    onCancel        : @escaping ((_ : UIAlertAction) -> Void)
    ) -> Void {

    // create the alert
    let alert = UIAlertController(
      title          : title,
      message        : message,
      preferredStyle : .alert
    )

    // add the buttons
    alert.addAction(
      UIAlertAction(
        title   : "Cancel",
        style   : .default,
        handler : onCancel
      )
    )
    alert.addAction(
      UIAlertAction(
        title   : "Retry",
        style   :.default,
        handler : onRetry
      )
    )

    // show the alert
    viewController.present(
      alert,
      animated   : true,
      completion : nil
    )
  }


  /**
   Display a message with an OK button only
   **/
  static func showOKMessage(
    viewController : UIViewController,
    title          : String,
    message        : String,
    onOK           : ((_ : UIAlertAction) -> Void)? = nil
    ) {

    // create the alert
    let alert = UIAlertController(
      title          : title,
      message        : message,
      preferredStyle : .alert
    )

    // add the button
    alert.addAction(
      UIAlertAction(
        title: "OK",
        style: .default,
        handler: onOK
      )
    )

    // show the alert
    viewController.present(
      alert,
      animated: true,
      completion: nil
    )
  }
}