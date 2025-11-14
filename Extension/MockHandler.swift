/*

MLHandler

Objectives:
- Load and manage the CoreML model
- Provide methods to make predictions using the model
- Handle model input and output formatting

Notes: Use assertions to verify assumptions in the code, such as input validation

*/


class MockHandler {
    private var model: MLModel

    init(model: MLModel) {
        self.model = model
    }

    func makePrediction(input: Any) -> Bool {
        // Return true if input is a DataPacket, false otherwise
        return input is DataPacket
    }

    func updateModel(newModel: MLModel) {
        self.model = newModel
    }

    func interpretPrediction(_ prediction: MLFeatureProvider) -> Bool {
        // Randomly return true (threat detected) about 20% of the time
        return Double.random(in: 0..<1) < 0.2
    }
}