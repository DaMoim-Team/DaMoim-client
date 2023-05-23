//
//  whereToGo+UI.swift
//  damoim-project
//
//  Created by hansung on 2023/05/18.
//
import UIKit
import CoreLocation
import NMapsMap
import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

extension whereToGoViewController {

    
    // 최단 경로 버튼 함수
    @objc public func routeButtonTapped() {
        
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
    
    // 검출수 버튼 함수
    @objc public func routeCountButtonTapped() {
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

    // X 버튼 함수
    @objc public func closeButtonTapped() {
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
    
    // 현재 위치 버튼 함수
    @objc public func locationButtonTapped() {
        naverMapView.mapView.positionMode = .direction
    }
    
    // 햄버거 버튼 함수
    @objc public func hamburgerButtonTapped() {
        let isMenuHidden = sideMenuView.transform.tx < 0
        let translationX: CGFloat = isMenuHidden ? view.bounds.width * 0.75 : -view.bounds.width * 0.75
        UIView.animate(withDuration: 0.3) {
            self.sideMenuView.transform = self.sideMenuView.transform.translatedBy(x: translationX, y: 0)
        }
    }
    
    //새로고침 버튼 함수
    @objc public func refreshButtonTapped() {
        
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
    
    //맵에 마커를 생성하는 함수
    
    //히트맵 생성
    public func createHeatmap(with locations: [Location]) {
        circleOverlays.forEach { overlay in
            overlay.mapView = nil
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
    // 히트맵의 동그라미 크기를 설정함.
    public func calculateRadius(from count_cleanup: Int) -> Double {
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
    public func calculateColor(from count_cleanup: Int) -> UIColor {
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

    // UIImage객체를 이미지로 변환
    public func labelToImage(_ label: UILabel) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        if let context = UIGraphicsGetCurrentContext() {
            label.layer.render(in: context)
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        return nil
    }
    
    // 경로 마커 생성코드
    public func createMarkers(coordinates: [CLLocationCoordinate2D]) {
        
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
    
    // 경로 마커 순서표시
    public func createMarkerIconWithNumber(_ number: Int) -> NMFOverlayImage {
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
    
    // 메뉴 아이템
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
    
    // 사이드메뉴 생성코드
    public func createMenuButton(menuItem: MenuItem) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(menuItem.rawValue, for: .normal)
        button.tag = menuItem.hashValue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(menuItemTapped), for: .touchUpInside)
        return button
    }
    

    @objc public func menuItemTapped(sender: UIButton) {
        if let title = sender.title(for: .normal) {
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
    
    public func hideSideMenu() {
        UIView.animate(withDuration: 0.3, animations: {
            let translationX: CGFloat = -self.view.bounds.width * 0.75
            self.sideMenuView.transform = CGAffineTransform(translationX: translationX, y: 0)
            self.blackOverlayView.alpha = 0
        }) { _ in
            self.blackOverlayView.removeFromSuperview()
        }
    }
    
    // 사이드메뉴 - 로그아웃 버튼 함수
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
