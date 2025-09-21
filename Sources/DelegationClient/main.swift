import Delegation

struct ContentView {
    @Delegatable var pushListView: (() -> Void)? = nil
    @Delegatable var presentDetail: ((String) -> Void)?
    @Delegatable var loadData: (() async -> Void)?
    @Delegatable var showAlert: ((String, Int) -> Void)?
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

contentView.pushListView?()
contentView.presentDetail?("샘플 ID")
Task {
    await contentView.loadData?()
}
contentView.showAlert?("주의", 3)

