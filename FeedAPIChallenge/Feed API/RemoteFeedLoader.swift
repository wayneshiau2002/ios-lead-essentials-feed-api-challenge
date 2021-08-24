//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

private enum FeedImageMapper {
	private static var OK_200: Int { return 200 }

	private struct Root: Decodable {
		let items: [RemoteFeedImage]
		var feedImages: [FeedImage] {
			return items.map { $0.feedImage }
		}
	}

	private struct RemoteFeedImage: Decodable {
		let image_id: UUID
		let image_desc: String?
		let image_loc: String?
		let image_url: URL

		var feedImage: FeedImage {
			return FeedImage(id: image_id, description: image_desc, location: image_loc, url: image_url)
		}
	}

	static func map(_ data: Data, from response: HTTPURLResponse) -> FeedLoader.Result {
		guard response.statusCode == OK_200,
		      let root = try? JSONDecoder().decode(Root.self, from: data) else {
			return .failure(RemoteFeedLoader.Error.invalidData)
		}

		return .success(root.feedImages)
	}
}

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url) { [weak self] result in
			guard self != nil else { return }

			switch result {
			case let .success((data, response)):
				completion(FeedImageMapper.map(data, from: response))
			case .failure(_):
				completion(.failure(Error.connectivity))
			}
		}
	}
}
