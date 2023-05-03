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

class whereToGoViewController: UIViewController, NMFLocationManagerDelegate, CLLocationManagerDelegate, NMFMapViewDelegate, NMFMapViewTouchDelegate {

    var naverMapView: NMFNaverMapView!
    var locationManager: CLLocationManager! // NMFLocationManager를 사용합니다.
    
    // 경로로 돌아가는 버튼 추가
    let goBackToPathButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("경로로 돌아가기", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // 햄버거 버튼을 프로퍼티로 추가
    private lazy var hamburgerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "list.dash"), for: .normal)
        button.addTarget(self, action: #selector(hamburgerButtonTapped), for: .touchUpInside)
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
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 네이버 지도 설정
        naverMapView = NMFNaverMapView(frame: view.frame)
        view.addSubview(naverMapView)

        // 햄버거 버튼을 뷰에 추가
        view.addSubview(hamburgerButton)

        // 오토레이아웃을 사용하여 버튼을 위치시키세요.
        NSLayoutConstraint.activate([
            hamburgerButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
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
        
        // 메뉴 아이템 버튼 생성 및 sideMenuView에 추가
        let menuItem1 = createMenuButton(menuItem: .idSettings)
        let menuItem2 = createMenuButton(menuItem: .howTo)
        let menuItem3 = createMenuButton(menuItem: .yetToDecide)

        sideMenuView.addSubview(menuItem1)
        sideMenuView.addSubview(menuItem2)
        sideMenuView.addSubview(menuItem3)

        
        // 메뉴 아이템 버튼 레이아웃 설정
        menuItem1.centerXAnchor.constraint(equalTo: sideMenuView.centerXAnchor).isActive = true
        menuItem1.topAnchor.constraint(equalTo: sideMenuView.topAnchor, constant: 100).isActive = true
        
        menuItem2.centerXAnchor.constraint(equalTo: sideMenuView.centerXAnchor).isActive = true
        menuItem2.topAnchor.constraint(equalTo: menuItem1.bottomAnchor, constant: 20).isActive = true

        menuItem3.centerXAnchor.constraint(equalTo: sideMenuView.centerXAnchor).isActive = true
        menuItem3.topAnchor.constraint(equalTo: menuItem2.bottomAnchor, constant: 20).isActive = true
        
        // 블랙 오버레이 뷰에 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(blackOverlayViewTapped))
        blackOverlayView.addGestureRecognizer(tapGesture)

        naverMapView.mapView.touchDelegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //locationManager = NMFLocationManager.sharedInstance()
        //locationManager.add(self) // 자신을 NMFLocationManager의 위치 업데이트 수신자로 추가합니다.
        let mapView = naverMapView.mapView
        
        let initialLocation = NMGLatLng(lat: 37.5825638, lng: 127.0101949)
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
        
        // 위치 추적 모드를 지정합니다.
        //naverMapView.mapView.positionMode = .direction
        
        // 위치 기능 활성화
        //naverMapView.positionMode = .direction
        
        // 경로로 돌아가는 버튼을 추가하고 제약 조건 설정
        view.addSubview(goBackToPathButton)
        NSLayoutConstraint.activate([
        goBackToPathButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            goBackToPathButton.bottomAnchor.constraint(equalTo: locationButton.topAnchor, constant: -16)
        ])
                
        // 경로로 돌아가는 버튼에 touchUpInside 이벤트 추가
        goBackToPathButton.addTarget(self, action: #selector(moveToInitialPath), for: .touchUpInside)
        
        
        
        //서버의 최적 경로 좌표를 사용하여 경로를 지도에 표시
        fetchOptimalRouteCoordinates(minimumCount: 3) { filteredCoordinates, error in
            guard let filteredCoordinates = filteredCoordinates, error == nil else {
                print("Error fetching optimal route coordinatesAndCounts:", error?.localizedDescription ?? "unknown error")
                return
            }

            DispatchQueue.main.async {
                for i in 0..<(filteredCoordinates.count - 1) {
                    self.requestDirection(start: filteredCoordinates[i], end: filteredCoordinates[i + 1]) { polylineOverlay, error in
                        DispatchQueue.main.async {
                            if let polylineOverlay = polylineOverlay {
                                polylineOverlay.mapView = self.naverMapView.mapView
                            } else {
                                print("Error requesting direction:", error?.localizedDescription ?? "unknown error")
                            }
                        }
                    }
                }
                self.createMarkers(coordinates: filteredCoordinates)
            }
        }
        
        fetchLocations { locations, error in
            guard let locations = locations, error == nil else {
                print("Error fetching locations:", error?.localizedDescription ?? "unknown error")
                return
            }
            DispatchQueue.main.async {
                self.createHeatmap(with: locations)
            }
        }
        
    }
    //기본 마커
    func createMarkers(coordinates: [CLLocationCoordinate2D]) {
        for (index, coordinate) in coordinates.enumerated() {
            let marker = NMFMarker(position: NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude))
            marker.captionText = index == 0 ? "출발" : "\(index)"
            marker.mapView = self.naverMapView.mapView
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
    
   
    //서버에서 최적 경로 좌표를 가져오는 함수
    //JSON 데이터를 가져와서 해당 좌표를 배열로 반환
    //최적 경로 데이터를 가져오는 함수
    func fetchOptimalRouteCoordinates(minimumCount: Int, completion: @escaping ([CLLocationCoordinate2D]?, Error?) -> Void) {
        guard let url = URL(string: "http://52.79.138.34:1105/data") else {
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode(ResponseData.self, from: data)
                //count 값 필터링 수행
                let filteredCoordinatesAndCounts = decodedData.optimalRoute.filter { $0.count >= minimumCount }
                let filteredCoordinates = filteredCoordinatesAndCounts.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                completion(filteredCoordinates, nil)
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    // 서버에서 최적 경로 좌표와 장소 정보를 가져오는 함수
    // 히트맵에 사용될 데이터를 가져오는 함수
    func fetchLocations(completion: @escaping ([Location]?, Error?) -> Void) {
        guard let url = URL(string: "http://52.79.138.34:1105/data") else {
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode(ResponseData.self, from: data)
                //let coordinates = decodedData.optimalRoute.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                let locations = decodedData.locations
                completion(locations, nil)
            
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }

    
    //네이버지도 방향api를 사용해 경로를 가져오는 함수
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
    
    
    //히트맵
    func createHeatmap(with locations: [Location]) {
        for location in locations {
            let circleOverlay = NMFCircleOverlay(NMGLatLng(lat: location.latitude, lng: location.longitude), radius: calculateRadius(from: location.count))
            circleOverlay.fillColor = calculateColor(from: location.count)
            circleOverlay.mapView = naverMapView.mapView
        }
    }
    func calculateRadius(from count: Int) -> Double {
        // count 값에 따라 원하는 반지름 값을 반환합니다.
        let baseRadius = 15.0
            
        if count >= 3 {
            return baseRadius * 1.5
        } else {
            return baseRadius
        }
    }

    func calculateColor(from count: Int) -> UIColor {
        let color1 = UIColor.blue
        let color2 = UIColor.red
        let progress = CGFloat(count)/10.0
        let color = UIColor.interpolate(from: color1, to: color2, progress: progress)
        
        // count 값에 따라 원하는 색상 값을 반환합니다.
        if count >= 3 {
            return UIColor.red.withAlphaComponent(0.5)
        } else {
            return UIColor.blue.withAlphaComponent(0.5)
        }
    }
    

    
    //구조체 정의
    //서버에서 보내주는 전체 데이터를 매핑
    struct ResponseData: Codable {
        let locations: [Location]
        let optimalRoute: [RouteStep]
        
        enum CodingKeys: String, CodingKey {
            case locations
            case optimalRoute = "optimal_route"
        }
    }
    
    //locations 배열의 요소를 매핑
    struct Location: Codable {
        let count: Int
        let id: Int
        let latitude: Double
        let longitude: Double
    }
    //optimal_route 배열의 요소를 매핑
    struct RouteStep: Codable {
        let latitude: Double
        let longitude: Double
        let count: Int
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
        case idSettings = "계정정보"
        case howTo = "도움말"
        case yetToDecide = "로그아웃"

        var viewController: UIViewController? {
            switch self {
            case .idSettings:
                return idSettingsViewController()
            case .howTo:
                return howtoViewController()
            // 다른 뷰 컨트롤러를 나중에 추가할 수 있습니다.
            case .yetToDecide:
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
            case "계정정보":
                guard let idSettingsViewController = self.storyboard?.instantiateViewController(withIdentifier: "idSettingsViewControllerID") as? idSettingsViewController else { return }
                //idSettingsViewController.modalPresentationStyle = .fullScreen
                //present(idSettingsViewController, animated: true, completion: nil)
                self.navigationController?.pushViewController(idSettingsViewController, animated: true)

            case "도움말":
                guard let howtoViewController = self.storyboard?.instantiateViewController(withIdentifier: "howtoViewControllerID") as? howtoViewController else { return }
                //howtoViewController.modalPresentationStyle = .fullScreen
                //present(howtoViewController, animated: true, completion: nil)
                self.navigationController?.pushViewController(howtoViewController, animated: true)
                
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

extension UIColor {
    static func interpolate(from: UIColor, to: UIColor, progress: CGFloat) -> UIColor {
        let fromComponents = from.cgColor.components!
        let toComponents = to.cgColor.components!
        let r = (toComponents[0] - fromComponents[0]) * progress + fromComponents[0]
        let g = (toComponents[1] - fromComponents[1]) * progress + fromComponents[1]
        let b = (toComponents[2] - fromComponents[2]) * progress + fromComponents[2]
        let a = (toComponents[3] - fromComponents[3]) * progress + fromComponents[3]
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
