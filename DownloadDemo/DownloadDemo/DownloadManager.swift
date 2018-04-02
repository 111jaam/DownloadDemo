//
//  ViewController.swift
//  DownloaderDemo
//
//  Created by bharat byan on 29/03/18.
//  Copyright © 2018 bharat byan. All rights reserved.
//

import Foundation

class DownloadManager : NSObject, URLSessionDelegate, URLSessionDownloadDelegate {

    static var shared = DownloadManager()

    typealias ProgressHandler = (Float) -> ()
    typealias completeHandler = (Bool) -> ()

    var onProgress : ProgressHandler? {
        didSet {
            if onProgress != nil {
                let _ = activate()
            }
        }
    }

    var onComplete: completeHandler?{
        didSet{
            if onComplete != nil{
                let _ = activate()
            }
        }
    }
    
    //MARK:- Init Stuff
    
    override private init() {
        super.init()
    }

    func activate() -> URLSession {
        let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background")

        // Warning: If an URLSession still exists from a previous download, it doesn't create a new URLSession object but returns the existing one with the old delegate object attached!
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }

    //MARK:- Custom callbacks
    
    private func calculateProgress(session : URLSession, completionHandler : @escaping (Float) -> ()) {
        session.getTasksWithCompletionHandler { (tasks, uploads, downloads) in
            let progress = downloads.map({ (task) -> Float in
                if task.countOfBytesExpectedToReceive > 0 {
                    return Float(task.countOfBytesReceived) / Float(task.countOfBytesExpectedToReceive)
                } else {
                    return 0.0
                }
            })
            completionHandler(progress.reduce(0.0, +))
        }
    }
    
    private func downloadedSuccess(completionHandler : @escaping (Bool) -> ()) {
        completionHandler(true)
    }

    //MARK:- URLSessionDownloadDelegate
    // 1
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

        if totalBytesExpectedToWrite > 0 {
            if let onProgress = onProgress {
                calculateProgress(session: session, completionHandler: onProgress)
            }
            
            //Below code To print in console only
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            debugPrint("Progress \(downloadTask) \(progress)")
        }
    }

    //2
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        debugPrint("Download finished temp location: \(location)")

        
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectoryPath:String = path[0]
        let fileManager = FileManager()
        let destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appendingFormat("/file.pdf"))
        
        if fileManager.fileExists(atPath: destinationURLForFile.path){
            //Do something
            debugPrint("Download already exists final location: \(destinationURLForFile.path)")
        }
        else{
            do {
                try fileManager.moveItem(at: location, to: destinationURLForFile)
                // show file
                //Do something
                debugPrint("Download finished final location: \(destinationURLForFile.path)")
                
            }catch{
                print("An error occurred while moving file to destination url")
            }
        }
    }

    //MARK:- URLSessionTaskDelegate
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        if error != nil{
            //This method callback can be used to send more info regarding the downloadTask.
            downloadedSuccess(completionHandler: onComplete!)
        }

        debugPrint("Task completed: \(task), error: \(String(describing: error))")
    }
}

