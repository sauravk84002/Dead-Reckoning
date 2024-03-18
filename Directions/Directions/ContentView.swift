//
//  ContentView.swift
//  Directions
//

import MapKit
import SwiftUI
import AVFoundation
import Contacts

struct ContentView: View {
	
	@State private var directions: [String] = []
	@State private var arrows: [String] = []
	@State private var distances: [Double] = []
	@State private var showDirections = false
	@State var count = 0
	@State var dif = 0
	@State var min = 0
	@State var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
	
	@State var dest: String = ""
	@State var pickView: Int = 0
	
	var body: some View {
		if pickView == 0 {
			intro
		} else {
			x
		}
	}
	
	var x: some View {
		
		VStack {
			MapView(directions: $directions, distances: $distances, arrows: $arrows)
			
			HStack(alignment: .center, spacing: 5) {
				Button(action: {
					self.showDirections.toggle()
				}, label: {
					Text("Let's Get Started")
						.foregroundColor(.white)
						.padding(.vertical, 20)
						.padding(.horizontal, 30)
						.background(Color.black)
						.cornerRadius(25)
				})
				.disabled(directions.isEmpty)
				.padding()
			}
			
		}.sheet(isPresented: $showDirections, content: {
			VStack(spacing: 0) {
				Text("Directions")
					.font(.largeTitle)
					.bold()
					.padding()
				
				Divider().background(Color.blue)
				
				VStack {
					VStack {
						Spacer()
						if distances[min] < 10 {
							Image(systemName: arrows[min])
									.resizable()
									.aspectRatio(contentMode: .fit)
									.frame(maxWidth: .infinity, maxHeight: .infinity)
									.padding()
						} else {
							Image(systemName: "arrow.up")
									.resizable()
									.aspectRatio(contentMode: .fit)
									.frame(maxWidth: .infinity, maxHeight: .infinity)
									.padding()
						}
							
						Text(self.directions[min])
									.font(.title)
									.fontWeight(.bold)
									.multilineTextAlignment(.center)
									.padding()
						Text("\(distances[min], specifier: "%.2f") m")
									.font(.title2)
									.padding(.bottom)
					}
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.background(Color.blue)
					.foregroundColor(.white)

					/*
					if i == min {
						HStack {
							Text(self.directions[i]).padding()
							Spacer()
							Text("\(distances[i], specifier: "%.2f") m").padding()
						}
						.foregroundColor(.white)
						.background(Color.black)
					} else if i > min {
						HStack {
							Text(self.directions[i]).padding()
							Spacer()
						}
					}
					 */
					
				}
				.onReceive(timer) { time in
					if distances.count > 0 {
						count += 1
						if distances[min] > 2 {
							distances[min] = distances[min] - 2
						} else {
							distances[min] = 0
						}
						if distances[min] <= 0 {
							let utterance = AVSpeechUtterance(string: directions[min+1])
							utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
							utterance.rate = 0.8
							let synthesizer = AVSpeechSynthesizer()
							synthesizer.speak(utterance)
							if distances.count == 1 {
								self.showDirections = false
								self.pickView = 2
							}
							distances.removeFirst()
							directions.removeFirst()
							print(distances.count)
							print(directions.count)
							count = 0
							min += 1
							
						}
					}
				}
			}
		})
	}
	
	var intro: some View {
			VStack(spacing: 20) {
					Spacer()
				TextField("Destination", text: self.$dest)
						.padding(.all, 20)
						.background(Color.white)
						.cornerRadius(8)
						.shadow(radius: 4)
						.border(Color.black, width: 2)
					Button(action: {
							self.pickView = 1
					}, label: {
							Text("Let's go")
									.foregroundColor(.white)
									.font(.headline)
					})
					.frame(maxWidth: 300, minHeight: 80)
					.background(Color.blue)
					.cornerRadius(8)
					.shadow(radius: 4)
					.padding(.bottom, 20)
				Spacer()
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.padding(.all, 20)
			.background(Color.gray.opacity(0.2))
	}

	
}

struct MapView: UIViewRepresentable {
  typealias UIViewType = MKMapView
  
  @Binding var directions: [String]
	@Binding var distances: [Double]
	@Binding var arrows: [String]
  
  func makeCoordinator() -> MapViewCoordinator {
    return MapViewCoordinator()
  }
  
  func makeUIView(context: Context) -> MKMapView {
    let mapView = MKMapView()
    mapView.delegate = context.coordinator

    let region = MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: 53.463018, longitude: -2.242477),
      span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    mapView.setRegion(region, animated: true)
    
    // start
		let addressDict = [CNPostalAddressStreetKey: "Aquarius Park", CNPostalAddressCityKey: "Manchester", CNPostalAddressCountryKey: "United Kingdom", CNPostalAddressISOCountryCodeKey: "GB", CNPostalAddressPostalCodeKey: "M1 1AB", CNPostalAddressStateKey: "Greater Manchester", CNPostalAddressSubLocalityKey: "City Centre", CNPostalAddressSubAdministrativeAreaKey: "Greater Manchester"]

		let p1 = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 53.463018, longitude: -2.242477), addressDictionary: addressDict)

		let addressDict2 = [CNPostalAddressStreetKey: "Ummal Yatim Foundation", CNPostalAddressCityKey: "Manchester", CNPostalAddressCountryKey: "United Kingdom", CNPostalAddressISOCountryCodeKey: "GB", CNPostalAddressPostalCodeKey: "M1 1AB", CNPostalAddressStateKey: "Greater Manchester", CNPostalAddressSubLocalityKey: "City Centre", CNPostalAddressSubAdministrativeAreaKey: "Greater Manchester"]
    
    // end
    let p2 = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 53.463516, longitude: -2.240544), addressDictionary: addressDict2)
    
    let request = MKDirections.Request()
    request.source = MKMapItem(placemark: p1)
    request.destination = MKMapItem(placemark: p2)
    request.transportType = .walking
    
    let directions = MKDirections(request: request)
    directions.calculate { response, error in
      guard let route = response?.routes.first else { return }
      mapView.addAnnotations([p1, p2])
      mapView.addOverlay(route.polyline)
      mapView.setVisibleMapRect(
        route.polyline.boundingMapRect,
        edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20),
        animated: true)
      self.directions = route.steps.map { $0.instructions }.filter { !$0.isEmpty }
			self.distances = route.steps.map { $0.distance }.filter { $0 > 0 }
			self.arrows = ["arrow.left", "arrow.left", "pin", "pin"]
    }
    return mapView
  }
  
  func updateUIView(_ uiView: MKMapView, context: Context) {
  }
  
  class MapViewCoordinator: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      let renderer = MKPolylineRenderer(overlay: overlay)
      renderer.strokeColor = .systemBlue
      renderer.lineWidth = 5
      return renderer
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
