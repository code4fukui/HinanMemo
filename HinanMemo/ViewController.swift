//
//  ViewController.swift
//  HinanMemo
//
//  Created by taisuke on 2016/04/16.
//  Copyright © 2016年 taisuke. All rights reserved.
//

import UIKit
import CoreData // for write, read & delete
import CoreLocation // for GPS

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {

    @IBOutlet weak var btnget: UIButton!
    @IBOutlet weak var btnclear: UIButton!
    @IBOutlet weak var listItems: UITableView!
    
    private var items: NSArray = [ ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        listItems.registerClass(UITableViewCell.self, forCellReuseIdentifier: "MyCell") // MyCell である必要あり
        listItems.dataSource = self
        listItems.delegate = self
        
        
        if let data: NSString = readData() {
            print(data)
            showJSON(data)
        }
    }
    @IBAction func actionGet(sender: AnyObject) {
        print(btnget.titleLabel)
        if let label = btnget!.titleLabel!.text {
            if label == "ゲット" {
                btnget.setTitle("取得中", forState: .Normal)
                getGPS()
            }
        }
    }
    @IBAction func actionClear(sender: AnyObject) {
        items = []
        listItems.reloadData()
        print("actionClear");
        btnget.setTitle("ゲット", forState: .Normal)
    }
    // alert
    func alert(str: String) {
        let alertController = UIAlertController(title: "", message: str, preferredStyle: .Alert)
        let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(defaultAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    // GPS
    var lm: CLLocationManager!
    func getGPS() {
        lm = CLLocationManager()
        lm.delegate = self
//        lm.requestAlwaysAuthorization()
//        lm.requestWhenInUseAuthorization()
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedWhenInUse {
            lm.requestWhenInUseAuthorization()
        }
        lm.desiredAccuracy = kCLLocationAccuracyBest // 精度
        // lm.distanceFilter = 1000 // 指定m移動したら更新
//        lm.startUpdatingLocation()
        lm.requestLocation() // one shot
    }
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let lat: CLLocationDegrees = location.coordinate.latitude
            let lng: CLLocationDegrees = location.coordinate.longitude
            NSLog("latiitude: \(lat) , longitude: \(lng)")
            
            //        let lat = 35.94
            //      let lng = 135.18
            let q = getSPARQL(lat, longitude: lng)
            print(q)
            querySPARQL(q)
                //      self.deleteData()
                //        self.writeData("{ \"items\": [ \"a\", \"b\", \"c\" ] }")
        }
        
    }
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        alert("位置情報が取得できなかったため鯖江駅を使用します")
        print("error GPS")
        
        // エラーの時は鯖江駅周辺
        let lat = 35.94
        let lng = 136.18
        let q = getSPARQL(lat, longitude: lng)
        print(q)
        querySPARQL(q)
    }
    // JSON
    func showJSON(json:NSString) {
        print(json)
        do {
            let data = json.dataUsingEncoding(NSUTF8StringEncoding)
            let dict = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers) as! NSDictionary
            
            let results = dict.objectForKey("results") as! NSDictionary
            items = results.objectForKey("bindings") as! NSArray
            for i in 0 ..< items.count {
                let item = items[i]
                let name = item.objectForKey("name") as! NSDictionary
                print(name.objectForKey("value") as! String)
            }
            listItems.reloadData()
        } catch {
            print("showJSON error")
        }
        btnget.setTitle("ゲット", forState: .Normal)
    }
    func getSPARQL(lat: Double, longitude lng: Double) -> String {
        let TYPE = "http://purl.org/jrrk#EmergencyFacility"
        let dll = 0.01
        let latmin = lat - dll
        let latmax = lat + dll
        let lngmin = lng - dll
        let lngmax = lng + dll
        let q =
            "PREFIX geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>\n" +
            "PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n" +
            "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>\n" +
            "select ?s ?name ?lat ?lng ?type ?desc ?url {\n" +
            "{" +
            "?s rdf:type <" + TYPE + ">;\n" +
            "rdf:type ?type;\n" +
            "rdfs:label ?name;\n" +
            "geo:lat ?lat;\n" +
            "geo:long ?lng.\n" +
            " filter(?lat<\(latmax) && ?lat>\(latmin) && ?lng<\(lngmax) && ?lng>\(lngmin))\n" +
            "filter(lang(?name)=\"ja\")" +
            "}}"
        // + " limit 10"
        print(q)
        return q
    }
    func querySPARQL(sparql: String) {
        let base = "http://sparql.odp.jig.jp/data/sparql"
        var body = "output=json&app=dev2&query="
        let sparql2 = sparql.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        body += sparql2.stringByReplacingOccurrencesOfString("&", withString: "%26")
        
        print(body)
        
        let url = NSURL(string: base)
        let req = NSMutableURLRequest(URL: url!)
        req.HTTPMethod = "POST"
        req.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate:nil, delegateQueue:NSOperationQueue.mainQueue())
        
        let task = session.dataTaskWithRequest(req, completionHandler: {
            (data, response, error) -> Void in
            if let d = data {
                if let json = NSString(data:d, encoding:NSUTF8StringEncoding) {
                    self.deleteData()
                    self.writeData(json as String)
                
                    self.showJSON(json)
                
                }
            }
        })
        task.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let item = items[indexPath.row]
        let latc = item.objectForKey("lat") as! NSDictionary
        let lat = latc.objectForKey("value") as! String
        let lngc = item.objectForKey("lng") as! NSDictionary
        let lng = lngc.objectForKey("value") as! String
        
        print("Num: \(indexPath.row) \(lat) \(lng)")
        //        print("Value: \(items[indexPath.row])")
        

//        let url = NSURL(string: "http://maps.gsi.go.jp/#18/\(lat)/\(lng)")
        let url = NSURL(string: "https://www.google.com/maps?ll=\(lat),\(lng)")
        if UIApplication.sharedApplication().canOpenURL(url!){
            UIApplication.sharedApplication().openURL(url!)
        }
    }
    
    // table
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let name = item.objectForKey("name") as! NSDictionary
        let val = name.objectForKey("value") as! String
//        print(name.objectForKey("value" as! String)

        let cell = tableView.dequeueReusableCellWithIdentifier("MyCell", forIndexPath: indexPath)
        cell.textLabel!.text = val // "\(items[indexPath.row])"
        return cell
    }
    
    // CoreData write & read & delete
    func writeData(json: String) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let data = NSEntityDescription.insertNewObjectForEntityForName("Entity", inManagedObjectContext: appDelegate.managedObjectContext) as! Entity
        
        data.json = json
        
        appDelegate.saveContext()
    }
    func readData() -> String? {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        
        do {
            let datas = try appDelegate.managedObjectContext.executeFetchRequest(fetchRequest) as! [Entity]
            
            for data in datas {
                print(data.json)
                return data.json
            }
        } catch let error as NSError {
            print(error)
            return nil
        }
        print("none data")
        return nil
    }
    func deleteData() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context: NSManagedObjectContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Entity")
        
        do {
            let datas = try appDelegate.managedObjectContext.executeFetchRequest(fetchRequest) as! [Entity]
            
            for data in datas {
                context.deleteObject(data)
            }
            appDelegate.saveContext()
        } catch let error as NSError {
            print(error)
        }
    }
}


