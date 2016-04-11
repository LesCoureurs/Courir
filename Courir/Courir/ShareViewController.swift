//
//  ShareViewController.swift
//  Courir
//
//  Created by Ian Ngiaw on 4/10/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

private let reuseIdentifier = "ghostShareCell"
class ShareViewController: UIViewController {

    private let dates = GhostStore.storedGhostDates
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var ghostsTableView: UITableView!
    private lazy var dateFormatter: NSDateFormatter = {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd-MMM-yyyy hh:mm:ss a"
        return dateFormatter
    }()
    private var qrUIImages: [UIImage]?
    
    private var timer: NSTimer?
    private var isAnimating = false
    private var frame = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ghostsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        ghostsTableView.dataSource = self
        ghostsTableView.delegate = self
    }
    
    @IBAction func animatePressed(sender: AnyObject) {
        if qrUIImages != nil && !isAnimating {
            timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self,
                                                           selector: #selector(self.updateQRImage),
                                                           userInfo: nil, repeats: true)
            isAnimating = true
        } else {
            frame = 0
            isAnimating = false
            timer?.invalidate()
            timer = nil
        }
    }
    
    func updateQRImage() {
        qrImageView.image = qrUIImages![frame]
        frame = (frame + 1) % qrUIImages!.count
    }
    
    func splitDataIntoChunks(data: NSData, size: Int) -> [NSData] {
        assert(data.length > 0 && size > 0)
        var res = [NSData]()
        var total = 0
        let parts = Int(ceil(Double(data.length) / Double(size)))
        var count = 0
        while (total < data.length) {
            let len = data.length - total >= size ? size : data.length - total
            let subData = data.subdataWithRange(NSMakeRange(total, len))
            let dataDict = [
                "part": count,
                "totalParts": parts,
                "partSize": len,
                "totalSize": data.length,
                "data": subData
            ]
            count += 1
            total += len
            res.append(NSKeyedArchiver.archivedDataWithRootObject(dataDict))
        }
        return res
    }
    
    func generateQRImages(data: NSData) -> [CIImage]? {
        var res = [CIImage]()
        let dataChunks = splitDataIntoChunks(data, size: 400)
        for chunk in dataChunks {
            guard let qrImage = generateQRImage(chunk) else {
                return nil
            }
            res.append(qrImage)
        }
        return res
    }
    
    func generateQRImage(data: NSData) -> CIImage? {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")
        
        return filter?.outputImage
    }
}

extension ShareViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dates.count
    }
    
    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = ghostsTableView.dequeueReusableCellWithIdentifier(reuseIdentifier)!
        cell.textLabel?.text = dateFormatter.stringFromDate(dates[indexPath.row])
        return cell
    }
}

extension ShareViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let ghostStore = GhostStore(date: dates[indexPath.row])
        
        guard let ghostData = ghostStore?.convertToData(),
            qrImages = generateQRImages(ghostData) else {
            print("qrImage generation failed")
            return
        }
        qrUIImages = qrImages.map { UIImage(CIImage: $0) }
        qrImageView.image = qrUIImages![0]
    }
}