import SwiftUI

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general
    }

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
                .tag(Tabs.general)
        }
        .padding(20)
        .frame(width: 450, height: 200)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("includeSubfolders") private var includeSubfolders: Bool = true
    @AppStorage("enableJKLShortcuts") private var enableJKLShortcuts: Bool = true
    @AppStorage("seekStepSeconds") private var seekStepSeconds: Int = 5
    @AppStorage("doubleTapAction") private var doubleTapAction: String = "playPause"
    @AppStorage("showFilesInSidebar") private var showFilesInSidebar: Bool = false

    // Future settings can be added here
    // @AppStorage("anotherSetting") private var anotherSetting: Bool = false

    var body: some View {
        Form {
            Section {
                Toggle("浏览文件夹时包含子文件夹内容", isOn: $includeSubfolders)
                    .toggleStyle(.checkbox)

                Text("启用后，选中文件夹时将显示其所有子文件夹中的照片。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                Toggle("在侧栏显示文件", isOn: $showFilesInSidebar)
                    .toggleStyle(.checkbox)
                Text("开启后，侧栏“文件夹”区将列出具体文件项。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Toggle("启用 J/K/L 播放快捷键", isOn: $enableJKLShortcuts)
                    .toggleStyle(.checkbox)
                HStack {
                    Text("左右箭头跳转步长")
                    Picker("", selection: $seekStepSeconds) {
                        Text("5 秒").tag(5)
                        Text("10 秒").tag(10)
                    }
                    .frame(width: 100)
                }
                HStack {
                    Text("双击行为")
                    Picker("", selection: $doubleTapAction) {
                        Text("播放/暂停").tag("playPause")
                        Text("全屏切换").tag("fullscreen")
                    }
                    .frame(width: 140)
                }
                Text("除空格外，其他播放快捷键仅在播放中生效。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
#Preview {
    SettingsView()
}
