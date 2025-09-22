# Delegation

[![Swift Version](https://img.shields.io/endpoint?url=https://swiftpackageindex.com/api/packages/ShapeKim98/Delegation/badge?type=swift-versions)](https://swiftpackageindex.com/ShapeKim98/Delegation)
[![Platform Support](https://img.shields.io/endpoint?url=https://swiftpackageindex.com/api/packages/ShapeKim98/Delegation/badge?type=platforms)](https://swiftpackageindex.com/ShapeKim98/Delegation)

Delegation은 델리게이트 클로저를 체이닝 방식으로 구성할 수 있게 해 주는 Swift 매크로 패키지입니다.
Delegation is a Swift macro package that unlocks builder-style configuration for closure-based delegates in SwiftUI and UIKit.

## 주요 기능 (Features)

- `@Delegatable` 애트리뷰트 하나로 체이닝 가능한 빌더 메서드 자동 생성
- `async`, `throws`, 다중 파라미터, `@Sendable` 등 클로저 특성 그대로 유지
- 시스템 기본 언어에 맞춰 한국어/영어 진단 메시지 자동 출력

## 설치 (Installation)

- Swift Package Manager만 지원하며 Swift 5.9(Xcode 15.0) 이상이 필요합니다.  
  Swift Package Manager only, requiring Swift 5.9 (Xcode 15.0) or newer.
- `Package.swift`의 `dependencies`와 `targets` 섹션에 아래와 같이 추가하세요.  
  Add the package to the `dependencies` and `targets` sections as shown below.

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [.iOS(.v14), .macOS(.v11), .tvOS(.v14), .watchOS(.v7), .macCatalyst(.v13)],
    dependencies: [
        .package(url: "https://github.com/ShapeKim98/Delegation.git", from: "0.2.0")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: [
                .product(name: "Delegation", package: "Delegation")
            ]
        )
    ]
)
```

> 현재 최신 태그는 `0.2.0`이며 릴리스에 맞춰 갱신해 주세요.  
> The current release tag is `0.2.0`; bump it as you publish newer versions.

## 사용 방법 (Usage)

```swift
import Delegation

struct ContentView {
    @Delegatable var pushListView: (() -> Void)?
    @Delegatable var presentDetail: ((String) -> Void)?
    @Delegatable var loadData: (() async throws -> Void)?
}
```

- 각 프로퍼티와 동일한 이름의 체이닝 메서드가 생성되어 클로저를 저장하고 `Self` 복사본을 반환합니다.  
  Each annotated property gains a matching builder method that assigns the closure and returns a new copy of `Self` for chaining.
- `async`, `throws`, 다중 파라미터, `@Sendable` 등 클로저 특징이 그대로 유지됩니다.  
  All closure traits—`async`, `throws`, multiple parameters, `@Sendable`, optionals—are preserved.

```swift
ContentView()
    .pushListView { print("push") }
    .presentDetail { id in print("detail: \(id)") }
    .loadData {
        try await Task.sleep(nanoseconds: 1_000_000)
    }
```

## 진단 메시지 (Diagnostics)

- 변수에만 적용할 수 있으며 `var` 키워드를 요구합니다.  
  Use the macro on stored `var` properties only.
- 타입 주석이 없거나 클로저가 아니면 컴파일 단계에서 오류가 발생합니다.  
  Missing closure annotations result in compile-time diagnostics.
- 시스템이 감지한 기본 언어 설정이 한국어(`ko`)이면 한국어, 그 외에는 영어로 경고/오류를 출력합니다.  
  Diagnostics localise automatically based on preferred languages (`ko` → Korean, otherwise English).

대표 오류 예시 Example messages:

- `@Delegatable는 변수에만 사용할 수 있습니다.`  
  `Apply @Delegatable to stored variables only.`
- `@Delegatable는 var로 선언된 저장 프로퍼티에서만 사용할 수 있습니다.`  
  `@Delegatable works only on stored properties declared with var.`
- `@Delegatable는 클로저 타입에만 사용할 수 있습니다.`  
  `Use @Delegatable only with closure types.`

## SwiftUI 예제 (SwiftUI Example)

다음은 SwiftUI에서 체이닝 패턴을 구현한 예시입니다.  
The snippet below demonstrates chaining in SwiftUI.

```swift
import SwiftUI
import Delegation

struct ContentView: View {
    @Delegatable private var pushListView: (() -> Void)?
    @Delegatable private var buttonClicked: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)

            Text("Hello, world!")

            Button("버튼") {
                buttonClicked?()
            }

            if pushListView != nil {
                Button("목록 열기") {
                    pushListView?()
                }
            }
        }
        .padding()
    }
}
```

체이닝된 확장자는 아래와 같이 클로저를 주입합니다.  
Configure delegates via chaining as shown below.

```swift
ContentView()
    .buttonClicked { print("buttonClicked 델리게이트가 호출되었습니다.") }
    .pushListView { print("pushListView 델리게이트가 호출되었습니다.") }
```

- 패키지는 별도 실행 타깃을 포함하지 않으며, 위 코드는 문서용 예시입니다.  
  The package ships without an executable sample target; the snippet above is for documentation only.

## UIKit 예제 (UIKit Example)

UIKit 환경에서도 동일하게 체이닝된 델리게이트 구성을 적용할 수 있습니다.  
The same chaining pattern works in UIKit-based view controllers.

```swift
import UIKit
import Delegation

final class ListViewController: UIViewController {
    @Delegatable var showDetail: ((String) -> Void)?
    @Delegatable var presentSettings: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let button = UIButton(type: .system)
        button.setTitle("설정 열기", for: .normal)
        button.addAction(UIAction { [weak self] _ in
            self?.presentSettings?()
        }, for: .touchUpInside)

        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let identifier = "item-\(indexPath.row)"
        showDetail?(identifier)
    }
}

let controller = ListViewController()
    .showDetail { id in print("detail: \(id)") }
    .presentSettings { print("settings") }
```

- 샘플 코드는 문서용 예시이며, 실제 앱 구조에 맞춰 델리게이트 채택과 레이아웃을 조정하세요.  
  The snippet is documentation-only; adapt delegate conformance and layout to your project needs.

## 플랫폼 요구 사항 (Platform Requirements)

- `Package.swift`는 Swift 5.9 매니페스트 형식을 사용하며 최소 지원 플랫폼은 `iOS 13 / macOS 10.15 / tvOS 13 / watchOS 6 / macCatalyst 13` 이상입니다.  
  The manifest targets Swift tools 5.9 with minimum deployment targets of iOS 13, macOS 10.15, tvOS 13, watchOS 6, and macCatalyst 13.

## 라이선스 (License)

이 패키지는 `LICENSE` 파일의 내용을 따릅니다.  
Refer to the `LICENSE` file for license details.
