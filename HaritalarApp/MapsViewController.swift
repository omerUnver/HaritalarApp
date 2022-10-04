//
//  ViewController.swift
//  HaritalarApp
//
//  Created by M.Ömer Ünver on 28.09.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData
class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var notText: UITextField!
    @IBOutlet weak var isimText: UITextField!
    var locationManager = CLLocationManager()
    var secilenLatitude = Double()
    var secilenLongitude = Double()
    
    var secilenIsim = ""
    var secilenId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //İstenilen Keskinlik yani en doğru konum verisini alıyoruz burada
        locationManager.requestWhenInUseAuthorization() //uygulama konumu kullanmak için izin istemesi (burada uygulamayı kullanırken konum kullanımına izin veriyor)
        locationManager.startUpdatingLocation() //konumu güncelle
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer: )))
        gestureRecognizer.minimumPressDuration = 3 //location seçmek için minimum ekrana basma süresi
        mapView.addGestureRecognizer(gestureRecognizer)
        
        let hideKeyboard = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(hideKeyboard)
        
        if secilenIsim != ""{
            //Core datada'dan verileri çek
            if let uuidString = secilenId?.uuidString{
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let contex = appDelegate.persistentContainer.viewContext
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do{
                    let sonuclar = try contex.fetch(fetchRequest)
                    if sonuclar.count > 0 {
                        for sonuc in sonuclar as! [NSManagedObject]{
                            if let isim = sonuc.value(forKey: "isim") as? String{
                                annotationTitle = isim
                                if let not = sonuc.value(forKey: "not") as? String{
                                    annotationSubtitle = not
                                    if let latitude = sonuc.value(forKey: "latitude") as? Double{
                                        annotationLatitude = latitude
                                        if let longitude = sonuc.value(forKey: "longitude") as? Double{
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubtitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                            mapView.addAnnotation(annotation)
                                            isimText.text = annotationTitle
                                            notText.text = annotationSubtitle
                                    
                                            locationManager.stopUpdatingLocation()
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                            }
                            
                                        }
                           
                                    }
                            
                                }
                            
                            
                        }
                    }
                } catch {
                    print("hata")
                }
            } else {
                //yeni veri ekle
            }
            
        }
    }
        
        @objc func hideKeyboard(){
            view.endEditing(true)
        }
        
        @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer){
            if gestureRecognizer.state == .began{ //tıklama başladığında yapılacaklar
                let secilenNokta = gestureRecognizer.location(in: mapView)
                let secilenKoordinat = mapView.convert(secilenNokta, toCoordinateFrom: mapView)
                
                secilenLatitude = secilenKoordinat.latitude
                secilenLongitude = secilenKoordinat.longitude
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = secilenKoordinat
                annotation.title = isimText.text
                annotation.subtitle = notText.text
                mapView.addAnnotation(annotation)
                
                
            }
        }
        
        //latitude : Enlem
        //longitude : Boylam
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if secilenIsim == "" {
                let newLocation = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
                
                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) //Yükseklik ve alçaklık veriyor
                
                let region = MKCoordinateRegion(center: newLocation, span: span)
                mapView.setRegion(region, animated: true)
            }
            
        }
        
        
        @IBAction func kaydetButton(_ sender: Any) {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let contex = appDelegate.persistentContainer.viewContext
            
            let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: contex)
            yeniYer.setValue(isimText.text, forKey: "isim")
            yeniYer.setValue(notText.text, forKey: "not")
            yeniYer.setValue(secilenLatitude, forKey: "latitude")
            yeniYer.setValue(secilenLongitude, forKey: "longitude")
            yeniYer.setValue(UUID(), forKey: "id")
            
            do{
                try contex.save()
                print("kayıt edildi")
            } catch {
                print("hata")
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("yeniYer"), object: nil)
            navigationController?.popViewController(animated: true)
            
            
        }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let annotationId = "Annotation ID"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationId)
        
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .green
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        }else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if secilenIsim != "" {
            var requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemark, error in
                if let placemarks = placemark {
                    if placemarks.count > 0 {
                        let yeniPlacemark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: yeniPlacemark)
                        
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                                        
                    }
                }
                
                
            }
            
            
            
        }
    }
    
    
    }
