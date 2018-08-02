//
//  ViewController.swift
//  Neighborhoods
//
//  Created by Ezra Celli on 5/20/18.
//  Copyright © 2018 Ezra Celli. All rights reserved.
//

import UIKit
import os.log
import MapboxGeocoder
import GoogleMobileAds

class ViewController: UIViewController, CLLocationManagerDelegate, GADBannerViewDelegate {
    
    //MARK: Properties
    let locationManager = CLLocationManager()
    // Access token for MapboxGeocoder
    let accessToken = "pk.eyJ1IjoiZXpyYWNlbGxpIiwiYSI6ImNqaGV0bDQzeDEwcWkzY3BlYnl0d3NqOHUifQ.lm_X6rvI5XZ8j_KVIYDT_w"
    // Application ID for GoogleMobileAds
    let adUnitID = "ca-app-pub-2386564496666365/2255436012"
    // Test ID:
    //let adUnitID = "ca-app-pub-3940256099942544/2934735716"
    
    // MARK: Outlets
    @IBOutlet weak var neighborhoodLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var bannerView: GADBannerView!
    
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get current location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Configure bannerView properties
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        bannerView.delegate = self
    }
    
    // MARK: CLLocationManager delegate functions
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Retrieve current location
        let location = locations.first
        
        // Safely unwrap latitude and longitude for current location
        if let latitude = location?.coordinate.latitude, let longitude = location?.coordinate.longitude {
            
            // Get neighborhood for current location
            let myLocation = CLLocationCoordinate2DMake(latitude, longitude)
            getNeighborhood(location: myLocation)
        }
        
        // Stop updating location
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: GADBannerView delegate functions
    // Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")
        
        // Add banner to view and add constraints as above.
        //addBannerViewToView(bannerView)
        
        // Animate a banner ad
        bannerView.alpha = 0
        UIView.animate(withDuration: 1, animations: {
            bannerView.alpha = 1
        })
    }
    
    // Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    // Tells the delegate that a full-screen view will be presented in response to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    // Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    // Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    // Tells the delegate that a user click will open another app (such as the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
    
    // MARK: Private Functions
    private func getNeighborhood(location: CLLocationCoordinate2D) {
        
        // Initialize a geocoder object using the access token
        let geocoder = Geocoder(accessToken: accessToken)
        
        let options = ReverseGeocodeOptions(coordinate: location)
        geocoder.geocode(options) { (placemarks, attribution, error) in
            guard let placemark = placemarks?.first else {
                return
            }
            
            // Display neighborhood for location; add a link to neighborhood Wikipedia page
            self.neighborhoodLabel.text = placemark.neighborhood?.name ?? "'Hood"
            self.neighborhoodLabel.numberOfLines = 0
            if self.neighborhoodLabel.text != "'Hood" {
                let tap = UITapGestureRecognizer(target: self, action: #selector(self.onClick(sender:)))
                self.neighborhoodLabel.addGestureRecognizer(tap)
                self.neighborhoodLabel.isUserInteractionEnabled = true
                self.neighborhoodLabel.textColor = UIColor(red: 0.0, green: 122/255, blue: 1.0, alpha: 1.0)
                self.neighborhoodLabel.underline()
            }
            
            // Display city for location
            self.cityLabel.text = placemark.place?.name ?? "City"
        }
        
        
        // If neighborhood or city could not be updated, display an alert apologizing for the problem
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4), execute: {
            if self.neighborhoodLabel.text == "'Hood" && self.cityLabel.text == "City" {
                self.apologyAlertController(problem: "location")
            } else if self.neighborhoodLabel.text == "'Hood" {
                self.apologyAlertController(problem: "neighborhood")
            } else if self.cityLabel.text == "City" {
                self.apologyAlertController(problem: "city")
            }
        })
    }
    
    private func apologyAlertController(problem: String) {
        let title = "Sorry!"
        let message = "Your current \(problem) could not be determined."
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        
        present(alertController, animated: true)
    }
    
    @objc private func onClick(sender: UITapGestureRecognizer) {
        let wikiURL = "https://www.google.com/search?q=\(neighborhoodLabel.text ?? "") \(cityLabel.text ?? "")"
        openURL(URLString: wikiURL)
    }

    private func openURL(URLString: String) {
        guard let escapedURLString = URLString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            os_log("URLString unable to be escaped", log: .default, type: .error)
            return
        }
        guard let url = URL(string: escapedURLString) else {
            os_log("escapedURLString unable to be converted to a URL", log: .default, type: .error)
            return
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }

}

extension UILabel {
    func underline() {
        if let textString = self.text {
            let attributedString = NSMutableAttributedString(string: textString)
            attributedString.addAttribute(NSAttributedStringKey.underlineStyle,
                                          value: NSUnderlineStyle.styleSingle.rawValue,
                                          range: NSRange(location: 0, length: attributedString.length))
            attributedText = attributedString
        }
    }
}

