//
//  File.swift
//  Spore
//
//  Created by Vikram Ramkumar on 12/16/15.
//  Copyright © 2015 Vikram Ramkumar. All rights reserved.
//

import UIKit
import Parse

class MainController: UIViewController, UITableViewDelegate, CLLocationManagerDelegate {
    
    
    var timer = NSTimer()
    
    var initialRowLoad = true
    var userList = Array<PFObject>()
    var userName = ""
    var userEmail = ""
    var userToReceivePhotos = 2
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet var table: UITableView!
    @IBOutlet var settingsButton: UIBarButtonItem!
    @IBOutlet var snap: UIImageView!
    
    
    
    override func viewDidLoad() {
        
        //Initialize values
        snap.alpha = 0
        
        /* Not working right now
        //Retreive local history list
        if userDefaults.objectForKey("userList") != nil {
            
            let temp = userDefaults.objectForKey("userList") as! NSData
            userList = NSKeyedUnarchiver.unarchiveObjectWithData(temp) as! Array<PFObject>
            
        }
        */
        
        //Load view
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        //Initialize row load
        initialRowLoad = true
        super.viewWillAppear(true)
    }
    
    override func viewDidAppear(animated: Bool) {
        
        //Run like usual
        super.viewDidAppear(true)
        
        //Retrieve photos pending for user
        if userDefaults.integerForKey("userToReceivePhotos") > 0 {
            
            userToReceivePhotos = userDefaults.integerForKey("userToReceivePhotos")
            print("User received photos: " + String(userToReceivePhotos))
        }
        
        //Update user list and reload the table
        updateUserList()
        
        //Congifure gestures & snap
        snap.userInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: ("snapTapped"))
        let swipe = UISwipeGestureRecognizer(target: self, action: Selector("snapSwiped"))
        swipe.direction = .Down
        snap.addGestureRecognizer(tap)
        snap.addGestureRecognizer(swipe)
    }
    
    internal func snapTapped() {
        
        print("Tapped!")
        UIView.animateWithDuration(0.3) { () -> Void in
            
            self.snap.alpha = 0
        }
    }
    
    internal func snapSwiped() {
        
        print("Swiping!")
        UIView.animateWithDuration(0.3) { () -> Void in
            
            self.snap.center = CGPoint(x: self.snap.center.x, y: self.snap.center.y + self.snap.bounds.height + 100)
        }
        
        delay(1) { () -> () in
            
            self.snap.alpha = 0
            self.snap.center = CGPoint(x: self.snap.center.x, y: self.snap.center.y - self.snap.bounds.height - 100)
        }
    }
    
    internal func saveUserList() {
        
        /*
        let listData = NSKeyedArchiver.archivedDataWithRootObject(userList)
        userDefaults.setObject(listData, forKey: "userList")
        */
        print("Reloading table")
        table.reloadData()
    }
    
    internal func updateUserList() {
        
        //If user is to receive photos, execute the following
        if userToReceivePhotos > 0 {
            
            //Get unsent photos in the database equal to how many the user gets
            let query = PFQuery(className:"photo")
            query.whereKeyDoesNotExist("receivedBy")
            query.limit = userToReceivePhotos
            
            //Query with above conditions
            query.findObjectsInBackgroundWithBlock({ (photos, error) -> Void in
                
                    
                if error != nil {
                    print("Photo query error: " + error!.description)
                }
                else if photos!.count < 1 {
                    
                    //Let the user know that the database is empty
                    print("Database empty.")
                    let alert = UIAlertController(title: "", message: "Please wait a while and try again.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler:nil))
                }
                else {
                    
                    print("photo count: " + String(photos!.count))
                    //Run for each returned object
                    for photoObject in photos!{
                        
                        //Attach receipt details to object
                        photoObject["receivedAt"] = NSDate()
                        photoObject["receivedBy"] = self.userEmail
                        
                        
                        //Add object to userList
                        self.userList.append(photoObject)
                        print("userList count: " + String(self.userList.count))
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            self.saveUserList()
                        })
                        
                        //Save object to database
                        print("Saving object!")
                        photoObject.saveInBackground()
                        print("Saved object!")
                        print("userList count: " + String(self.userList.count))
                    }
                    
                    //Reset user photos to zero once photos are retreived
                    print("Resetting user photos")
                    self.userDefaults.setInteger(0, forKey: "userToReceivePhotos")
                    
                    self.delay(0.5, closure: { () -> () in
                        
                        self.initialRowLoad = false
                    })
                    
                }
            })
        }
    }
    
    internal func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //Initialize variables
        print("Reached cell")
        let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Unread")
        let userListLength = userList.count - 1
        print(userListLength)
        
        let time = userList[userListLength - indexPath.row]["receivedAt"]
        let countryCode = userList[userListLength - indexPath.row]["countryCode"]
        
        //Configure image
        cell.imageView!.image = getCountryImage(countryCode as! String).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        cell.imageView!.tintColor = UIColor(red: CGFloat(arc4random_uniform(255))/255.0, green: CGFloat(arc4random_uniform(255))/255.0, blue: CGFloat(arc4random_uniform(255))/255.0, alpha: 0.5)
        
        //Configure text
        cell.textLabel!.text = getCountryName(countryCode as! String)
        
        //Configure subtext
        cell.detailTextLabel!.textColor = UIColor(red: 166.0/255.0, green: 166.0/255.0, blue: 166.0/255.0, alpha: 1.0)
        cell.detailTextLabel!.text = String(time)
        
        return cell
    }
    
    internal func getCountryImage(countryCode: String) -> UIImage {
        
        let link  = "Countries/" + countryCode + "/128.png"
        return UIImage(named: link)!
    }
    
    internal func getCountryName(countryCode: String) -> String {
        
        
        var countryName = "Spain"
        print("Country:" + countryCode)
        
        //Find country and obtain the 2 digit ISO code
        for country in countryTable {
            
            if country[1] == countryCode {
                countryName = country[0]
                break
            }
        }
        
        return countryName
    }
    
    internal func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if initialRowLoad {
            
            cell.center = CGPointMake(cell.center.x+100, cell.center.y)
            UIView.animateWithDuration(0.2 + Double(indexPath.row)/10) { () -> Void in
                
                cell.center = CGPointMake(cell.center.x-100, cell.center.y)
            }
        }
    }
    
    
    internal func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return userList.count
    }
    
    internal func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.Delete {
            userList.removeAtIndex(indexPath.row)
        }
    
        userDefaults.setObject(userList, forKey: "userList")
        
        table.reloadData()
    }
    
    internal func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let index = userList.count - 1 - indexPath.row
        let photoToDisplay = userList[index]["photo"] as! PFFile
        photoToDisplay.getDataInBackgroundWithBlock { (photoData, photoConvError) -> Void in
            
            if photoConvError != nil {
                
                print("Error converting photo from file: " + photoConvError!.description)
            }
            else {
                
                //Configure and display image for user
                self.snap.image = UIImage(data: photoData!)
                self.snap.alpha = 1
                
                //Deselect row
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
            }
        }
    }
    
    internal func delay(delay: Double, closure:()->()) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
    }
    
    
    internal func segueToNextView(identifier: String) {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            self.dismissViewControllerAnimated(true, completion: nil)
            self.performSegueWithIdentifier(identifier, sender: self)
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if(segue.identifier == "MainToCamera") {
            let nextView = segue.destinationViewController as! CameraController
            nextView.userName = self.userName
            nextView.userEmail = self.userEmail
        }
        else if(segue.identifier == "MainToSettings") {
            let nextView = segue.destinationViewController as! SettingsController
            nextView.userName = self.userName
            nextView.userEmail = self.userEmail
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var countryTable = [["Afghanistan","af"],
        ["Åland Islands","ax"],
        ["Albania","al"],
        ["Algeria","dz"],
        ["American Samoa","as"],
        ["Andorra","ad"],
        ["Angola","ao"],
        ["Anguilla","ai"],
        ["Antarctica","aq"],
        ["Antigua and Barbuda","ag"],
        ["Argentina","ar"],
        ["Armenia","am"],
        ["Aruba","aw"],
        ["Australia","au"],
        ["Austria","at"],
        ["Azerbaijan","az"],
        ["Bahamas","bs"],
        ["Bahrain","bh"],
        ["Bangladesh","bd"],
        ["Barbados","bb"],
        ["Belarus","by"],
        ["Belgium","be"],
        ["Belize","bz"],
        ["Benin","bj"],
        ["Bermuda","bm"],
        ["Bhutan","bt"],
        ["Bolivia","bo"],
        ["Bonaire, Sint Eustatius and Saba","bq"],
        ["Bosnia and Herzegovina","ba"],
        ["Botswana","bw"],
        ["Bouvet Island","bv"],
        ["Brazil","br"],
        ["British Indian Ocean Territory","io"],
        ["Brunei Darussalam","bn"],
        ["Bulgaria","bg"],
        ["Burkina Faso","bf"],
        ["Burundi","bi"],
        ["Cambodia","kh"],
        ["Cameroon","cm"],
        ["Canada","ca"],
        ["Cabo Verde","cv"],
        ["Cayman Islands","ky"],
        ["Central African Republic","cf"],
        ["Chad","td"],
        ["Chile","cl"],
        ["China","cn"],
        ["Christmas Island","cx"],
        ["Cocos (Keeling) Islands","cc"],
        ["Colombia","co"],
        ["Comoros","km"],
        ["Congo","cg"],
        ["Congo","cd"],
        ["Cook Islands","ck"],
        ["Costa Rica","cr"],
        ["Côte d'Ivoire","ci"],
        ["Croatia","hr"],
        ["Cuba","cu"],
        ["Curaçao","cw"],
        ["Cyprus","cy"],
        ["Czech Republic","cz"],
        ["Denmark","dk"],
        ["Djibouti","dj"],
        ["Dominica","dm"],
        ["Dominican Republic","do"],
        ["Ecuador","ec"],
        ["Egypt","eg"],
        ["El Salvador","sv"],
        ["Equatorial Guinea","gq"],
        ["Eritrea","er"],
        ["Estonia","ee"],
        ["Ethiopia","et"],
        ["Falkland Islands (Malvinas)","fk"],
        ["Faroe Islands","fo"],
        ["Fiji","fj"],
        ["Finland","fi"],
        ["France","fr"],
        ["French Guiana","gf"],
        ["French Polynesia","pf"],
        ["French Southern Territories","tf"],
        ["Gabon","ga"],
        ["Gambia","gm"],
        ["Georgia","ge"],
        ["Germany","de"],
        ["Ghana","gh"],
        ["Gibraltar","gi"],
        ["Greece","gr"],
        ["Greenland","gl"],
        ["Grenada","gd"],
        ["Guadeloupe","gp"],
        ["Guam","gu"],
        ["Guatemala","gt"],
        ["Guernsey","gg"],
        ["Guinea","gn"],
        ["Guinea-Bissau","gw"],
        ["Guyana","gy"],
        ["Haiti","ht"],
        ["Heard Island and McDonald Islands","hm"],
        ["Holy See","va"],
        ["Honduras","hn"],
        ["Hong Kong","hk"],
        ["Hungary","hu"],
        ["Iceland","is"],
        ["India","in"],
        ["Indonesia","id"],
        ["Iran","ir"],
        ["Iraq","iq"],
        ["Ireland","ie"],
        ["Isle of Man","im"],
        ["Israel","il"],
        ["Italy","it"],
        ["Jamaica","jm"],
        ["Japan","jp"],
        ["Jersey","je"],
        ["Jordan","jo"],
        ["Kazakhstan","kz"],
        ["Kenya","ke"],
        ["Kiribati","ki"],
        ["North Korea","kp"],
        ["South Korea","kr"],
        ["Kuwait","kw"],
        ["Kyrgyzstan","kg"],
        ["Lao People's Democratic Republic","la"],
        ["Latvia","lv"],
        ["Lebanon","lb"],
        ["Lesotho","ls"],
        ["Liberia","lr"],
        ["Libya","ly"],
        ["Liechtenstein","li"],
        ["Lithuania","lt"],
        ["Luxembourg","lu"],
        ["Macao","mo"],
        ["Macedonia ","mk"],
        ["Madagascar","mg"],
        ["Malawi","mw"],
        ["Malaysia","my"],
        ["Maldives","mv"],
        ["Mali","ml"],
        ["Malta","mt"],
        ["Marshall Islands","mh"],
        ["Martinique","mq"],
        ["Mauritania","mr"],
        ["Mauritius","mu"],
        ["Mayotte","yt"],
        ["Mexico","mx"],
        ["Micronesia","fm"],
        ["Moldova","md"],
        ["Monaco","mc"],
        ["Mongolia","mn"],
        ["Montenegro","me"],
        ["Montserrat","ms"],
        ["Morocco","ma"],
        ["Mozambique","mz"],
        ["Myanmar","mm"],
        ["Namibia","na"],
        ["Nauru","nr"],
        ["Nepal","np"],
        ["Netherlands","nl"],
        ["New Caledonia","nc"],
        ["New Zealand","nz"],
        ["Nicaragua","ni"],
        ["Niger","ne"],
        ["Nigeria","ng"],
        ["Niue","nu"],
        ["Norfolk Island","nf"],
        ["Northern Mariana Islands","mp"],
        ["Norway","no"],
        ["Oman","om"],
        ["Pakistan","pk"],
        ["Palau","pw"],
        ["Palestine, State of","ps"],
        ["Panama","pa"],
        ["Papua New Guinea","pg"],
        ["Paraguay","py"],
        ["Peru","pe"],
        ["Philippines","ph"],
        ["Pitcairn","pn"],
        ["Poland","pl"],
        ["Portugal","pt"],
        ["Puerto Rico","pr"],
        ["Qatar","qa"],
        ["Réunion","re"],
        ["Romania","ro"],
        ["Russian Federation","ru"],
        ["Rwanda","rw"],
        ["Saint Barthélemy","bl"],
        ["Saint Helena, Ascension and Tristan da Cunha","sh"],
        ["Saint Kitts and Nevis","kn"],
        ["Saint Lucia","lc"],
        ["Saint Martin (French part)","mf"],
        ["Saint Pierre and Miquelon","pm"],
        ["Saint Vincent and the Grenadines","vc"],
        ["Samoa","ws"],
        ["San Marino","sm"],
        ["Sao Tome and Principe","st"],
        ["Saudi Arabia","sa"],
        ["Senegal","sn"],
        ["Serbia","rs"],
        ["Seychelles","sc"],
        ["Sierra Leone","sl"],
        ["Singapore","sg"],
        ["Sint Maarten (Dutch part)","sx"],
        ["Slovakia","sk"],
        ["Slovenia","si"],
        ["Solomon Islands","sb"],
        ["Somalia","so"],
        ["South Africa","za"],
        ["South Georgia and the South Sandwich Islands","gs"],
        ["South Sudan","ss"],
        ["Spain","es"],
        ["Sri Lanka","lk"],
        ["Sudan","sd"],
        ["Suriname","sr"],
        ["Svalbard and Jan Mayen","sj"],
        ["Swaziland","sz"],
        ["Sweden","se"],
        ["Switzerland","ch"],
        ["Syrian Arab Republic","sy"],
        ["Taiwan","tw"],
        ["Tajikistan","tj"],
        ["Tanzania","tz"],
        ["Thailand","th"],
        ["Timor-Leste","tl"],
        ["Togo","tg"],
        ["Tokelau","tk"],
        ["Tonga","to"],
        ["Trinidad and Tobago","tt"],
        ["Tunisia","tn"],
        ["Turkey","tr"],
        ["Turkmenistan","tm"],
        ["Turks and Caicos Islands","tc"],
        ["Tuvalu","tv"],
        ["Uganda","ug"],
        ["Ukraine","ua"],
        ["United Arab Emirates","ae"],
        ["United Kingdom","gb"],
        ["United States of America","us"],
        ["United States Minor Outlying Islands","um"],
        ["Uruguay","uy"],
        ["Uzbekistan","uz"],
        ["Vanuatu","vu"],
        ["Venezuela","ve"],
        ["Vietnam","vn"],
        ["Virgin Islands (British)","vg"],
        ["Virgin Islands (U.S.)","vi"],
        ["Wallis and Futuna","wf"],
        ["Western Sahara","eh"],
        ["Yemen","ye"],
        ["Zambia","zm"],
        ["Zimbabwe","zw"]]
}
