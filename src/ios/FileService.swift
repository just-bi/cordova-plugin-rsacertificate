import Foundation

class FileService {

  /**
   Returns the path to the first file having the provided extension in the provided foler
   **/
  public static func getURLToFirstFileInDirectoryByExtension (
    directoryPath : URL,
    fileExtension : String
  ) -> URL? {
    let fileManager = FileManager.default
    do {
      let fileNames = try fileManager.contentsOfDirectory(atPath: directoryPath.path)
      for fileName in fileNames {
        let filePath = directoryPath.appendingPathComponent(fileName)
        if(filePath.pathExtension == fileExtension){
          return filePath;
        }
      }
    }
    catch _ as NSError {
      return nil
    }
    return nil
  }


  /**
   Move all files from a certain exteion to another location
   Note that only the last file will remain
   **/
  public static func moveAllFilesInDirectoryWithExtensionToNewLocation(
    directoryPath     : URL,
    fileExtension     : String,
    newLocation       : URL
    ) -> Bool {

    do {
      let fileNames = try FileManager.default.contentsOfDirectory(atPath: directoryPath.path)
      for fileName in fileNames {
        let filePath = directoryPath.appendingPathComponent(fileName)
        if filePath.pathExtension != fileExtension {
          continue
        }
        if filePath == newLocation {
          continue
        }
        FileService.moveAndOverwriteFile(fileToBeMoved: filePath, newLocation: newLocation)
      }
    } catch _ as NSError {
    }
    return true
  }


  /**
   Checks if file exists
   **/
  public static func fileExists(filePath: String) -> Bool {
    return FileManager.default.fileExists(atPath: filePath)
  }


  /**
   Delete file if exists
   **/
  public static func deleteFile(filePath: String) -> Bool {
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: filePath) {
      do {
        try fileManager.removeItem(atPath: filePath)
      }
      catch let error as NSError {
        print("Ooops! Something went wrong: \(error)")
      }
    }
    return true
  }


  /**
   Move a file to another location, overwrites if already existing
   **/
  public static func moveAndOverwriteFile(fileToBeMoved: URL, newLocation: URL) {
    let fileManager = FileManager.default

    if !fileManager.fileExists(atPath: newLocation.path) {
      do {
        try fileManager.moveItem(at: fileToBeMoved, to: newLocation)
        try fileManager.addSkipBackupAttributeToItemAtURL(url: newLocation as NSURL)
      } catch let error as NSError {
        print("Error: \(error)")
      }
    }
    else {
      do {
        try fileManager.removeItem(atPath: newLocation.path)
        try fileManager.moveItem(at: fileToBeMoved, to: newLocation)
        try fileManager.addSkipBackupAttributeToItemAtURL(url: newLocation as NSURL)
      } catch let error as NSError {
        print("Error: \(error)")
      }
    }
  }



  /**
   Deletes all files with the provided extension inside the provided directory
   **/
  public static func deleteAllFilesInDirectoryByExtension(
    directoryPath     : URL,
    fileExtension     : String,
    ignoreFiles       : [String]? = []
  ) -> Bool {
    do {
      let fileNames = try FileManager.default.contentsOfDirectory(atPath: directoryPath.path)

      for fileName in fileNames {
        if ignoreFiles!.contains(fileName) {
          continue
        }

        let filePath = directoryPath.appendingPathComponent(fileName)
        if filePath.pathExtension != fileExtension {
          continue
        }

        do {
          try FileManager.default.removeItem(at: filePath)
        } catch _ as NSError {
        }
      }
    } catch _ as NSError {
    }
    return true
  }


  /**
   Get the path to the Inbox folder of the application
   **/
  public static func getPathToInboxFolder() -> URL {
    let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    return documentsUrl.appendingPathComponent("Inbox/")
  }
}

/**
 Extension to add the exclude from backup flag
 **/
extension FileManager{
  func addSkipBackupAttributeToItemAtURL(url:NSURL) throws {
    try url.setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
  }
}

