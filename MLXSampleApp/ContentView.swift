//
//  ContentView.swift
//  MLXSampleApp
//
//  Created by İbrahim Çetin on 28.02.2025.
//

import SwiftUI
import MLXLLM
import MLXVLM
import PhotosUI

struct ContentView: View {
    init() {
        LLMModelFactory.shared.modelRegistry.registerCustomModels()
    }

    private var vm = MLXViewModel(
        modelConfiguration: MLXVLM.ModelRegistry.qwen2VL2BInstruct4Bit
    )

    @State private var prompt: String = ""
    @State private var selectedImages: [Data] = []

    @State private var showingPhotoPicker: Bool = false
    @State private var photoSelection: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    if let selectedImage = selectedImages.first, let image = PlatformImage(data: selectedImage) {
                        Image(platformImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 200, alignment: .trailing)
                    }

                    Text(vm.output)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Image(systemName: "photo.badge.plus")
                    }

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
#if(os(iOS))
            .photosPicker(isPresented: $showingPhotoPicker, selection: $photoSelection)
            .onChange(of: photoSelection, addImage)
#elseif(os(macOS))
            .fileImporter(isPresented: $showingPhotoPicker, allowedContentTypes: [.image], onCompletion: addImage)
#endif

            .toolbar {
                if let errorMessage = vm.errorMessage {
                    ErrorView(errorMessage: errorMessage)
                }

                if let progress = vm.downloadProgress, !progress.isFinished {
                    DownloadProgressView(progress: progress)
                }

                Button(action: reset) {
                    TokensPerSecondView(value: vm.tokensPerSecond)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("MLXSampleApp")
#if(os(macOS))
            .navigationSubtitle(vm.modelConfiguration.name)
#endif
        }
    }

    private func generate() {
        Task {
            await vm.generate(prompt: prompt, images: selectedImages)
        }
    }

#if(os(iOS))
    private func addImage() {
        Task {
            if let data = try? await photoSelection?.loadTransferable(type: Data.self) {
                selectedImages = [data]
            } else {
                selectedImages = []
            }
        }
    }
#elseif(os(macOS))
    private func addImage(_ result: Result<URL, any Error>) {
        if let url = try? result.get(), let data = try? Data(contentsOf: url) {
            selectedImages = [data]
        } else {
            selectedImages = []
        }
    }
#endif

    private func reset() {
        vm.output = ""
        vm.tokensPerSecond = 0

        prompt = ""
        selectedImages = []
    }

    private var sendButtonDisabled: Bool {
        vm.isRunning ||
        prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        (vm.downloadProgress != nil && !vm.downloadProgress!.isFinished)
    }
}

#Preview {
    ContentView()
}
