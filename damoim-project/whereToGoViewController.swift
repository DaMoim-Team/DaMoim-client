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

    public var naverMapView: NMFNaverMapView!
    public var locationManager: CLLocationManager! // NMFLocationManager를 사용합니다.
    public var minCount: Int = 0

    public var locations: [Location] = []
    public var optimalroute: [CLLocationCoordinate2D] = []
    
    //출발지
    var startLocation: Location?
    
    // 밑쪽 변수
    public var polylineOverlays: [NMFPolylineOverlay] = []
    public var markers: [NMFMarker] = []
    public var totalRouteSegments = 0
    public var completedRouteSegments = 0
    public var fetchedLocations: [Location] = []
    public var optimalrouteWithoutStart: [CLLocationCoordinate2D] = []
    
    public var circleOverlays: [NMFCircleOverlay] = []
    
    public var circleLabels: [NMFMarker] = []
    
    // 햄버거 버튼을 프로퍼티로 추가
    public lazy var hamburgerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "hamburgerIcon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(hamburgerButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // 최단 루트 기준 경로 버튼
    public lazy var routeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "shortestroute")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(routeButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // 검출 수 기준 경로 버튼
    public lazy var routeCountButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "countroute")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(routeCountButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    //x버튼
    public lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "xIcon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    //새로고침 버튼
    public let refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "refreshIcon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    //사이드메뉴
    public lazy var sideMenuView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    public let blackOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //UserDefaults의 minCount값 불러오기. 초기값은 3
        minCount = UserDefaults.standard.integer(forKey: "minCount") == 0 ? 3 : UserDefaults.standard.integer(forKey: "minCount")
        
        
        // 네이버 지도 설정
        naverMapView = NMFNaverMapView(frame: view.frame)
        view.addSubview(naverMapView)

        // 햄버거 버튼을 뷰에 추가
        view.addSubview(hamburgerButton)

        // 햄버거 버튼 autolayout
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

        // 서브뷰 constraint
        accountInfoView.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor).isActive = true
        accountInfoView.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor).isActive = true
        accountInfoView.topAnchor.constraint(equalTo: sideMenuView.topAnchor).isActive = true
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

    @objc private func blackOverlayViewTapped() {
        // 블랙 오버레이 뷰를 터치하면 사이드 메뉴를 숨깁니다.
        hideSideMenu()
        
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
