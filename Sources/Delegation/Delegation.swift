// The Swift Programming Language
// https://docs.swift.org/swift-book

/// `@Delegatable`를 var 프로퍼티에 붙이면 동일한 이름의 빌더 메서드를 생성합니다.
///
/// ```swift
/// struct ContentView {
///     @Delegatable var pushListView: (() -> Void)?
///     @Delegatable var presentDetail: ((String) -> Void)?
/// }
/// ```
///
/// 위 선언은 아래 메서드를 자동으로 추가합니다.
///
/// ```swift
/// public func pushListView(_ perform: @escaping () -> Void) -> Self {
///     var delegator = self
///     delegator.pushListView = perform
///     return delegator
/// }
///
/// public func presentDetail(_ perform: @escaping (String) -> Void) -> Self {
///     var delegator = self
///     delegator.presentDetail = perform
///     return delegator
/// }
/// ```
///
/// 파라미터가 있는 클로저도 원형 그대로 전달받도록 생성됩니다.
@attached(peer, names: arbitrary)
public macro Delegatable() = #externalMacro(module: "DelegationMacros", type: "DelegatableMacro")

/// `@Controllable`를 void 메서드에 붙이면 동일한 시그니처로 `Self`를 반환하는 메서드를 생성합니다.
///
/// ```swift
/// @Controllable
/// private func changeNumber(_ number: Int) {
///     self.number = number
/// }
/// ```
///
/// 위 선언은 아래 메서드를 추가합니다.
///
/// ```swift
/// @discardableResult
/// public func changeNumber(_ number: Int) -> Self {
///     self.number = number
///     return self
/// }
/// ```
@attached(peer, names: arbitrary)
public macro Controllable() = #externalMacro(module: "DelegationMacros", type: "ControllableMacro")
