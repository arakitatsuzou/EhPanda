//
//  AppearanceSettingView.swift
//  EhPanda
//
//  Created by 荒木辰造 on R 3/01/18.
//

import SwiftUI

struct AppearanceSettingView: View {
    @EnvironmentObject var store: Store
    
    var setting: Setting? {
        store.appState.settings.setting
    }
    var settingBinding: Binding<Setting>? {
        Binding($store.appState.settings.setting)
    }
    
    var body: some View {
        if let setting = setting,
           let settingBinding = settingBinding
        {
            Form {
                Section(header: Text("全般")) {
                    HStack {
                        Text("テーマ")
                        Spacer()
                        Picker(
                            selection: settingBinding.preferredColorScheme,
                            label: Text(setting.preferredColorScheme.rawValue.lString()),
                            content: {
                                ForEach(PreferredColorScheme.allCases) { colorScheme in
                                    Text(colorScheme.rawValue.lString()).tag(colorScheme)
                                }
                            }
                        )
                    }
                    .pickerStyle(MenuPickerStyle())
                    Toggle(isOn: settingBinding.translateCategory, label: {
                        Text("カテゴリーを訳す")
                    })
                }
                Section(header: Text("ホーム")) {
                    Toggle(isOn: settingBinding.showSummaryRowTags) {
                        HStack {
                            Text("リストでタグを表示")
                            if setting.showSummaryRowTags {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    if setting.showSummaryRowTags {
                        Toggle(isOn: settingBinding.summaryRowTagsMaximumActivated) {
                            Text("リストでのタグ数を制限")
                        }
                    }
                    if setting.summaryRowTagsMaximumActivated {
                        HStack {
                            Text("タグ数上限")
                            Spacer()
                            TextField("", text: settingBinding.rawSummaryRowTagsMaximum)
                                .multilineTextAlignment(.center)
                                .keyboardType(.numberPad)
                                .background(Color(.systemGray6))
                                .frame(width: 50)
                                .cornerRadius(5)
                        }
                    }
                }
            }
            .navigationBarTitle("外観")
        }
    }
}
