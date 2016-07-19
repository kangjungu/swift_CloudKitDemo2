//
//  ViewController.swift
//  CloudKitDemo2
//
//  Created by JHJG on 2016. 7. 15..
//  Copyright © 2016년 KangJungu. All rights reserved.
//

import UIKit
import CloudKit
import MobileCoreServices

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var commentsField: UITextView!
    @IBOutlet weak var addressField: UITextField!
    
    //애플리케이션의 컨테이너에 대한 참조체를 얻는드ㅏ.
    let container = CKContainer.defaultContainer()
    var publicDatabase: CKDatabase?
    //현재의 데이터 베이스 레코드를 저장할 변수
    var currentRecord: CKRecord?
    //사진 이미지를 저장할 변수
    var photoURL: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //공용 클라우드 데이터 베이스
        publicDatabase = container.publicCloudDatabase
        
        // 'TRUEPREDICATE'는 지정된 타입의 모든 레코드가 조건식과 일치한다는 의미로 항상 true 값을 반환하도록 구성된 특별한 값이다.
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        
        // CloudKit 구독은 CKSubscription 클래스의 인스턴스를 이용하여 구성된다.
        // 'FiresOnRecordCreation'옵션은 'Houses' 타입의 새로운 레코드가 데이터베이스에 추가될 때 마다 사용자에게 알리라는 뜻이다. 
        // .FiresOnRecordUpdate, .FiresOnRecordDelete, .FiresOnce가 있다. FiresOnce는 알림을 보낸후 서버에서 구독을 삭제한다.
        let subscription = CKSubscription(recordType: "Houses", predicate: predicate, options: .FiresOnRecordCreation)
        
        //알림과 함께 애플리케이션에 전송될 정보를 정의하기 위해 사용된다.
        let notificationInfo = CKNotificationInfo()
        
        notificationInfo.alertBody = "A new House was added"
        notificationInfo.shouldBadge = true
        
        subscription.notificationInfo = notificationInfo
        
        //클라우드 데이터베이스에 구독정보를 보낸다.
        publicDatabase?.saveSubscription(subscription, completionHandler: { (returnRecord, error) in
            if let err = error{
                print("subscription failed %@",err.localizedDescription)
            }else{
                dispatch_async(dispatch_get_main_queue()){
                    self.notifyUser("Success", message: "Subscription set up successfully")
                }
            }
        })
    }
    
    //사용자 인터페이스의 배경뷰를 터치할 때 키보드가 사라진다.
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        addressField.endEditing(true)
        commentsField.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //클라우드 데이터베이스에 저장하는 코드
    @IBAction func saveRecord(sender: AnyObject) {
        
        //데이터베이스 레코드에 포함될 사진을 사용자가 서택했는지 검사.
        if photoURL == nil {
            notifyUser("No photo",message: "Use the Photo option to chosse a photo for the record")
            return
        }
        
        //새로운 CloudKitAsset 객체를 생성하고 앞에서 사용자가 선택한 사진이미지에 대한 URL로 초기화
        let asset = CKAsset(fileURL: photoURL!)
        
        //CKRecord 인스턴스를 생성하고 'Houses'라는 레코드 타입을 할당한다.
        let myRecord = CKRecord(recordType: "Houses")
        //텍스트뷰 내용과 asset을 record에 넣는다.
        myRecord.setObject(addressField.text, forKey: "address")
        myRecord.setObject(commentsField.text, forKey: "comment")
        myRecord.setObject(asset, forKey: "photo")
        
        //공용 클라우드 데이터 베이스의 saveRecord 메서드는 새롭게 생성된 레코드를 전달하며 호출된다. 완료핸들러는 저장 작업에대한 성공 여부를 알려준다.
        publicDatabase?.saveRecord(myRecord, completionHandler: { (returnRecord, error) in
            if let err = error {
                self.notifyUser("Save error", message:(err.localizedDescription))
            }else{
                //이 작업은 UI 작업 + 백그라운드 작업이므로 UI작업은 메인 스레드로 전달한다.
                dispatch_async(dispatch_get_main_queue()) {
                    self.notifyUser("Success", message:"Record aved successfully")
                }
                //사용자가 나중에 해당 레코드를 갱신하거나 삭제할 때 참조할 수 있는 currentRecord 변수에 저장된다.
                self.currentRecord = myRecord
            }
        })
    }
    
    //지정된 주소와 일치하는 애플리케이션을 가져와서 사용자에게 표시
    @IBAction func performQuery(sender: AnyObject) {
        
        //주소 필드가 애플리케이션 사용자 인터페이스에 사용자가 입력한 주소와 일치하는 레코드를 검색하는 쿼리임을 가리키는 새로운 조건부 인스턴스 구성
        let predicate = NSPredicate(format: "address = %@", addressField.text!)
        //검색할 레토드 타입과 함께 조건부 인스턴스가 사용됨.
        let query = CKQuery(recordType: "Houses", predicate: predicate)
        
        //공용 클라우드 데이터베이스 객체의 performQuery 메서드가 호출되며, 쿼리가 끝날때 실행될 완료 핸들러(비동기이기 때문에)와 함께 쿼리객체를 전달.
        publicDatabase?.performQuery(query, inZoneWithID: nil, completionHandler: { (results, error) in
            
            if error != nil {
                //에러 발생
                dispatch_async(dispatch_get_main_queue()){
                    self.notifyUser("Cloud Access Error", message: error!.localizedDescription)
                }
            }else{
                if results!.count > 0 {
                    let record = results![0]
                    self.currentRecord = record
                    
                    //메인 스레드에서 ui 변환
                    dispatch_async(dispatch_get_main_queue()){
                        self.commentsField.text = record.objectForKey("comment") as! String
                        
                        let photo = record.objectForKey("photo") as! CKAsset
                        
                        let image = UIImage(contentsOfFile: photo.fileURL.path!)
                        
                        self.imageView.image = image
                        self.photoURL = self.saveImageToFile(image!)
                    }
                    
                }
            }
        })
    }
    
    //사진 선택 액션
    @IBAction func selectPhoto(sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.mediaTypes = [kUTTypeImage as String]
        
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    //클라우드 데이터베이스 레코드 업데이트
    @IBAction func updateRecord(sender: AnyObject) {
        
        //업데이트를 할때는 업데이트될 레코드의 ID가 필요하다
        if let record = currentRecord{
            let asset = CKAsset(fileURL: photoURL!)
            
            record.setObject(addressField.text, forKey: "address")
            record.setObject(commentsField.text, forKey: "comment")
            record.setObject(asset, forKey: "photo")
        
            //저장 작업이 시작되면, CloudKit은 데이터 베이스에 있는 레코드와 일치하는 아이디를 가지고 있는지를 식별하고, 사용자가 제공한 최신 데이터를 이용해 일치하는 레코드 업데이트
            publicDatabase?.saveRecord(record, completionHandler: ({returnRecord, error in
                if let err = error{
                    dispatch_async(dispatch_get_main_queue()){
                        self.notifyUser("Update error", message: err.localizedDescription)
                    }
                }else{
                    dispatch_async(dispatch_get_main_queue()){
                        self.notifyUser("Sucess", message: "Record updated successfully")
                    }
                }
            }))
            
        }else{
            notifyUser("No Record Selected", message:"Use Query to select a record to update")
        }
    }
    
    //레코드 삭제
    @IBAction func deleteRecord(sender: AnyObject) {
        
        if let record = currentRecord{
            //레코드의 아이디로 삭제 메소드 호출함.
            publicDatabase?.deleteRecordWithID(record.recordID, completionHandler: { (returnRecord, error) in
                if let err = error{
                    
                    dispatch_async(dispatch_get_main_queue()){
                        self.notifyUser("Delete Error", message: err.localizedDescription)
                    }
            
                }else{
                    dispatch_async(dispatch_get_main_queue()){
                        self.notifyUser("Success", message: "Record deleted successfully")
                    }
                }
            })
        }else{
            notifyUser("No Record Selected ", message: "Use Query to select a record to delete")
        }
    }
    
    //사진을 선택한 경우라면 사진 이미지는 이미지 뷰 인스턴스를 통해 애플리케이션에서 표시한 다음, 이미지를 디바이스 파일 시스템에 저장하고 해당 URL을 나중에 사용할 참조체인 photoURL 변수에 저장한다.
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imageView.image = image
        photoURL = saveImageToFile(image)
    }
    
    //뷰에서 이미지 피커 뷰 컨트롤러를 해제한다.
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //Image를 파일객체로 만드는 메소드
    func saveImageToFile(image: UIImage) -> NSURL{
        let filemgr = NSFileManager.defaultManager()
        //Documents 디렉터리에 대한 참조체를 얻어 currentImage.png라는 이름의 이미지 파일 경로를 만든다.
        let dirpaths = filemgr.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let filePath = dirpaths[0].URLByAppendingPathComponent("currentImage.png").path
        
        //그런 다음 애플리케이션이 사용하는 아이클라우드 사용량을 줄이기 위해서 이미지를 0.5의 압출률로 하여 JPEG파일로 만든다.
        UIImageJPEGRepresentation(image, 0.5)!.writeToFile(filePath!, atomically: true)
        
        //메소드를 호출한 곳으로 이렇게 만들어진 파일의 URL을 반환한다.
        return NSURL.fileURLWithPath(filePath!)
    }
    
    //사용자에게 표시될 제목과 메시지로 두개의 문자열을 매개변수로 받으며, 이렇게 받은 문자열은 Alert View를 만드는데 사용된다.
    func notifyUser(title: String,message: String) ->Void{
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        
        alert.addAction(cancelAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //백그라운드나 포그라운드에서 애플리케이션이 실행중일때 알림을 받았을 경우 이 메소드를 실행한다.
    func fetchRecord(recordID: CKRecordID) -> Void{
        
        //공용 클라우드 데이터베이스에 대한 참조체를 얻은다음(viewDidLoad메서드 이전에 실행되기때문에)
        publicDatabase = container.publicCloudDatabase
        
        //클라우드 데이터베이스에서 매개변수로 전달된 레코드 아이디로 레코드를 가져온다.
        publicDatabase?.fetchRecordWithID(recordID, completionHandler: { (record, error) in
            if let err = error{
                dispatch_async(dispatch_get_main_queue()){
                    self.notifyUser("Fetch Error", message: err.localizedDescription)
                }
            }else{
                dispatch_async(dispatch_get_main_queue()){
                    self.currentRecord = record
                    self.addressField.text = record?.objectForKey("address") as? String
                    self.commentsField.text = record?.objectForKey("comment") as? String
                    let photo = record!.objectForKey("photo") as! CKAsset
                    
                    let image = UIImage(contentsOfFile: photo.fileURL.path!)
                    
                    self.imageView.image = image
                    self.photoURL = self.saveImageToFile(image!)
                }
            }
        })
    }
    
    
}

