//
//  ModelRegistery+custom.swift
//  MLXSampleApp
//
//  Created by İbrahim Çetin on 28.02.2025.
//

import MLXLLM
import MLXLMCommon

extension ModelRegistry {
    static let deepSeekR1_1_5B_4bit = ModelConfiguration(
        id: "mlx-community/DeepSeek-R1-Distill-Qwen-1.5B-4bit",
        overrideTokenizer: "PreTrainedTokenizer",
        defaultPrompt: "List five interesting facts about black holes."
    )

    static let qwen2_5Coder_1_5B_4bit = ModelConfiguration(
        id: "mlx-community/Qwen2.5-Coder-1.5B-Instruct-4bit",
        overrideTokenizer: "PreTrainedTokenizer",
        defaultPrompt: "Generate a simple HTTP server in Python."
    )

    func registerCustomModels() {
        register(configurations: [
            ModelRegistry.deepSeekR1_1_5B_4bit,
            ModelRegistry.qwen2_5Coder_1_5B_4bit
        ])
    }
}
