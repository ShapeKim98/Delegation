# Delegation

한국어 | English

`@Delegatable` 매크로는 델리게이트 클로저를 저장하는 프로퍼티에 빌더 스타일의 체이닝 메서드를 추가해 SwiftUI 및 UIKit 구성 요소에서 호출 클로저를 간단히 주입할 수 있게 해 줍니다.
`@Delegatable` generates builder-style methods for closure-backed delegate properties so SwiftUI/UIKit components can adopt chained delegate configuration with minimal boilerplate.

## 설치 (Installation)

- Swift Package Manager만 지원합니다.  
  Add only via Swift Package Manager.
- `Package.swift`의 `dependencies`와 `targets` 섹션에 아래와 같이 추가하세요.  
  Add the package to the `dependencies` and `targets` sections as shown below.

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [.iOS(.v14), .macOS(.v11), .tvOS(.v14), .watchOS(.v7), .macCatalyst(.v13)],
    dependencies: [
        .package(url: "https://github.com/ShapeKim98/Delegation.git", from: "0.1.0")
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

> 현재 최신 태그는 `0.1.0`이며 릴리스에 맞춰 갱신해 주세요.  
> The current release tag is `0.1.0`; bump it as you publish newer versions.

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

## 플랫폼 요구 사항 (Platform Requirements)

- `Package.swift`는 Swift 6.2 매니페스트 형식을 사용하며 최소 지원 플랫폼은 `iOS 13 / macOS 10.15 / tvOS 13 / watchOS 6 / macCatalyst 13` 이상입니다.  
  The manifest targets Swift tools 6.2 with minimum deployment targets of iOS 13, macOS 10.15, tvOS 13, watchOS 6, and macCatalyst 13.
- SwiftUI 예시는 런타임에서 `@available` 속성을 통해 iOS 14, macOS 11, tvOS 14, watchOS 7 이상에서만 활성화됩니다.  
  The SwiftUI demo activates on iOS 14, macOS 11, tvOS 14, watchOS 7 and newer via availability annotations.

## 라이선스 (License)

이 패키지는 `LICENSE` 파일의 내용을 따릅니다.  
Refer to the `LICENSE` file for license details.
