//
//  ScanViewController.swift
//  Courir
//
//  Created by Ian Ngiaw on 4/10/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit
import AVFoundation

class ScanViewController: UIViewController {
    
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureVideoCapture()
        addPreviewLayer()
        initializeQRView()
    }

    func configureVideoCapture() {
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let deviceInput: AVCaptureDeviceInput!
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch {
            print("error in getting device input")
            return
        }
        captureSession = AVCaptureSession()
        captureSession?.addInput(deviceInput)
        let metadataOutput = AVCaptureMetadataOutput()
        captureSession?.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
    }
    
    func addPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer!)
        captureSession?.startRunning()
    }
    
    func initializeQRView() {
        qrCodeView = UIView()
        qrCodeView?.layer.borderColor = UIColor.redColor().CGColor
        qrCodeView?.layer.borderWidth = 5
        view.addSubview(qrCodeView!)
        view.bringSubviewToFront(qrCodeView!)
    }
}

extension ScanViewController: AVCaptureMetadataOutputObjectsDelegate {
    func captureOutput(captureOutput: AVCaptureOutput!,
                       didOutputMetadataObjects metadataObjects: [AnyObject]!,
                       fromConnection connection: AVCaptureConnection!) {
        guard metadataObjects != nil && metadataObjects.count > 0 else {
            print("nothing detected")
            return
        }
        guard let codeObject = metadataObjects[0] as? AVMetadataMachineReadableCodeObject else {
            print("invalid metadata object")
            return
        }
        if codeObject.type == AVMetadataObjectTypeQRCode {
            let barCode = previewLayer?
                .transformedMetadataObjectForMetadataObject(codeObject) as!
                AVMetadataMachineReadableCodeObject
            qrCodeView?.frame = barCode.bounds
            print(codeObject.stringValue)
        }
    }
}
