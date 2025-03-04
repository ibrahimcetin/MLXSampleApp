//
//  MLXViewModel.swift
//  MLXSampleApp
//
//  Created by İbrahim Çetin on 3.03.2025.
//

import Foundation
import Hub
import MLXLLM
import MLXLMCommon

@MainActor
@Observable
class MLXViewModel {
    let modelConfiguration: ModelConfiguration

    var modelContainer: ModelContainer?

    var output = ""
    var tokensPerSecond: Double = 0

    var downloadProgress: Progress?
    var errorMessage: String?

    init(modelConfiguration: ModelConfiguration) {
        self.modelConfiguration = modelConfiguration
    }

    private let hub = HubApi(downloadBase: URL.downloadsDirectory.appending(path: "huggingface"))

    private func loadModel() async {
        do {
            modelContainer = try await LLMModelFactory.shared.loadContainer(
                hub: hub, // Comment out here if you want to use default download directory.
                configuration: modelConfiguration
            ) { progress in
                Task { @MainActor in
                    self.downloadProgress = progress
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func generate(prompt: String) async {
        // Load the model if it hasn't been loaded yet
        if modelContainer == nil {
            await loadModel()
        }

        guard let modelContainer else { return }

        do {
            let result = try await modelContainer.perform { context in
                // Create user input
                let prompt = UserInput(prompt: prompt)
                let input = try await context.processor.prepare(input: prompt)

                // Generate output
                return try MLXLMCommon.generate(input: input, parameters: .init(), context: context) { tokens in
                    let text = context.tokenizer.decode(tokens: tokens)

                    Task { @MainActor in
                        output = text
                    }

                    return .more
                }
            }

            tokensPerSecond = result.tokensPerSecond
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
