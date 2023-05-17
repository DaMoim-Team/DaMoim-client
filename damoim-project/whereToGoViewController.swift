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
import Firebase
import FirebaseAuth
import FirebaseFirestore

class whereToGoViewController: UIViewController, NMFLocationManagerDelegate, CLLocationManagerDelegate, NMFMapViewDelegate, NMFMapViewTouchDelegate {

    var naverMapView: NMFNaverMapView!
    var locationManager: CLLocationManager! // NMFLocationManager를 사용합니다.
    var minCount: Int = 0
    
    var locations: [Location] = []
    var optimalroute: [CLLocationCoordinate2D] = []
    
    //출발지
    var startLocation: Location?
    
    // 햄버거 버튼을 프로퍼티로 추가
    private lazy var hamburgerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "hamburgerIcon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(hamburgerButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    //경로를 표시하는 버튼
    private lazy var routeButton: UIButton = {
        let button = UIButton(type: .system)
        //button.setTitle("경로 표시", for: .normal)
        button.setImage(UIImage(named: "shortestroute")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(routeButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    //x버튼
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "xIcon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    //검출 수 기준 경로 버튼
    private lazy var routeCountButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "countroute")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(routeCountButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()


    
    //사이드메뉴
    private lazy var sideMenuView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let blackOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()
    
    //새로고침
    private let refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "refreshIcon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //UserDefaults의 minCount값 불러오기
        minCount = UserDefaults.standard.integer(forKey: "minCount") == 0 ? 3 : UserDefaults.standard.integer(forKey: "minCount")
        
        // 네이버 지도 설정
        naverMapView = NMFNaverMapView(frame: view.frame)
        view.addSubview(naverMapView)

        // 햄버거 버튼을 뷰에 추가
        view.addSubview(hamburgerButton)

        // 오토레이아웃을 사용하여 버튼을 위치시키세요.
        NSLayoutConstraint.activate([
            hamburgerButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            hamburgerButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16)
        ])

        // 햄버거 버튼을 상위 계층으로 이동
        view.bringSubviewToFront(hamburgerButton)
        
        // 사이드 메뉴 뷰를 뷰 계층에 추가
        view.addSubview(sideMenuView)
        sideMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        sideMenuView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        sideMenuView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        sideMenuView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75).isActive = true

        // 사이드 메뉴를 초기에 숨김
        sideMenuView.transform = CGAffineTransform(translationX: -view.bounds.width * 0.75, y: 0)
        
        // 계정 정보를 포함할 서브뷰 생성
        let accountInfoView = UIView()
        accountInfoView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.1)

        accountInfoView.translatesAutoresizingMaskIntoConstraints = false
        sideMenuView.addSubview(accountInfoView)

        accountInfoView.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor).isActive = true
        accountInfoView.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor).isActive = true
        accountInfoView.topAnchor.constraint(equalTo: sideMenuView.topAnchor).isActive = true
        // 적당한 높이로 설정. 필요에 따라 조정 가능
        accountInfoView.heightAnchor.constraint(equalToConstant: 150).isActive = true



        // 계정 정보 레이블 생성 및 sideMenuView에 추가
        let nameText = UILabel()
        nameText.textAlignment = .left
        nameText.text = "Loading..."
        nameText.textColor = .black
        nameText.font = UIFont.boldSystemFont(ofSize: 25)
        nameText.translatesAutoresizingMaskIntoConstraints = false
        accountInfoView.addSubview(nameText)

        nameText.leadingAnchor.constraint(equalTo: accountInfoView.leadingAnchor, constant: 16).isActive = true
        nameText.topAnchor.constraint(equalTo: accountInfoView.topAnchor, constant: 100).isActive = true
        
        if let user = Auth.auth().currentUser {
            let userEmail = user.email ?? "No Email"
            
            Firestore.firestore().collection("users").document(userEmail).getDocument{ (document, error) in
                if let error = error{
                    print("Error getting user data \(error)")
                } else{
                    if let document = document, document.exists{
                        let userName = document.get("name") as? String ?? "No Name"
                        let jobNum = document.get("job") as? Int
                        nameText.text = "미화원 " + userName + " 님"
                    }
                }
            }
        } else {
            nameText.text = "No User"
        }


        // 메뉴 아이템 버튼 생성 및 sideMenuView에 추가
        let menuItem1 = createMenuButton(menuItem: .howTo)
        let menuItem2 = createMenuButton(menuItem: .count)
        let menuItem3 = createMenuButton(menuItem: .cleaning)
        let menuItem4 = createMenuButton(menuItem: .logout)

        sideMenuView.addSubview(menuItem1)
        sideMenuView.addSubview(menuItem2)
        sideMenuView.addSubview(menuItem3)
        sideMenuView.addSubview(menuItem4)

        // 메뉴 아이템 버튼 레이아웃 설정
        menuItem1.centerXAnchor.constraint(equalTo: sideMenuView.centerXAnchor).isActive = true
        menuItem1.topAnchor.constraint(equalTo: accountInfoView.bottomAnchor, constant: 20).isActive = true

        menuItem2.centerXAnchor.constraint(equalTo: sideMenuView.centerXAnchor).isActive = true
        menuItem2.topAnchor.constraint(equalTo: menuItem1.bottomAnchor, constant: 20).isActive = true

        menuItem3.centerXAnchor.constraint(equalTo: sideMenuView.centerXAnchor).isActive = true
        menuItem3.topAnchor.constraint(equalTo: menuItem2.bottomAnchor, constant: 20).isActive = true

        menuItem4.centerXAnchor.constraint(equalTo: sideMenuView.centerXAnchor).isActive = true
        menuItem4.topAnchor.constraint(equalTo: menuItem3.bottomAnchor, constant: 20).isActive = true

        
        // 블랙 오버레이 뷰에 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(blackOverlayViewTapped))
        blackOverlayView.addGestureRecognizer(tapGesture)

        naverMapView.mapView.touchDelegate = self

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let mapView = naverMapView.mapView
        
        let initialLocation = NMGLatLng(lat: 37.547174, lng: 127.041846)
        let initialZoomLevel: Double = 16
        let cameraPosition = NMFCameraPosition(initialLocation, zoom: initialZoomLevel)
        mapView.moveCamera(NMFCameraUpdate(position: cameraPosition))
        
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
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
        locationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
        
        // 버튼 추가
        view.addSubview(routeButton)
        
        // 버튼 제약 조건 설정
        NSLayoutConstraint.activate([
            routeButton.bottomAnchor.constraint(equalTo: locationButton.topAnchor, constant: -16),
            routeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -13)
        ])
        
        // Close 버튼 추가
        view.addSubview(closeButton)
        
        // Close 버튼 제약 조건 설정
        NSLayoutConstraint.activate([
            //closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
        
        // 새로고침 버튼 추가 및 설정
        view.addSubview(refreshButton)
        NSLayoutConstraint.activate([
            refreshButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            refreshButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        refreshButton.addTarget(self, action: #selector(refreshButtonTapped), for: .touchUpInside)
        
        
        // 검출 수 경로 버튼 추가
        view.addSubview(routeCountButton)
        
        // 버튼 제약 조건 설정
        NSLayoutConstraint.activate([
            routeCountButton.bottomAnchor.constraint(equalTo: routeButton.topAnchor, constant: -16),
            routeCountButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -13)
        ])
        
        //사이드메뉴 상위계층 이동
        view.bringSubviewToFront(sideMenuView)
        //화면 새로 고침
        self.refreshButtonTapped()
    }
    
    //기본 마커
    private func createMarkers(coordinates: [CLLocationCoordinate2D]) {
        
        var count = 0 // 경로 순서를 나타내는 변수

        coordinates.forEach { coordinate in
            let marker = NMFMarker(position: NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude))

            // 첫 번째 마커인 경우 "START" 문자열을 사용하고, 그렇지 않은 경우 count를 사용합니다.
            if count == 0 {
                marker.captionText = "출발"
                marker.captionTextSize = 18  // 캡션 텍스트의 크기를 설정합니다.
                marker.captionColor = UIColor.red  // 캡션 텍스트의 색상을 설정합니다.
                marker.captionHaloColor = UIColor.white  // 캡션 텍스트의 테두리 색상을 설정합니다.
                marker.iconTintColor = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.0)

            } else {
                marker.iconImage = createMarkerIconWithNumber(count)
            }

            marker.mapView = naverMapView.mapView
            markers.append(marker)

            count += 1 // 경로 순서를 증가
            closeButton.isHidden = false
        }
    }
        
    // 마커에 경로 순위를 표시
    // 출발지 수정
    func createMarkerIconWithNumber(_ number: Int) -> NMFOverlayImage {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        label.backgroundColor = .green
        label.textAlignment = .center
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.text = "\(number)"
        label.layer.cornerRadius = label.bounds.width / 2
        label.layer.masksToBounds = true

        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        return NMFOverlayImage(image: image)
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
       
    //서버에서 JSON 데이터 가져오는 함수
    func fetchData(minimumCount: Int, completion: @escaping ([CLLocationCoordinate2D]?, [Location]?, Error?) -> Void) {
        guard let url = URL(string: "http://52.79.138.34:1105/data") else {
            completion(nil, nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, nil, error)
                return
            }
            
            // JSON 데이터를 문자열로 변환하고 출력합니다.
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
            
            do {
                let decodedData = try JSONDecoder().decode(ResponseData.self, from: data)
                
                //출발지
                guard let startLocation = self.fetchStartLocation(from: decodedData) else {
                    completion(nil, nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find start location"]))
                    return
                }
                
                // optimalrouteWithoutStart 배열 생성
                self.optimalrouteWithoutStart = self.fetchOptimalRouteCoordinates(from: decodedData, minimumCount: minimumCount)
                // 출발지 제거
                if let startLocationIndex = self.optimalrouteWithoutStart.firstIndex(where: { $0.latitude == startLocation.latitude && $0.longitude == startLocation.longitude }) {
                    self.optimalrouteWithoutStart.remove(at: startLocationIndex)
                }
                
                let locations = self.fetchLocations(from: decodedData, startLocation: startLocation)
                let optimalroute = self.fetchOptimalRouteCoordinates(from: decodedData, minimumCount: 0)
                completion(optimalroute, locations, nil)
                
                
                
            } catch {
                completion(nil, nil, error)
            }
        }
        
        task.resume()
    }

    //출발지 위치 fetch
    func fetchStartLocation(from responseData: ResponseData) -> Location? {
        let startLocation = responseData.optimalRoute.first { $0.cctv_id == "start" }
        return startLocation
    }


    func fetchLocations(from responseData: ResponseData, startLocation: Location) -> [Location] {
        var filteredLocations = responseData.optimalRoute.filter { $0.count_cleanup > 0 && $0.cctv_id != "start" }
        
        //출발지 위치를 'filteredLocations'에 넣음
        filteredLocations.insert(startLocation, at: 0)
        
        return filteredLocations
    }


    func fetchOptimalRouteCoordinates(from responseData: ResponseData, minimumCount: Int) -> [CLLocationCoordinate2D] {
        let filteredCoordinatesAndCounts = responseData.optimalRoute.filter { $0.count_cleanup >= minCount }
        let filteredCoordinates = filteredCoordinatesAndCounts.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        return filteredCoordinates
    }
  
    //네이버지도 방향api를 사용해 경로를 가져오는 함수
    func requestDirection(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, completion: @escaping (NMFPolylineOverlay?, Error?) -> Void) {
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
                let coordinates = decodedData.coordinates.map { NMGLatLng(lat: $0.latitude, lng: $0.longitude) }
                let polylineOverlay = NMFPolylineOverlay(coordinates)
                polylineOverlay?.color = .systemBlue
                polylineOverlay?.width = 10
                completion(polylineOverlay, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
    
    private var circleOverlays: [NMFCircleOverlay] = []
    
    private var circleLabels: [NMFMarker] = []
    
    private func labelToImage(_ label: UILabel) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        if let context = UIGraphicsGetCurrentContext() {
            label.layer.render(in: context)
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        return nil
    }
    
    func createHeatmap(with locations: [Location]) {
        circleOverlays.forEach { overlay in
            overlay.mapView = nil
        }
        circleOverlays.removeAll()
        
        for location in locations {
            let circleOverlay = NMFCircleOverlay(NMGLatLng(lat: location.latitude, lng: location.longitude), radius: calculateRadius(from: location.count_cleanup))
            circleOverlay.fillColor = calculateColor(from: location.count_cleanup)
            circleOverlay.mapView = naverMapView.mapView
            circleOverlays.append(circleOverlay) // 이 줄을 추가하세요.
            
            // 레이블 생성
            let label = UILabel()
            label.text = "\(location.count_cleanup)"
            label.textAlignment = .center
            label.textColor = .black
            label.font = UIFont.systemFont(ofSize: 25)
            label.frame = CGRect(x: 0, y: 0, width: circleOverlay.radius * 2, height: circleOverlay.radius)
            label.layer.cornerRadius = circleOverlay.radius
            label.layer.masksToBounds = true
            label.isUserInteractionEnabled = false

            // 지도 위에 레이블 추가
            if let labelTextImage = labelToImage(label) {
                let labelMarker = NMFMarker(position: NMGLatLng(lat: location.latitude, lng: location.longitude))
                labelMarker.iconImage = NMFOverlayImage(image: labelTextImage)
                labelMarker.iconTintColor = .clear
                labelMarker.mapView = naverMapView.mapView
                circleLabels.append(labelMarker)
            }
        }
    }

    
    // minCount = 3 으로 되어있음
    func calculateRadius(from count_cleanup: Int) -> Double {
           let smallRadius = 30.0
           let mediumRadius = 70.0
           let largeRadius = 100.0

           if count_cleanup <= 5 {
               return smallRadius
           } else if count_cleanup > 5 && count_cleanup <= 10 {
               return mediumRadius
           } else {
               return largeRadius
           }
    }

    
    // 앱 시작후 히트맵 색깔 수정, 검출 수 조정과 관계없이 히트맵이 검출 수에 의해 색으로 구분되어 표시됌
    func calculateColor(from count_cleanup: Int) -> UIColor {
        let color1 = UIColor.green
        let color2 = UIColor.systemYellow
        let color3 = UIColor.red

        if count_cleanup <= 5 {                 // 검출 수가 5이하일 때, 히트맵 파란색
                return color1.withAlphaComponent(0.5)
            } else if count_cleanup > 6 && count_cleanup <= 10 {        // 검출 수 6이상 10이하이면 히트맵 주황색
                return color2.withAlphaComponent(0.5)
            } else {                                        // 그 이상 검출되면, 빨간색으로 표시
                return color3.withAlphaComponent(0.5)
            }
            circleOverlays.removeAll()

            // UserDefaults에서 minCount 값 가져오기
            let minCount = UserDefaults.standard.integer(forKey: "minCount") == 0 ? 3 : UserDefaults.standard.integer(forKey: "minCount")

            for location in locations {
                if location.count_cleanup >= minCount { // count_catch 값이 minCount 이상인 경우에만 히트맵 생성
                    let circleOverlay = NMFCircleOverlay(NMGLatLng(lat: location.latitude, lng: location.longitude), radius: calculateRadius(from: location.count_cleanup))
                    circleOverlay.fillColor = calculateColor(from: location.count_cleanup)
                    circleOverlay.mapView = naverMapView.mapView
                    circleOverlays.append(circleOverlay)

                    // 레이블 생성
                    let label = UILabel()
                    label.text = "\(location.count_cleanup)"
                    label.textAlignment = .center
                    label.textColor = .black
                    label.font = UIFont.systemFont(ofSize: 25)
                    label.frame = CGRect(x: 0, y: 0, width: circleOverlay.radius * 2, height: circleOverlay.radius)
                    label.layer.cornerRadius = circleOverlay.radius
                    label.layer.masksToBounds = true
                    label.isUserInteractionEnabled = false

                    // 지도 위에 레이블 추가
                    if let labelTextImage = labelToImage(label) {
                        let labelMarker = NMFMarker(position: NMGLatLng(lat: location.latitude, lng: location.longitude))
                        labelMarker.iconImage = NMFOverlayImage(image: labelTextImage)
                        labelMarker.iconTintColor = .clear
                        labelMarker.mapView = naverMapView.mapView
                        circleLabels.append(labelMarker)
                    }
                }
            }
        }

        
        // minCount = 3 으로 되어있음
        func calculateRadius(from count_cleanup: Int) -> Double {
               let smallRadius = 30.0
               let mediumRadius = 70.0
               let largeRadius = 100.0

               if count_cleanup <= 5 {
                   return smallRadius
               } else if count_cleanup > 5 && count_cleanup <= 10 {
                   return mediumRadius
               } else {
                   return largeRadius
               }
        }

        
        // 앱 시작후 히트맵 색깔 수정, 검출 수 조정과 관계없이 히트맵이 검출 수에 의해 색으로 구분되어 표시됌
        func calculateColor(from count_cleanup: Int) -> UIColor {
            let color1 = UIColor.green
            let color2 = UIColor.systemYellow
            let color3 = UIColor.red

            if count_cleanup <= 5 {                 // 검출 수가 5이하일 때, 히트맵 파란색
                    return color1.withAlphaComponent(0.5)
                } else if count_cleanup > 5 && count_cleanup <= 10 {        // 검출 수 6이상 10이하이면 히트맵 주황색
                    return color2.withAlphaComponent(0.5)
                } else {                                        // 그 이상 검출되면, 빨간색으로 표시
                    return color3.withAlphaComponent(0.5)
                }

        }
    

    //구조체 정의
    //서버에서 보내주는 전체 데이터를 매핑
    struct ResponseData: Codable {
        let optimalRoute: [Location]
        
        enum CodingKeys: String, CodingKey {
            case optimalRoute = "optimal_route"
        }
    }
    
    //optimal_route 배열의 요소를 매핑
    struct Location: Codable {
        let count_catch: Int
        let count_cleanup: Int
        let latitude: Double
        let longitude: Double
        let cctv_id: String
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
    
    @objc func locationButtonTapped() {
        naverMapView.mapView.positionMode = .direction
    }
    
    @objc private func hamburgerButtonTapped() {
        let isMenuHidden = sideMenuView.transform.tx < 0
        let translationX: CGFloat = isMenuHidden ? view.bounds.width * 0.75 : -view.bounds.width * 0.75
        UIView.animate(withDuration: 0.3) {
            self.sideMenuView.transform = self.sideMenuView.transform.translatedBy(x: translationX, y: 0)
        }
    }
    
    enum MenuItem: String {
        case howTo = "도움말"
        case count = "경로추천설정"
        case cleaning = "흡연자검출초기화"
        case logout = "로그아웃"

        var viewController: UIViewController? {
            switch self {
            case .howTo:
                return howtoViewController()
            // 다른 뷰 컨트롤러를 나중에 추가할 수 있습니다.
            case .count:
                return countViewController()
            case .cleaning:
                return cleanViewController()
            case .logout:
                return nil
            }
        }
    }


    private func createMenuButton(menuItem: MenuItem) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(menuItem.rawValue, for: .normal)
        button.tag = menuItem.hashValue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(menuItemTapped), for: .touchUpInside)
        return button
    }
    

    @objc private func menuItemTapped(sender: UIButton) {
        if let title = sender.title(for: .normal) {
            print("\(title) 메뉴 아이템이 선택되었습니다.")

            switch title {
            case "도움말":
                guard let howtoViewController = self.storyboard?.instantiateViewController(withIdentifier: "howtoViewControllerID") as? howtoViewController else { return }
                // 도움말 텍스트 설정
                howtoViewController.helpText = "여기에 미화원!! 에 대한 도움말을 입력하세요..."   // 원하는 텍스트 입력
                self.navigationController?.pushViewController(howtoViewController, animated: true)
                
            case "경로추천설정":
                guard let countViewController = self.storyboard?.instantiateViewController(withIdentifier: "countViewControllerID") as? countViewController else { return }
                
                self.navigationController?.pushViewController(countViewController, animated: true)
                
            case "흡연자검출초기화":
                guard let cleanViewController = self.storyboard?.instantiateViewController(withIdentifier: "cleanViewControllerID") as? cleanViewController else { return }
                
                self.navigationController?.pushViewController(cleanViewController, animated: true)
                
            case "로그아웃":
                do{
                    try Auth.auth().signOut()
                } catch let signOutError as NSError {
                    print("Error signing out: %@", signOutError)
                }
                navigateToLoginViewController()
                self.dismiss(animated: true, completion: nil)

            default:
                print("해당 메뉴에 대한 뷰 컨트롤러가 아직 구현되지 않았습니다.")
            }
        }

        hideSideMenu()
    }


    @objc private func blackOverlayViewTapped() {
        // 블랙 오버레이 뷰를 터치하면 사이드 메뉴를 숨깁니다.
        hideSideMenu()
        
    }

    private func hideSideMenu() {
        UIView.animate(withDuration: 0.3, animations: {
            let translationX: CGFloat = -self.view.bounds.width * 0.75
            self.sideMenuView.transform = CGAffineTransform(translationX: translationX, y: 0)
            self.blackOverlayView.alpha = 0
        }) { _ in
            self.blackOverlayView.removeFromSuperview()
        }
    }


    func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
        hideSideMenu()
    }
    
    func navigateToLoginViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil) // "Main"은 스토리보드의 이름입니다.
        if let navigationController = storyboard.instantiateViewController(withIdentifier: "firstNavControllerID") as? UINavigationController,
           let loginViewController = navigationController.viewControllers.first as? loginViewController {
            // 애니메이션과 함께 뷰 컨트롤러 전환 (옵션)
            let transition = CATransition()
            transition.duration = 0.5
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromLeft
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            view.window!.layer.add(transition, forKey: kCATransition)

            // 로그인 뷰 컨트롤러를 새로운 루트 뷰 컨트롤러로 설정합니다.
            view.window?.rootViewController = navigationController
            view.window?.makeKeyAndVisible()
        }
    }
    
    private var polylineOverlays: [NMFPolylineOverlay] = []
    private var markers: [NMFMarker] = []
    private var totalRouteSegments = 0
    private var completedRouteSegments = 0
    var fetchedLocations: [Location] = []
    var optimalrouteWithoutStart: [CLLocationCoordinate2D] = []
    
    @objc private func routeButtonTapped() {
        
        //히트맵 숨기기
        circleOverlays.forEach { overlay in
            overlay.mapView = nil
        }
        
        // 레이블 숨기기
        circleLabels.forEach { label in
            label.mapView = nil
        }


        // 미리 가져온 경로 좌표를 사용하여 경로를 지도에 표시
        DispatchQueue.main.async {
            self.totalRouteSegments = self.optimalroute.count
            self.completedRouteSegments = 0
            if let startLocation = self.startLocation {
                var start = CLLocationCoordinate2D(latitude: startLocation.latitude, longitude: startLocation.longitude)
                let optimalrouteWithoutStart = self.optimalroute.filter { !($0.latitude == start.latitude && $0.longitude == start.longitude) }
                for i in 0..<(optimalrouteWithoutStart.count) {
                    let end = CLLocationCoordinate2D(latitude: optimalrouteWithoutStart[i].latitude, longitude: optimalrouteWithoutStart[i].longitude)
                        self.requestDirection(start: start, end: end) { polylineOverlay, error in
                            DispatchQueue.main.async {
                                if let polylineOverlay = polylineOverlay {
                                    polylineOverlay.mapView = self.naverMapView.mapView
                                    self.polylineOverlays.append(polylineOverlay)
                                } else {
                                    print("Error requesting direction:", error?.localizedDescription ?? "unknown error")
                                }
                                
                                self.completedRouteSegments += 1
                                
                                if self.completedRouteSegments == self.totalRouteSegments {

                                    print("Finished drawing route")
                                }
                            }
                        }
                    start = end
                    }
            }
            
            // 경로 표시 버튼 비활성화 및 닫기 버튼 활성화
            self.routeButton.isHidden = true
            self.routeCountButton.isHidden = true
            self.closeButton.isHidden = false
            
            // 정렬된 locations의 좌표를 사용하여 마커 생성
            if let startLocation = self.startLocation {
                let sortedCoordinates = [CLLocationCoordinate2D(latitude: startLocation.latitude, longitude: startLocation.longitude)]
                + self.optimalrouteWithoutStart.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                self.createMarkers(coordinates: sortedCoordinates)
            } else {
                print("start location not set")
                let sortedCoordinates = self.optimalrouteWithoutStart.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                self.createMarkers(coordinates: sortedCoordinates)
            }
        }
    }
    
    //count 기준으로 경로 안내
    @objc private func routeCountButtonTapped() {
        print("routeCountButtonTapped called")
        
        //히트맵 숨기기
        circleOverlays.forEach { overlay in
            overlay.mapView = nil
        }
        // 레이블 숨기기
        circleLabels.forEach { label in
            label.mapView = nil
        }

        //fetchedLocations: 출발 위치 제외
        DispatchQueue.main.async {
            self.totalRouteSegments = self.fetchedLocations.count
            self.completedRouteSegments = 0
            if let startLocation = self.startLocation {
                var start = CLLocationCoordinate2D(latitude: startLocation.latitude, longitude: startLocation.longitude)
                for i in 0..<(self.fetchedLocations.count) {
                    let end = CLLocationCoordinate2D(latitude: self.fetchedLocations[i].latitude, longitude: self.fetchedLocations[i].longitude)
                    self.requestDirection(start: start, end: end) { polylineOverlay, error in
                        DispatchQueue.main.async {
                            if let polylineOverlay = polylineOverlay {
                                polylineOverlay.mapView = self.naverMapView.mapView
                                self.polylineOverlays.append(polylineOverlay)
                            } else {
                                print("Error requesting direction:", error?.localizedDescription ?? "unknown error")
                            }
                                
                            self.completedRouteSegments += 1
                                
                            if self.completedRouteSegments == self.totalRouteSegments {
               
                                print("Finished drawing route")
                            }
                        }
                    }
                    start = end
                }
            }else {
                print("Not enough locations to draw")
            }
            // 경로 표시 버튼 비활성화 및 닫기 버튼 활성화
            self.routeButton.isHidden = true
            self.routeCountButton.isHidden = true
            self.closeButton.isHidden = false
            
            // 정렬된 locations의 좌표를 사용하여 마커 생성
            if let startLocation = self.startLocation {
                let sortedCoordinates = [CLLocationCoordinate2D(latitude: startLocation.latitude, longitude: startLocation.longitude)]
                       + self.fetchedLocations.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                self.createMarkers(coordinates: sortedCoordinates)
            } else {
                print("start location not set")
                let sortedCoordinates = self.fetchedLocations.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                self.createMarkers(coordinates: sortedCoordinates)
            }
        }
    }

    
    @objc private func closeButtonTapped() {
        // 경로 지우기
        polylineOverlays.forEach { overlay in
            overlay.mapView = nil
        }
        polylineOverlays.removeAll()

        // 마커 지우기
        markers.forEach { marker in
            marker.mapView = nil
        }
        markers.removeAll()
        
        // 히트맵 다시 표시
        circleOverlays.forEach { overlay in
            overlay.mapView = naverMapView.mapView
        }
        
        // 레이블 다시 표시
        circleLabels.forEach { label in
            label.mapView = naverMapView.mapView
        }

        

        // 경로 표시 버튼 활성화 및 닫기 버튼 비활성화
        routeButton.isHidden = false
        routeCountButton.isHidden = false
        closeButton.isHidden = true
    }
    
    @objc private func refreshButtonTapped() {
        
        fetchedLocations.removeAll()
        
        // 기존 히트맵 지우기
        circleOverlays.forEach { overlay in
            overlay.mapView = nil
        }
        circleOverlays.removeAll()
        
        // 레이블 숨기기
        circleLabels.forEach { label in
            label.mapView = nil
        }
        circleLabels.removeAll()

        // 기존 경로 지우기
        polylineOverlays.forEach { overlay in
            overlay.mapView = nil
        }
        polylineOverlays.removeAll()

        // 기존 마커 지우기
        markers.forEach { marker in
            marker.mapView = nil
        }
        markers.removeAll()

        
        fetchData(minimumCount: minCount) { optimalroute, locations, error in
            guard let optimalroute = optimalroute, let locations = locations, error == nil else {
                print("Error fetching data:", error?.localizedDescription ?? "unknown error")
                return
            }

            DispatchQueue.main.async {
                // 새로 가져온 optimalroute를 전역 변수에 할당합니다.
                self.optimalroute = optimalroute
                // 새로 가져온 locations를 전역 변수에 할당합니다.
                self.fetchedLocations = locations
                
                //'start' 위치를 찾아서 전역 변수에 저장
                if let startLocation = locations.first(where: { $0.cctv_id == "start" }) {
                    self.startLocation = startLocation
            
                    // 'start' 위치의 위도와 경도를 출력합니다.
                    print("Start location latitude: \(startLocation.latitude), longitude: \(startLocation.longitude)")
                }else {
                    print("Start location not found in locations")
                }
                //출발지 제외하고 내림차순 정렬
                self.fetchedLocations = self.fetchedLocations
                    .filter { $0.cctv_id != "start" && $0.count_cleanup >= self.minCount}
                    .sorted(by: {$0.count_cleanup > $1.count_cleanup })
                
                // 경로 설정 버튼이 활성화되어 있다면, 닫기 버튼이 비활성화되어 있는 상태입니다.
                // 이 경우, 닫기 버튼을 누른 것처럼 작동하게 합니다.
                if self.routeButton.isHidden == true {
                    self.closeButtonTapped()
                }
                if self.routeButton.isHidden == false {
                    //경로설정버튼이 나와있다면 나와있는 히트맵을 지우고 히트맵을 다시 표시할것.
                    
                    // 새 히트맵을 생성하고 표시합니다.
                    self.createHeatmap(with: self.fetchedLocations)
                }
                if self.routeCountButton.isHidden == true {
                    self.closeButtonTapped()
                }
                if self.routeCountButton.isHidden == false {
                    //경로설정버튼이 나와있다면 나와있는 히트맵을 지우고 히트맵을 다시 표시할것.
                    
                    // 새 히트맵을 생성하고 표시합니다.
                    self.createHeatmap(with: self.fetchedLocations)
                }
                
            }
        }
    }

    func presentCountViewController() {
        let countVC = countViewController()
        countVC.minCount = minCount
        countVC.delegate = self
        navigationController?.pushViewController(countVC, animated: true)
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

extension whereToGoViewController: CountViewControllerDelegate {
    func updateMinimumCount(_ count: Int) {
        self.minCount = count
    }
}

protocol CountViewControllerDelegate: AnyObject {
    func updateMinimumCount(_ count_cleanup: Int)
}
