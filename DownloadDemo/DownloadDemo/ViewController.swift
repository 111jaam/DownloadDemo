//
//  ViewController.swift
//  DownloaderDemo
//
//  Created by bharat byan on 29/03/18.
//  Copyright © 2018 bharat byan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var downloadTask: URLSessionDownloadTask!
    var downloadCompleted = false
    
    @IBOutlet weak var viewURLInfo: UIStackView!
    @IBOutlet weak var viewDownloadInfo: UIStackView!
    @IBOutlet weak var lblDownloadInfo: UILabel!
    @IBOutlet weak var txtUrl: UITextField!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var activityDownload: UIActivityIndicatorView!
    
    //MARK:- View's lifeCycle
    override func viewDidLoad() {
        
        //Pre-fill textfield with testing  URLs
//        txtUrl.text = "https://scholar.princeton.edu/sites/default/files/oversize_pdf_test_0.pdf" //~100mb
        txtUrl.text = "https://github.com/sqlitebrowser/sqlitebrowser/releases/download/v3.10.1/DB.Browser.for.SQLite-3.10.1.dmg" //~15mb
        
        let _ = DownloadManager.shared.activate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //1 Callback getting download progress
        DownloadManager.shared.onProgress = { (progress) in
            OperationQueue.main.addOperation {
                self.progressView.progress = progress
            }
        }
        
        //2 Callback getting download completion info
        DownloadManager.shared.onComplete = { complete in
            if complete {
                OperationQueue.main.addOperation {
                    self.downloadFinished(complete)
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        DownloadManager.shared.onProgress = nil
    }
    
    //MARK: Overiding method to hide keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //MARK:- Custom Methods
    func downloadStartedWithUrl(_ url: URL){
        viewURLInfo.alpha = 0.3
        viewURLInfo.isUserInteractionEnabled = false
        
        downloadTask = DownloadManager.shared.activate().downloadTask(with: url)
    }
    
    func downloadFinished(_ isCompleted: Bool){
        
        self.viewURLInfo.alpha = 1.0
        self.viewURLInfo.isUserInteractionEnabled = true
        
        self.viewDownloadInfo.isHidden = true
        self.activityDownload.stopAnimating()
        
        if !isCompleted{
            self.progressView.progress = 0.0
        }
        
        if downloadTask != nil{
            self.downloadCompleted = true
            
            self.downloadTask.cancel()
            self.downloadTask = nil
        }
    }
    
    func downloadResumed(){
        self.viewDownloadInfo.isHidden = false
        self.activityDownload.startAnimating()
        
        downloadTask.resume()
    }
    
    //MARK:- IBActions
    
    @IBAction func startDownload(_ sender: Any) {
        
        guard txtUrl.text! != "" else {
            self.popupAlert(title: "Message", message: "Please enter URL", actionTitles: ["Ok"], actions:[{action1 in
                }, nil])
            return
        }
        
        let url = URL(string: txtUrl.text!)!
        
        if !downloadCompleted {
            if downloadTask == nil{
                downloadStartedWithUrl(url)
            }
            downloadResumed()
            
        }else{
            downloadStartedWithUrl(url)
            downloadCompleted = false
            downloadResumed()
        }
    }
    
    @IBAction func pause(_ sender: AnyObject) {
        
        activityDownload.stopAnimating()
        
        if downloadTask != nil{
            downloadTask.suspend()
        }
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        
        downloadFinished(false)
    }
}

extension UIViewController {
    func popupAlert(title: String?, message: String?, actionTitles:[String?], actions:[((UIAlertAction) -> Void)?]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for (index, title) in actionTitles.enumerated() {
            let action = UIAlertAction(title: title, style: .default, handler: actions[index])
            alert.addAction(action)
        }
        self.present(alert, animated: true, completion: nil)
    }
}
