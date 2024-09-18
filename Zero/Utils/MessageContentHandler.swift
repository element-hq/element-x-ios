import Foundation

class MessageContentHandler {
    
    func parseMessageContent(contentJsonString: String?) -> EventMessageContent? {
        if let contentData = contentJsonString?.data(using: .utf8) {
            do {
                // Decode the JSON data into MessageContent
                let messageContent = try JSONDecoder().decode(EventMessageContent.self, from: contentData)
                return messageContent
            } catch {
                print("Failed to decode content JSON: \(error)")
                return nil
            }
        } else {
            print("Failed to decode content JSON: `contentJsonString` is either nil or empty")
            return nil
        }
    }
}
