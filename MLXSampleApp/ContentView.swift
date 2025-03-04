//
//  ContentView.swift
//  MLXSampleApp
//
//  Created by İbrahim Çetin on 28.02.2025.
//

import SwiftUI
import MLXLLM

struct ContentView: View {
    private var vm = MLXViewModel(
        modelConfiguration: ModelRegistry.llama3_2_1B_4bit
    )

    @State private var prompt: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    Text(vm.output)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    TextField("Prompt", text: $prompt)
                        .textFieldStyle(.roundedBorder)

                    Button(action: generate) {
                        Image(systemName: "paperplane.fill")
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(sendButtonDisabled)
                }
            }
            .padding()
            .toolbar {
                if let errorMessage = vm.errorMessage {
                    ErrorView(errorMessage: errorMessage)
                }

                if let progress = vm.downloadProgress, !progress.isFinished {
                    DownloadProgressView(progress: progress)
                }

                TokensPerSecondView(value: vm.tokensPerSecond)
            }
            .navigationTitle("MLXSampleApp")
#if(os(macOS))
            .navigationSubtitle(vm.modelConfiguration.name)
#endif
        }
    }

    private func generate() {
        Task {
            await vm.generate(prompt: prompt)
        }
    }

    private var sendButtonDisabled: Bool {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        (vm.downloadProgress != nil && !vm.downloadProgress!.isFinished)
    }
}

#Preview {
    ContentView()
}
