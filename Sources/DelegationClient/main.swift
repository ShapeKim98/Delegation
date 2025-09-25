import Delegation
import SwiftUI

struct ContentView: View {
    @Delegatable var pushListView: (() -> Void)? = nil
    @Delegatable var presentDetail: ((String) -> Void)?
    @Delegatable var loadData: (() async -> Void)?
    @Delegatable var showAlert: ((String, Int) -> Void)?

    @State private var number: Int = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("현재 숫자: \(number)")

            Button("목록 화면으로 이동") {
                pushListView?()
            }

            Button("디테일 보기") {
                presentDetail?("샘플 ID")
            }

            Button("데이터 불러오기") {
                Task {
                    await loadData?()
                }
            }

            Button("경고 표시") {
                showAlert?("주의", 3)
            }
        }
    }

    var currentNumber: Int { _number.wrappedValue }

    @Controllable
    private mutating func changeNumber(_ number: Int) {
        _number = State(initialValue: number)
    }
}

var contentView = ContentView()
    .pushListView {
        print("pushListView 호출")
    }
    .presentDetail { identifier in
        print("presentDetail 호출: \(identifier)")
    }
    .loadData {
        print("loadData 호출")
    }
    .showAlert { title, count in
        print("showAlert 호출: title=\(title), count=\(count)")
    }
    .changeNumber(10)

contentView.pushListView?()
contentView.presentDetail?("샘플 ID")
Task {
    await contentView.loadData?()
}
contentView.showAlert?("주의", 3)
print("SwiftUI 뷰 상태 숫자: \(contentView.currentNumber)")

final class NumberController {
    var number = 0

    @Controllable
    private func changeNumber(_ number: Int) {
        self.number = number
    }
}

let controller = NumberController().changeNumber(42)
print("클래스 숫자: \(controller.number)")
