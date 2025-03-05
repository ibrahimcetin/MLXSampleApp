//
//  MLXViewModel.swift
//  MLXSampleApp
//
//  Created by İbrahim Çetin on 3.03.2025.
//

import Foundation
import Hub
import MLXLLM
import MLXVLM
import MLXLMCommon
import CoreImage

@MainActor
@Observable
class MLXViewModel {
    /// The model configuration. It can be a LLM or VLM
    ///
    /// You can checkout MLXLLM.ModelRegistry or MLXVLM.ModelRegistry
    /// for predefined models.
    let modelConfiguration: ModelConfiguration

    /// The model container is used to generate language model output.
    ///
    /// The model container should be loaded via ``ModelFactory.laodContainer`` method.
    ///
    /// There is two type ``ModelFactory``: ``LLMModelFactory`` and ``VLMModelFactory``.
    var modelContainer: ModelContainer?

    /// The output of the language model.
    ///
    /// Call ``generate(prompt:images:)`` method to generate output.
    var output = ""

    /// The generated tokens per second count for the output.
    ///
    /// This property updated after ``generate(prompt:images:)`` method completed.
    var tokensPerSecond: Double = 0

    /// Indicated whetever ``generate(prompt:images:)`` is running or not.
    var isRunning = false

    /// The download progress to track downloading langauge model.
    ///
    /// When you call ``generate(prompt:images:)``, the download begins if the model is missing.
    var downloadProgress: Progress?

    /// Any error message occured while the generate process.
    var errorMessage: String?

    init(modelConfiguration: ModelConfiguration) {
        self.modelConfiguration = modelConfiguration
    }

    /// The hub which changes the default download directory
    private let hub = HubApi(downloadBase: URL.downloadsDirectory.appending(path: "huggingface"))

    /// Returns appropriate `ModelFactory` for the ``modelConfiguration``
    ///
    /// If ``modelConfiguration`` is registered in the ``MLXLLM.ModelRegistry`` then it returns ``LLMModelFactory``.
    ///
    /// Otherwise, it returns ``VLMModelFactory``
    private var modelFactory: ModelFactory {
        // If the model is in LLM model registry then it is a LLM
        let isLLM = LLMModelFactory.shared.modelRegistry.models.contains { $0.name == modelConfiguration.name }

        // If the model is a LLM, select LLMFactory. If not, select VLM factory
        return if isLLM {
            LLMModelFactory.shared
        } else {
            VLMModelFactory.shared
        }
    }

    /// Loads the ``modelConfiguration`` into ``modelContainer``.
    ///
    /// You don't have to call this method explictly. ``generate(prompt:images:)`` method
    /// calls it when ``modelContainer`` is nil.
    private func loadModel() async {
        do {
            // Load the model with the appropriate factory
            modelContainer = try await modelFactory.loadContainer(
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

    /// Generates language model output. It will set ``output`` property.
    func generate(prompt: String, images: [Data] = []) async {
        isRunning = true

        // Load the model if it hasn't been loaded yet
        if modelContainer == nil {
            await loadModel()
        }

        guard let modelContainer else { isRunning = false; return }

        do {
            let result = try await modelContainer.perform { context in
                // Create images
                let images: [UserInput.Image] = images.compactMap { CIImage(data: $0) }.map { .ciImage($0) }
                let prompt = createPrompt(prompt, images: images)

                // Create user input
                var userInput = UserInput(prompt: prompt, images: images)
                userInput.processing.resize = CGSize(width: 448, height: 448)

                // Create LM input
                let input = try await context.processor.prepare(input: userInput)

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
        
        isRunning = false
    }

    /// Creates ``UserInput.Prompt`` from prompt string and images
    ///
    /// If images is empty, return ``UserInput.Prompt/text`` case with the prompt.
    ///
    /// Otherwise, it will create messages in Qwen2 VL format and return ``UserInput.Prompt/messages``.
    private nonisolated func createPrompt(_ prompt: String, images: [UserInput.Image]) -> UserInput.Prompt {
        if images.isEmpty {
            return .text(prompt)
        } else {
            // Messages format for Qwen 2 VL, Qwen 2.5 VL. May need to be adapted for other models.
            let message: Message = [
                "role": "user",
                "content": [
                    ["type": "text", "text": prompt]
                ] + images.map { _ in ["type": "image"] }
            ]

            return .messages([message])
        }
    }
}
