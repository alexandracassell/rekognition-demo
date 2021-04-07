/*
 * Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so.
 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
import UIKit
import SafariServices
import AWSRekognition

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SFSafariViewControllerDelegate {
        
    var infoLinksMap: [Int:String] = [1000:""]
    var rekognitionObject:AWSRekognition?
    
    @IBOutlet weak var OdometerImageView: UIImageView!
    
    @IBOutlet weak var mileageInput: UITextField!
    
    @IBOutlet weak var messageLabel: UILabel!
    
    var mileage: Int? = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Button Actions
    @IBAction func CameraOpen(_ sender: Any) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .camera
        pickerController.cameraCaptureMode = .photo
        present(pickerController, animated: true)
    }
    
    @IBAction func PhotoLibraryOpen(_ sender: Any) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .savedPhotosAlbum
        present(pickerController, animated: true)
    }
    
    @IBAction func submitMileage(_ sender: UIButton) {
        mileage = Int(mileageInput.text ?? "0")!
        print(mileage ?? 0)
        
        if (OdometerImageView.image != nil) {
            let odomImage: Data = UIImageJPEGRepresentation(OdometerImageView.image!, 0.2)!
            detectMileage(odometerImageData: odomImage)
        }
        else {
            print("Please upload a picture before submitting mileage")
            messageLabel.text = "Please upload a picture"
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true)
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("couldn't load image from Photos")
        }
        
        OdometerImageView.image = image
        
        //let odomImage:Data = UIImageJPEGRepresentation(image, 0.2)!
        //odomImage = UIImageJPEGRepresentation(image, <#T##compressionQuality: CGFloat##CGFloat#>)
        //detectMileage(odometerImageData: odomImage)
    }
    
    
    //MARK: - AWS Methods
    func detectMileage(odometerImageData: Data) {
        print("inside detectMileage")
        rekognitionObject = AWSRekognition.default()
        let odometerImage = AWSRekognitionImage()
        odometerImage?.bytes = odometerImageData
        let request = AWSRekognitionDetectTextRequest()
        request?.image = odometerImage
        
        var contenders: [String] = []
            
        rekognitionObject?.detectText(request!) {
            (result, error) in
                if error != nil {
                    print(error!)
                    return
                }
                
                if ((result!.textDetections?.count)! > 0) {
                    for (_, odomText) in result!.textDetections!.enumerated() {
                        if (odomText.confidence!.intValue > 50) {
                            // we have a confident match
                            //print("we have a match")
                            print(odomText.detectedText!)
                            contenders.append(odomText.detectedText!.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
                    // look through contenders to match with mileage input
                    print("contenders")
                    var acceptableInput:Bool = false
                    for contender in contenders {
                        print("contender", contender)
                        let int = Int(contender) ?? 0
                        print("casted", int)
                        if (abs(int - self.mileage!) <= 1) {
                            // then we have a good enough contender and can use input mileage
                            print("accepted")
                            acceptableInput = true
                        }
                    }
                    print(acceptableInput)
                    if (acceptableInput) {
                        print(String(self.mileage!))
                        self.messageLabel.text = "Mileage: " + String(self.mileage!)
                    }
                    else {
                        self.messageLabel.text = "Mileages do not match"
                    }
            }
                else {
                    print("Mileage was not detected")
                    self.messageLabel.text = "Mileage was not detected"
                }
        }
    }
}
