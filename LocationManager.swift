//
//  LocationManager.swift
//
//
//  Created by Jimmy Jose on 14/08/14.
//  Copyright (c) 2014 Varshyl Mobile Pvt. Ltd. All rights reserved.
//

import UIKit
import CoreLocation

typealias LMReverseGeocodeCompletionHandler = ((address:NSDictionary?, error:String?)->Void)?
typealias LMGeocodeCompletionHandler = ((address:NSDictionary?, error:String?)->Void)?
typealias LMLocationCompletionHandler = ((latitude:Double, longitude:Double, status:String, verboseMessage:String, error:String?)->())?




class LocationManager: NSObject,CLLocationManagerDelegate {
    
    private var completionHandler:LMLocationCompletionHandler
    
    private var reverseGeocodingCompletionHandler:LMReverseGeocodeCompletionHandler
    private var geocodingCompletionHandler:LMGeocodeCompletionHandler
    
    private var locationStatus : NSString = "Calibrating"// to pass in handler
    
    
    var delegate:LocationManagerDelegate? = nil
    
    var latitude:Double = 0.0
    var longitude:Double = 0.0
    
    var latitudeAsString:String = ""
    var longitudeAsString:String = ""
    
    
    var lastKnownLatitude:Double = 0.0
    var lastKnownLongitude:Double = 0.0
    
    var lastKnownLatitudeAsString:String = ""
    var lastKnownLongitudeAsString:String = ""
    
    
    var keepLastKnownLocation:Bool = true
    var hasLastKnownLocation:Bool = true
    
    var autoUpdate:Bool = false
    
    private var locationManager: CLLocationManager!
    
    var showVerboseMessage = false
    
    
    private var verboseMessage = "Calibrating"
    
    private let verboseMessageDictionary = [CLAuthorizationStatus.NotDetermined:"You have not yet made a choice with regards to this application.",
        CLAuthorizationStatus.Restricted:"This application is not authorized to use location services. Due to active restrictions on location services, the user cannot change this status, and may not have personally denied authorization.",
        CLAuthorizationStatus.Denied:"You have explicitly denied authorization for this application, or location services are disabled in Settings.",
        CLAuthorizationStatus.Authorized:"App is Authorized to use location services.",CLAuthorizationStatus.AuthorizedWhenInUse:"You have granted authorization to use your location only when the app is visible to you."]
    
    
    class var sharedInstance : LocationManager {
    struct Static {
        static let instance : LocationManager = LocationManager()
        }
        return Static.instance
    }
    
    
    
    private override init(){
        
        super.init()
        
        if(!autoUpdate){
            autoUpdate = !CLLocationManager.significantLocationChangeMonitoringAvailable()
        }
        
    }
    
    private func resetLatLon(){
        
        latitude = 0.0
        longitude = 0.0
        
        latitudeAsString = ""
        longitudeAsString = ""
        
    }
    
    private func resetLastKnownLatLon(){
        
        hasLastKnownLocation = false
        
        lastKnownLatitude = 0.0
        lastKnownLongitude = 0.0
        
        lastKnownLatitudeAsString = ""
        lastKnownLongitudeAsString = ""
        
    }
    
    func startUpdatingLocation(completionHandler:((latitude:Double, longitude:Double, status:String, verboseMessage:String, error:String?)->())? = nil){
        
        self.completionHandler = completionHandler
        
        initLocationManager()
    }
    
    
    func startUpdatingLocation(){
        
        initLocationManager()
    }
    
    func stopUpdatingLocation(){
        if(autoUpdate){
            locationManager.stopUpdatingLocation()
        }else{
            
            locationManager.stopMonitoringSignificantLocationChanges()
        }
        
        
        resetLatLon()
        if(!keepLastKnownLocation){
            resetLastKnownLatLon()
        }
    }
    
    private func initLocationManager() {
        
        // App might be unreliable if someone changes autoupdate status in between and stops it
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        // locationManager.locationServicesEnabled
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        //check for iOS8 thingy in next update
        //locationManager.requestAlwaysAuthorization()
        
        if(autoUpdate){
            
            locationManager.startUpdatingLocation()
        }else{
            
            locationManager.startMonitoringSignificantLocationChanges()
        }
        
        
    }
    
    
    internal func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        
        locationManager.stopUpdatingLocation()
        resetLatLon()
        if(!keepLastKnownLocation){
            
            resetLastKnownLatLon()
        }
        
        var verbose = ""
        if showVerboseMessage {verbose = verboseMessage}
        completionHandler?(latitude: 0.0, longitude: 0.0, status: locationStatus, verboseMessage:verbose,error: error.localizedDescription)
        
        if ((delegate? != nil) && (delegate?.respondsToSelector(Selector("locationManagerReceivedError:")))!){
            delegate?.locationManagerReceivedError!(error.localizedDescription)
        }
    }
    
    internal func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        
        var arrayOfLocation = locations as NSArray
        var location = arrayOfLocation.lastObject as CLLocation
        var coordLatLon = location.coordinate
        
        latitude  = coordLatLon.latitude
        longitude = coordLatLon.longitude
        
        latitudeAsString  = coordLatLon.latitude.description
        longitudeAsString = coordLatLon.longitude.description
        
        var verbose = ""
        if showVerboseMessage {verbose = verboseMessage}
        completionHandler?(latitude: latitude, longitude: longitude, status: locationStatus,verboseMessage:verbose, error: nil)
        
        lastKnownLatitude = coordLatLon.latitude
        lastKnownLongitude = coordLatLon.longitude
        
        lastKnownLatitudeAsString = coordLatLon.latitude.description
        lastKnownLongitudeAsString = coordLatLon.longitude.description
        
        hasLastKnownLocation = true
        
        if (delegate? != nil){
            if((delegate?.respondsToSelector(Selector("locationFoundGetAsString:longitude:")))!){
                delegate?.locationFoundGetAsString!(latitudeAsString,longitude:longitudeAsString)
            }
            if((delegate?.respondsToSelector(Selector("locationFound:longitude:")))!){
                delegate?.locationFound(latitude,longitude:longitude)
            }
        }
    }
    
    
    internal func locationManager(manager: CLLocationManager!,
        didChangeAuthorizationStatus status: CLAuthorizationStatus) {
            var hasAuthorised = false
            var verboseKey = status
            switch status {
            case CLAuthorizationStatus.Restricted:
                locationStatus = "Restricted Access"
            case CLAuthorizationStatus.Denied:
                locationStatus = "Denied access"
            case CLAuthorizationStatus.NotDetermined:
                locationStatus = "Not determined"
            default:
                locationStatus = "Allowed access"
                hasAuthorised = true
            }
            
            verboseMessage = verboseMessageDictionary[verboseKey]!
            
            if (hasAuthorised == true) {
                if(autoUpdate){
                    
                    locationManager.startUpdatingLocation()
                }else{
                    
                    locationManager.startMonitoringSignificantLocationChanges()
                }
            }else{
                
                resetLatLon()
                if (!locationStatus.isEqualToString("Denied access")){
                    
                    var verbose = ""
                    if showVerboseMessage {
                        
                        verbose = verboseMessage
                        
                        if ((delegate? != nil) && (delegate?.respondsToSelector(Selector("locationManagerVerboseMessage:")))!){
                            
                            delegate?.locationManagerVerboseMessage!(verbose)
                            
                        }
                    }
                    completionHandler?(latitude: latitude, longitude: longitude, status: locationStatus, verboseMessage:verbose,error: nil)
                }
                if ((delegate? != nil) && (delegate?.respondsToSelector(Selector("locationManagerStatus:")))!){
                    delegate?.locationManagerStatus!(locationStatus)
                }
            }
            
    }
    
    func reverseGeocodeLocationWithLatLon(#latitude:Double, longitude: Double,onReverseGeocodingCompletionHandler:((address:NSDictionary?, error:String?)->Void)?){
        
        var location:CLLocation = CLLocation(latitude:latitude, longitude: longitude)
        reverseGeocodeLocationWithCoordinates(location,onReverseGeocodingCompletionHandler)
        
        
    }
    
    func reverseGeocodeLocationWithCoordinates(coord:CLLocation, onReverseGeocodingCompletionHandler:((address:NSDictionary?, error:String?)->Void)?){
        
        
        self.reverseGeocodingCompletionHandler = onReverseGeocodingCompletionHandler
        
        
        reverseGocode(coord)
    }
    
    private func reverseGocode(location:CLLocation){
        
        var geocoder: CLGeocoder = CLGeocoder()
        
        
        geocoder.reverseGeocodeLocation(location, completionHandler: {(placemarks, error)->Void in
            
            if error {
                self.reverseGeocodingCompletionHandler!(address:nil, error: error.localizedDescription)
                
                return
            }
            
            if let placemark = placemarks?[0] as? CLPlacemark {
                var address = AddressParser()
                address.parseAppleLocationData(placemark)
                let addressDict = address.addressDictionary()
                self.reverseGeocodingCompletionHandler!(address: addressDict,error: nil)
            }
            else {
                self.reverseGeocodingCompletionHandler!(address: nil,error: "No Placemarks Found!")
                return
            }
            
        })
        
        
    }
    
    
    
    func geocodeAddressString(#address:NSString, onGeocodingCompletionHandler:((address:NSDictionary?, error:String?)->Void)?){
        
        
        self.geocodingCompletionHandler = onGeocodingCompletionHandler
        
        
        geoCodeAddress(address)
    }
    
    
    
    private func geoCodeAddress(address:NSString){
        
        var geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address, {(placemarks: [AnyObject]!, error: NSError!) -> Void in
            
            
            if error {
                
                self.geocodingCompletionHandler!(address:nil, error: error.localizedDescription)
                
                return
            }
            
            if let placemark = placemarks?[0] as? CLPlacemark {
                
                var address = AddressParser()
                address.parseAppleLocationData(placemark)
                let addressDict = address.addressDictionary()
                self.geocodingCompletionHandler!(address: addressDict,error: nil)
            }
            else {
                
                self.geocodingCompletionHandler!(address: nil,error: "invalid address: \(address)")
                return
            }
            
            
        })
        
        
    }
    
    
    func geocodeUsingGoogleAddressString(#address:NSString, onGeocodingCompletionHandler:((address:NSDictionary?, error:String?)->Void)?){
        
        
        self.geocodingCompletionHandler = onGeocodingCompletionHandler
        
        
        geoCodeUsignGoogleAddress(address)
    }
    
    
    private func geoCodeUsignGoogleAddress(address:NSString){
        
        var urlString = "http://maps.googleapis.com/maps/api/geocode/json?address=\(address)&sensor=true" as NSString
        
        urlString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        
        let url:NSURL = NSURL(string:urlString)
        
        let request:NSURLRequest = NSURLRequest(URL:url)
        
        let queue:NSOperationQueue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request,queue:queue,completionHandler:{response,data,error in
            
            if(error){
                
                self.geocodingCompletionHandler!(address: nil,error: error.localizedDescription)
                
            }else{
                
                var dataAsString: NSString = NSString(data: data, encoding: NSUTF8StringEncoding)
                
                // Convert the retrieved data in to an object through JSON deserialization
                var err: NSError
                var jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                
                var status = jsonResult.valueForKey("status") as NSString
                if((status.lowercaseString as NSString).isEqualToString("ok")){
                    var address = AddressParser()
                    address.parseGoogleLocationData(jsonResult)
                    let addressDict = address.addressDictionary()
                    self.geocodingCompletionHandler!(address: addressDict,error: nil)
                    
                }else{
                    
                    self.geocodingCompletionHandler!(address: nil,error: "invalid address: \(address)")
                    
                }
                
            }
            }
            
            
        )
        
        
    }
    
    func reverseGeocodeLocationUsingGoogleWithLatLon(#latitude:Double, longitude: Double,onReverseGeocodingCompletionHandler:((address:NSDictionary?, error:String?)->Void)?){
        
        self.reverseGeocodingCompletionHandler = onReverseGeocodingCompletionHandler
        reverseGocodeUsingGoogle(latitude:latitude,longitude: longitude)
        
        
    }
    
    func reverseGeocodeLocationUsingGoogleWithCoordinates(coord:CLLocation, onReverseGeocodingCompletionHandler:((address:NSDictionary?, error:String?)->Void)?){
        
        
        reverseGeocodeLocationUsingGoogleWithLatLon(latitude: coord.coordinate.latitude, longitude: coord.coordinate.longitude, onReverseGeocodingCompletionHandler: onReverseGeocodingCompletionHandler)
        
        
        
    }
    
    
    private func reverseGocodeUsingGoogle(#latitude:Double, longitude: Double){
    
        var urlString = "http://maps.googleapis.com/maps/api/geocode/json?latlng=\(latitude),\(longitude)&sensor=true" as NSString
        
        urlString = urlString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        
    
        let url:NSURL = NSURL(string:urlString)
        
        let request:NSURLRequest = NSURLRequest(URL:url)
        
        let queue:NSOperationQueue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request,queue:queue,completionHandler:{response,data,error in
            
            if(error){
             
                self.reverseGeocodingCompletionHandler!(address: nil,error: error.localizedDescription)
                
            }else{
               
                var dataAsString: NSString = NSString(data: data, encoding: NSUTF8StringEncoding)
                
                // Convert the retrieved data in to an object through JSON deserialization
                var err: NSError
                var jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
              
                var status = jsonResult.valueForKey("status") as NSString
                if((status.lowercaseString as NSString).isEqualToString("ok")){
                var address = AddressParser()
                address.parseGoogleLocationData(jsonResult)
                let addressDict = address.addressDictionary()
                self.reverseGeocodingCompletionHandler!(address: addressDict,error: nil)
                
                }else{
                
                    self.reverseGeocodingCompletionHandler!(address: nil,error: "invalid latitude: \(latitude) & longitude: \(longitude)")
                
                }
                
            }
            }
            
            
        )

    
    }
    
    
}


@objc protocol LocationManagerDelegate : NSObjectProtocol
{
    func locationFound(latitude:Double, longitude:Double)
    optional func locationFoundGetAsString(latitude:NSString, longitude:NSString)
    optional func locationManagerStatus(status:NSString)
    optional func locationManagerReceivedError(error:NSString)
    optional func locationManagerVerboseMessage(message:NSString)
}

private class AddressParser: NSObject{
    
    var latitude = NSString()
    var longitude  = NSString()
    var streetNumber = NSString()
    var route = NSString()
    var locality = NSString()
    var subLocality = NSString()
    var formattedAddress = NSString()
    var administrativeArea = NSString()
    var postalCode = NSString()
    var country = NSString()
    
    override init(){
        
        super.init()
        
    }
    
    func addressDictionary()-> NSDictionary{
        
        var addressDict = NSMutableDictionary()
        
        addressDict.setValue(latitude, forKey: "latitude")
        addressDict.setValue(longitude, forKey: "longitude")
        addressDict.setValue(streetNumber, forKey: "streetNumber")
        addressDict.setValue(locality, forKey: "locality")
        addressDict.setValue(subLocality, forKey: "subLocality")
        addressDict.setValue(administrativeArea, forKey: "administrativeArea")
        addressDict.setValue(postalCode, forKey: "postalCode")
        addressDict.setValue(country, forKey: "country")
        addressDict.setValue(formattedAddress, forKey: "formattedAddress")
        
        return addressDict
    }
    
    
    func parseAppleLocationData(placemark:CLPlacemark){
        
        var addressLines = placemark.addressDictionary["FormattedAddressLines"] as NSArray
        
        //self.streetNumber = placemark.subThoroughfare ? placemark.subThoroughfare : ""
        self.streetNumber = placemark.thoroughfare ? placemark.thoroughfare : ""
        self.locality = placemark.locality ? placemark.locality : ""
        self.postalCode = placemark.postalCode ? placemark.postalCode : ""
        self.subLocality = placemark.subLocality ? placemark.subLocality : ""
        self.administrativeArea = placemark.administrativeArea ? placemark.administrativeArea : ""
        self.country = placemark.country ?  placemark.country : ""
        self.longitude = placemark.location.coordinate.longitude.description;
        self.latitude = placemark.location.coordinate.latitude.description
        if(addressLines != nil && addressLines.count>0){
            self.formattedAddress = addressLines.componentsJoinedByString(", ")}
        else{
            self.formattedAddress = ""
        }
        
        
    }
    
    
    func parseGoogleLocationData(resultDict:NSDictionary){
        
        
        var status = resultDict.valueForKey("status") as NSString
        
        if((status.lowercaseString as NSString).isEqualToString("ok")){
            
            let locationDict = (resultDict.valueForKey("results") as NSArray).firstObject as NSDictionary
            
            let formattedAddrs = locationDict.objectForKey("formatted_address") as NSString
            
            var geometry = locationDict.objectForKey("geometry") as NSDictionary
            var location = geometry.objectForKey("location") as NSDictionary
            var lat = location.objectForKey("lat") as Double
            var lng = location.objectForKey("lat") as Double
            
            
            self.latitude = lat.description
            self.longitude = lng.description
            
            let addressComponents = locationDict.objectForKey("address_components") as NSArray
            
            component("street_number", inArray: addressComponents, ofType: "long_name")
            
            self.streetNumber = component("street_number", inArray: addressComponents, ofType: "long_name")
            
            self.route = component("route", inArray: addressComponents, ofType: "long_name")
            
            self.locality = component("locality", inArray: addressComponents, ofType: "long_name")
            
            self.subLocality = component("subLocality", inArray: addressComponents, ofType: "long_name")
            
            self.administrativeArea = component("administrative_area_level_1", inArray: addressComponents, ofType: "long_name")
            
            self.postalCode = component("postal_code", inArray: addressComponents, ofType: "short_name")
            
            self.country =  component("country", inArray: addressComponents, ofType: "long_name")
            
            self.formattedAddress = formattedAddrs;
            
        }
        else{
            
            
            
        }
        
    }
    
    func component(component:NSString,inArray:NSArray,ofType:NSString) -> NSString{
        var index:NSInteger = inArray.indexOfObjectPassingTest { (obj, idx, stop) -> Bool in
            
            var objDict:NSDictionary = obj as NSDictionary
            var types:NSArray = objDict.objectForKey("types") as NSArray
            let type = types.firstObject as NSString
            return type.isEqualToString(component)
            
        }
        
        if (index == NSNotFound){
            
            return ""
        }
        if (index >= inArray.count){
            return ""
        }
        
        var type = (inArray.objectAtIndex(index) as NSDictionary).valueForKey(ofType)! as NSString
        if (type != nil){
            
            return type
        }
        return ""
        
    }
    
}

