//
//  whereToGoViewController.swift
//  damoim-project
//
//  Created by hansung on 2023/04/19.
//
import UIKit
import NMapsMap
import CoreLocation
import Foundation

//initddddddd

class whereToGoViewController: UIViewController, NMFLocationManagerDelegate, CLLocationManagerDelegate {
    
    var naverMapView: NMFNaverMapView!
    var locationManager: CLLocationManager! // NMFLocationManager를 사용합니다.
    
    // 경로로 돌아가는 버튼 추가
    let goBackToPathButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("경로로 돌아가기", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //locationManager = NMFLocationManager.sharedInstance()
        //locationManager.add(self) // 자신을 NMFLocationManager의 위치 업데이트 수신자로 추가합니다.
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        naverMapView = NMFNaverMapView(frame: view.frame)
        view.addSubview(naverMapView)
        
        let mapView = naverMapView.mapView
        
        let initialLocation = NMGLatLng(lat: 37.5825638, lng: 127.0101949)
        let initialZoomLevel: Double = 16
        let cameraPosition = NMFCameraPosition(initialLocation, zoom: initialZoomLevel)
        mapView.moveCamera(NMFCameraUpdate(position: cameraPosition))
        
        // 경로 좌표 예시
        //let pathCoordinates = [
        //    NMGLatLng(lat: 37.5666102, lng: 126.9783881), // 서울시청
        //    NMGLatLng(lat: 37.565721, lng: 126.976897), // 경로1
        //    NMGLatLng(lat: 37.564711, lng: 126.977013) // 경로2
        //]
        
        //drawPathOnMap(pathCoordinates: pathCoordinates)
        
        // 현재 위치 버튼 추가
        let locationButton = NMFLocationButton()
        locationButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(locationButton)

        // 위치 버튼 제약 조건 설정
        NSLayoutConstraint.activate([
            locationButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            locationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        // 현재 위치 버튼의 mapView 속성을 설정하세요.
        locationButton.mapView = naverMapView.mapView
        
        // 위치 추적 모드를 지정합니다.
        naverMapView.mapView.positionMode = .direction
        
        // 위치 기능 활성화
        naverMapView.positionMode = .direction
        
        // 경로로 돌아가는 버튼을 추가하고 제약 조건 설정
        view.addSubview(goBackToPathButton)
        NSLayoutConstraint.activate([
        goBackToPathButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            goBackToPathButton.bottomAnchor.constraint(equalTo: locationButton.topAnchor, constant: -16)
        ])
                
        // 경로로 돌아가는 버튼에 touchUpInside 이벤트 추가
        goBackToPathButton.addTarget(self, action: #selector(moveToInitialPath), for: .touchUpInside)
        
        //서버의 최적 경로 좌표를 사용하여 경로를 지도에 표시
        fetchOptimalRouteCoordinates { optimalRouteCoordinates, error in
            guard let optimalRouteCoordinates = optimalRouteCoordinates, error == nil else {
                print("Error fetching optimal route coordinates:", error?.localizedDescription ?? "unknown error")
                return
            }
            
            DispatchQueue.main.async {
                for i in 0..<(optimalRouteCoordinates.count - 1) {
                    let start = optimalRouteCoordinates[i]
                    let end = optimalRouteCoordinates[i + 1]
                    
                    self.requestDirection(start: start, end: end) { polylineOverlay, error in
                        DispatchQueue.main.async {
                            if let polylineOverlay = polylineOverlay {
                                polylineOverlay.mapView = mapView
                            } else {
                                print("Error requesting direction:", error?.localizedDescription ?? "unknown error")
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    func moveMapTo(coordinate: NMGLatLng) {
        let cameraUpdate = NMFCameraUpdate(scrollTo: coordinate)
        cameraUpdate.animation = .easeIn
        cameraUpdate.animationDuration = 1.5
        naverMapView.mapView.moveCamera(cameraUpdate)
    }
    
    func drawPathOnMap(pathCoordinates: [NMGLatLng]) {
        let path = NMFPath(points: pathCoordinates)
        path?.color = .systemBlue
        path?.width = 10
        path?.outlineWidth = 2
        path?.outlineColor = .white
        path?.mapView = naverMapView.mapView
    }
    
    @objc func moveToInitialPath() {
        let initialLocation = NMGLatLng(lat: 37.5825638, lng: 127.0101949)
        moveMapTo(coordinate: initialLocation)
    }
   
    //서버에서 최적 경로 좌표 요청하는 함수
    func fetchOptimalRouteCoordinates(completion: @escaping ([CLLocationCoordinate2D]?, Error?) -> Void) {
        guard let url = URL(string: "http://52.79.138.34:1105/optimal_route") else {
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode([[String: Double]].self, from: data)
                let coordinates = decodedData.map { CLLocationCoordinate2D(latitude: $0["latitude"]!, longitude: $0["longitude"]!) }
                completion(coordinates, nil)
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    func requestDirection(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, completion: @escaping (NMFPath?, Error?) -> Void) {
        let directionAPI = "https://naveropenapi.apigw.ntruss.com/map-direction/v1/driving"
        let clientId = "hag6m0rapi"
        let clientSecret = "gAdjj4m7csASJFgaTg9aLetetBf4DNWZZpcBWBpY"
        
        guard let url = URL(string: "\(directionAPI)?start=\(start.longitude),\(start.latitude)&goal=\(end.longitude),\(end.latitude)") else {
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(clientId, forHTTPHeaderField: "X-NCP-APIGW-API-KEY-ID")
        request.addValue(clientSecret, forHTTPHeaderField: "X-NCP-APIGW-API-KEY")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            
            print(String(data: data, encoding: .utf8) ?? "Unable to convert data to String")

            do {
                let decodedData = try JSONDecoder().decode(DirectionResponse.self, from: data)
                let path = NMFPath(points: decodedData.coordinates.map { NMGLatLng(lat: $0.latitude, lng: $0.longitude) })
                path?.color = .systemBlue
                path?.width = 10
                path?.outlineWidth = 2
                path?.outlineColor = .white
                completion(path, nil)
            } catch {
                completion(nil, error)
            }
            
            
        }
        
        
        task.resume()
    }

    struct DirectionResponse: Codable {
        let coordinates: [CLLocationCoordinate2D]
        
        enum CodingKeys: String, CodingKey {
            case route
        }
        
        enum RouteKeys: String, CodingKey {
            case traoptimal
        }
        
        enum TraoptimalKeys: String, CodingKey {
            case path
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let routeContainer = try container.nestedContainer(keyedBy: RouteKeys.self, forKey: .route)
            var traoptimalArrayContainer = try routeContainer.nestedUnkeyedContainer(forKey: .traoptimal)
            let traoptimalContainer = try traoptimalArrayContainer.nestedContainer(keyedBy: TraoptimalKeys.self)
            let path = try traoptimalContainer.decode([[Double]].self, forKey: .path)

            coordinates = path.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
        }

        
        func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                var routeContainer = container.nestedContainer(keyedBy: RouteKeys.self, forKey: .route)
                var traoptimalContainer = routeContainer.nestedContainer(keyedBy: TraoptimalKeys.self, forKey: .traoptimal)
                
                let path = coordinates.map { [$0.longitude, $0.latitude] }
                try traoptimalContainer.encode(path, forKey: .path)
            }
    }



                                 
                                 
}

extension whereToGoViewController {
    @nonobjc func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let currentLatLng = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            
        // 현재 위치로 지도를 이동합니다.
        moveMapTo(coordinate: currentLatLng)
        
        // 필요한 경우 다른 작업을 수행합니다. 예를 들어, 현재 위치에 마커를 추가하거나,
        // 현재 위치와 관련된 정보를 사용자 인터페이스에 표시합니다.
    }
}
