import Foundation
import CoreML
import Flutter

@objc class CoreMLChatService: NSObject, FlutterPlugin {
    private var model: MLModel?
    private let methodChannel: FlutterMethodChannel
    
    init(channel: FlutterMethodChannel) {
        self.methodChannel = channel
        super.init()
    }
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "coreml_chat", binaryMessenger: registrar.messenger())
        let instance = CoreMLChatService(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "loadModel":
            loadModel(result: result)
        case "generateText":
            if let args = call.arguments as? [String: Any],
               let prompt = args["prompt"] as? String,
               let maxTokens = args["maxTokens"] as? Int {
                generateText(prompt: prompt, maxTokens: maxTokens, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            }
        case "isModelLoaded":
            result(model != nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func loadModel(result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Load the actual Core ML model from bundle
                guard let modelURL = Bundle.main.url(forResource: "coreml_model", withExtension: "mlmodelc") else {
                    print("Core ML model not found in bundle")
                    DispatchQueue.main.async {
                        result(false)
                    }
                    return
                }
                
                print("Loading Core ML model from: \(modelURL)")
                self.model = try MLModel(contentsOf: modelURL)
                print("Core ML model loaded successfully!")
                
                DispatchQueue.main.async {
                    result(true)
                }
            } catch {
                print("Error loading Core ML model: \(error)")
                DispatchQueue.main.async {
                    result(false)
                }
            }
        }
    }
    
    private func generateText(prompt: String, maxTokens: Int, result: @escaping FlutterResult) {
        guard let mlModel = model else {
            // Fallback response for demo purposes
            let responses = [
                "That's an interesting question! Let me think about that.",
                "I understand what you're asking. Here's my perspective:",
                "Based on what you've said, I would suggest:",
                "That's a great point. I think we could explore:",
                "I see what you mean. Perhaps we could consider:"
            ]
            
            let randomResponse = responses.randomElement() ?? "I'm processing your request."
            let fullResponse = "\(randomResponse) (Core ML model not loaded - using fallback responses)"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                result(fullResponse)
            }
            return
        }
        
        // Attempt to use the actual Core ML model
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                print("Attempting Core ML inference with prompt: \(prompt)")
                
                // First, let's inspect what features this model expects
                let modelDescription = mlModel.modelDescription
                print("Model input features:")
                for inputFeature in modelDescription.inputDescriptionsByName {
                    print("  - \(inputFeature.key): \(inputFeature.value.type)")
                }
                print("Model output features:")
                for outputFeature in modelDescription.outputDescriptionsByName {
                    print("  - \(outputFeature.key): \(outputFeature.value.type)")
                }
                
                // Create inputs for transformer model with position_ids
                var inputDict: [String: MLFeatureValue] = [:]
                
                // Handle each required input
                for (inputName, inputDescription) in modelDescription.inputDescriptionsByName {
                    print("Processing input: \(inputName) of type: \(inputDescription.type)")
                    
                    switch inputName {
                    case "input_ids":
                        // Simple tokenization - convert prompt to token IDs
                        let tokens = self.simpleTokenize(prompt)
                        let tokenArray = try MLMultiArray(shape: [1, NSNumber(value: tokens.count)], dataType: .int32)
                        for (i, token) in tokens.enumerated() {
                            tokenArray[i] = NSNumber(value: token)
                        }
                        inputDict[inputName] = MLFeatureValue(multiArray: tokenArray)
                        
                    case "attention_mask":
                        // Create attention mask (all 1s for our tokens)
                        let tokens = self.simpleTokenize(prompt)
                        let maskArray = try MLMultiArray(shape: [1, NSNumber(value: tokens.count)], dataType: .int32)
                        for i in 0..<tokens.count {
                            maskArray[i] = NSNumber(value: 1)
                        }
                        inputDict[inputName] = MLFeatureValue(multiArray: maskArray)
                        
                    case "position_ids":
                        // Create position IDs (0, 1, 2, 3, ...)
                        let tokens = self.simpleTokenize(prompt)
                        let positionArray = try MLMultiArray(shape: [1, NSNumber(value: tokens.count)], dataType: .int32)
                        for i in 0..<tokens.count {
                            positionArray[i] = NSNumber(value: i)
                        }
                        inputDict[inputName] = MLFeatureValue(multiArray: positionArray)
                        
                    default:
                        print("Unknown input: \(inputName), skipping...")
                    }
                }
                
                if !inputDict.isEmpty {
                    let input = try MLDictionaryFeatureProvider(dictionary: inputDict)
                    let prediction = try mlModel.prediction(from: input)
                    
                    // Try to extract output
                    if let firstOutputName = modelDescription.outputDescriptionsByName.keys.first,
                       let outputFeature = prediction.featureValue(for: firstOutputName) {
                        
                        if let outputArray = outputFeature.multiArrayValue {
                            // Convert output tokens back to text (simplified)
                            let outputText = "Generated \(outputArray.count) tokens"
                            DispatchQueue.main.async {
                                result("Core ML: \(outputText) for prompt: '\(prompt)'")
                            }
                            return
                        } else if outputFeature.type == .string {
                            DispatchQueue.main.async {
                                result("Core ML: \(outputFeature.stringValue)")
                            }
                            return
                        }
                    }
                }
                
                // If we reach here, the model format didn't match our assumptions
                print("Core ML model input/output format not recognized")
                DispatchQueue.main.async {
                    result("Core ML model loaded but format not compatible. Prompt: '\(prompt)' (Model integration needs adjustment for your specific model type)")
                }
                
            } catch {
                print("Core ML inference error: \(error)")
                print("Error details: \(error)")
                if let mlError = error as? MLModelError {
                    print("ML Model Error code: \(mlError.code)")
                    print("ML Model Error description: \(mlError.localizedDescription)")
                }
                DispatchQueue.main.async {
                    result("Core ML inference error: \(error.localizedDescription). Using fallback for: '\(prompt)'")
                }
            }
        }
    }
    
    private func simpleTokenize(_ text: String) -> [Int32] {
        // Very simple tokenization - convert each character to ASCII value
        // This is a placeholder - real models need proper tokenization
        let tokens = text.compactMap { char in
            Int32(char.asciiValue ?? 32) // Use space (32) as fallback
        }
        
        // Ensure we have at least one token
        return tokens.isEmpty ? [32] : Array(tokens.prefix(50)) // Limit to 50 tokens
    }
}