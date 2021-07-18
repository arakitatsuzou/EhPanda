//
//  PopularItemsRequest.swift
//  EhPanda
//
//  Created by 荒木辰造 on R 2/12/26.
//

import Kanna
import Combine
import Foundation

private func mapAppError(_ error: Error) -> AppError {
    switch error {
    case is ParseError:
        return .parseFailed
    case is URLError:
        return .networkingFailed
    default:
        return error as? AppError ?? .unknown
    }
}

struct GreetingRequest {
    var publisher: AnyPublisher<Greeting, AppError> {
        DFManager.session
            .dataTaskPublisher(
                for: Defaults.URL.greeting().safeURL()
            )
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .tryMap(Parser.parseGreeting)
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct UserInfoRequest {
    let uid: String

    var publisher: AnyPublisher<User, AppError> {
        DFManager.session
            .dataTaskPublisher(
                for: Defaults.URL.userInfo(uid: uid).safeURL()
            )
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .tryMap(Parser.parseUserInfo)
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct FavoriteNamesRequest {
    var publisher: AnyPublisher<[Int: String], AppError> {
        DFManager.session
            .dataTaskPublisher(
                for: Defaults.URL.ehConfig().safeURL()
            )
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .tryMap(Parser.parseFavoriteNames)
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct MangaItemReverseRequest {
    let detailURL: String
    var gid: String {
        if detailURL.safeURL().pathComponents.count >= 4 {
            return detailURL.safeURL().pathComponents[2]
        } else {
            return ""
        }
    }
    var token: String {
        if detailURL.safeURL().pathComponents.count >= 4 {
            return detailURL.safeURL().pathComponents[3]
        } else {
            return ""
        }
    }
    func getManga(from detail: MangaDetail?) -> Manga? {
        if let detail = detail {
            return Manga(
                detail: detail,
                gid: gid,
                token: token,
                title: detail.title,
                rating: detail.rating,
                tags: [],
                category: detail.category,
                language: detail.language,
                uploader: detail.uploader,
                publishedTime: detail.publishedTime,
                publishedDate: detail.publishedDate,
                coverURL: detail.coverURL,
                detailURL: detailURL
            )
        } else {
            return nil
        }
    }

    var publisher: AnyPublisher<Manga?, AppError> {
        DFManager.session
            .dataTaskPublisher(for: detailURL.safeURL())
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .compactMap { getManga(from: try? Parser.parseMangaDetail($0)) }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }

}

struct SearchItemsRequest {
    let keyword: String
    let filter: Filter

    var publisher: AnyPublisher<(PageNumber, [Manga]), AppError> {
        DFManager.session
            .dataTaskPublisher(
                for: Defaults.URL.searchList(
                    keyword: keyword,
                    filter: filter
                )
                .safeURL()
            )
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .map { (Parser.parsePageNum($0), Parser.parseListItems($0)) }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct MoreSearchItemsRequest {
    let keyword: String
    let filter: Filter
    let lastID: String
    let pageNum: Int

    var publisher: AnyPublisher<(PageNumber, [Manga]), AppError> {
        DFManager.session
            .dataTaskPublisher(
                for: Defaults.URL
                    .moreSearchList(
                        keyword: keyword,
                        filter: filter,
                        pageNum: "\(pageNum)",
                        lastID: lastID
                    )
                    .safeURL()
            )
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .map { (Parser.parsePageNum($0), Parser.parseListItems($0)) }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct FrontpageItemsRequest {
    var publisher: AnyPublisher<(PageNumber, [Manga]), AppError> {
        DFManager.session
            .dataTaskPublisher(for: Defaults.URL.frontpageList().safeURL())
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .map { (Parser.parsePageNum($0), Parser.parseListItems($0)) }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct MoreFrontpageItemsRequest {
    let lastID: String
    let pageNum: Int

    var publisher: AnyPublisher<(PageNumber, [Manga]), AppError> {
        DFManager.session
            .dataTaskPublisher(
                for: Defaults.URL
                    .moreFrontpageList(
                        pageNum: "\(pageNum)",
                        lastID: lastID
                    )
                    .safeURL()
            )
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .map { (Parser.parsePageNum($0), Parser.parseListItems($0)) }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct PopularItemsRequest {
    var publisher: AnyPublisher<(PageNumber, [Manga]), AppError> {
        DFManager.session
            .dataTaskPublisher(for: Defaults.URL.popularList().safeURL())
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .map { (Parser.parsePageNum($0), Parser.parseListItems($0)) }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct WatchedItemsRequest {
    var publisher: AnyPublisher<(PageNumber, [Manga]), AppError> {
        DFManager.session
            .dataTaskPublisher(for: Defaults.URL.watchedList().safeURL())
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .map { (Parser.parsePageNum($0), Parser.parseListItems($0)) }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct MoreWatchedItemsRequest {
    let lastID: String
    let pageNum: Int

    var publisher: AnyPublisher<(PageNumber, [Manga]), AppError> {
        DFManager.session
            .dataTaskPublisher(
                for: Defaults.URL
                    .moreWatchedList(
                        pageNum: "\(pageNum)",
                        lastID: lastID
                    )
                    .safeURL()
            )
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .map { (Parser.parsePageNum($0), Parser.parseListItems($0)) }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct FavoritesItemsRequest {
    let favIndex: Int

    var publisher: AnyPublisher<(PageNumber, [Manga]), AppError> {
        DFManager.session
            .dataTaskPublisher(
                for: Defaults.URL
                    .favoritesList(
                        favIndex: favIndex
                    )
                    .safeURL()
            )
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .map { (Parser.parsePageNum($0), Parser.parseListItems($0)) }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct MoreFavoritesItemsRequest {
    let favIndex: Int
    let lastID: String
    let pageNum: Int

    var publisher: AnyPublisher<(PageNumber, [Manga]), AppError> {
        DFManager.session
            .dataTaskPublisher(
                for: Defaults.URL
                    .moreFavoritesList(
                        favIndex: favIndex,
                        pageNum: "\(pageNum)",
                        lastID: lastID
                    )
                    .safeURL()
            )
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .map { (Parser.parsePageNum($0), Parser.parseListItems($0)) }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct MangaDetailRequest {
    let detailURL: String

    var publisher: AnyPublisher<(MangaDetail, APIKey), AppError> {
        DFManager.session
            .dataTaskPublisher(
                for: Defaults.URL
                    .mangaDetail(
                        url: detailURL
                    )
                    .safeURL()
            )
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .tryMap { try (Parser.parseMangaDetail($0), Parser.parseAPIKey($0))}
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct AssociatedItemsRequest {
    let keyword: AssociatedKeyword

    var publisher: AnyPublisher<(PageNumber, [Manga]), AppError> {
        DFManager.session.dataTaskPublisher(
            for: Defaults.URL
                .associatedItemsRedir(
                    keyword: keyword
                )
                .safeURL()
        )
        .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
        .map { (Parser.parsePageNum($0), Parser.parseListItems($0)) }
        .mapError(mapAppError)
        .eraseToAnyPublisher()
    }
}

struct MoreAssociatedItemsRequest {
    let keyword: AssociatedKeyword
    let lastID: String
    let pageNum: Int

    var publisher: AnyPublisher<(PageNumber, [Manga]), AppError> {
        DFManager.session
            .dataTaskPublisher(
                for: Defaults.URL
                    .moreAssociatedItemsRedir(
                        keyword: keyword,
                        lastID: lastID,
                        pageNum: "\(pageNum)"
                    )
                    .safeURL()
            )
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .map { (Parser.parsePageNum($0), Parser.parseListItems($0)) }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct AlterImagesRequest {
    let alterImagesURL: String

    var publisher: AnyPublisher<[MangaAlterData], AppError> {
        DFManager.session
            .dataTaskPublisher(for: alterImagesURL.safeURL())
            .map { Parser.parseAlterImages($0.data) }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct MangaArchiveRequest {
    let archiveURL: String

    var publisher: AnyPublisher<(MangaArchive?, CurrentGP?, CurrentCredits?), AppError> {
        DFManager.session
            .dataTaskPublisher(for: archiveURL.safeURL())
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .map {
                let funds = try? Parser.parseCurrentFunds($0)
                let archive = try? Parser.parseMangaArchive($0)

                if funds == nil {
                    return (archive, nil, nil)
                } else {
                    return (archive, funds?.0, funds?.1)
                }
            }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct MangaArchiveFundsRequest {
    let detailURL: String

    var alterDetailURL: String {
        detailURL.replacingOccurrences(
            of: Defaults.URL.exhentai,
            with: Defaults.URL.ehentai
        )
    }

    var publisher: AnyPublisher<(CurrentGP, CurrentCredits)?, AppError> {
        archiveURL(url: alterDetailURL)
            .flatMap(funds)
            .eraseToAnyPublisher()
    }

    func archiveURL(url: String) -> AnyPublisher<String, AppError> {
        DFManager.session
            .dataTaskPublisher(for: url.safeURL())
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .compactMap { try? Parser
                .parseMangaDetail($0)
                .archiveURL
            }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }

    func funds(url: String) -> AnyPublisher<(CurrentGP, CurrentCredits)?, AppError> {
        DFManager.session
            .dataTaskPublisher(for: url.safeURL())
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .tryMap(Parser.parseCurrentFunds)
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct MangaTorrentsRequest {
    let gid: String
    let token: String

    var publisher: AnyPublisher<[MangaTorrent], AppError> {
        DFManager.session
            .dataTaskPublisher(
                for: Defaults.URL
                    .mangaTorrents(
                        gid: gid,
                        token: token
                    )
                    .safeURL()
            )
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .map(Parser.parseMangaTorrents)
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct MangaCommentsRequest {
    let detailURL: String

    var publisher: AnyPublisher<[MangaComment], AppError> {
        DFManager.session
            .dataTaskPublisher(
                for: Defaults.URL
                    .mangaDetail(
                        url: detailURL
                    )
                    .safeURL()
            )
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .map(Parser.parseComments)
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct MangaContentsRequest {
    let detailURL: String
    let pageNum: Int
    let pageCount: Int

    var publisher: AnyPublisher<(PageNumber, [MangaContent]), AppError> {
        preContents(
            url: Defaults.URL
                .mangaContents(
                    detailURL: detailURL
                )
        )
        .flatMap(contents)
        .eraseToAnyPublisher()
    }

    func preContents(url: String) -> AnyPublisher<(PageNumber, [(Int, URL)]), AppError> {
        DFManager.session
            .dataTaskPublisher(for: url.safeURL())
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .tryMap { try (
                Parser.parsePageNum($0),
                Parser.parseImagePreContents($0, pageCount: pageCount)
            ) }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }

    func contents(pageNum: PageNumber, preContents: [(Int, URL)])
    -> AnyPublisher<(PageNumber, [MangaContent]), AppError>
    {
        preContents
            .publisher
            .flatMap { preContent in
                DFManager.session
                    .dataTaskPublisher(for: preContent.1)
                    .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
                    .tryMap { try Parser.parseMangaContent(doc: $0, tag: preContent.0) }
            }
            .collect()
            .map { (pageNum, $0) }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

// MARK: POST
struct AddFavoriteRequest {
    let gid: String
    let token: String
    let favIndex: Int

    var publisher: AnyPublisher<Any, AppError> {
        let url = Defaults.URL.addFavorite(gid: gid, token: token)
        let parameters: [String: String] = [
            "favcat": "\(favIndex)",
            "favnote": "",
            "apply": "Add to Favorites",
            "update": "1"
        ]

        var request = URLRequest(url: url.safeURL())

        request.httpMethod = "POST"
        request.httpBody = parameters.jsonString().data(using: .utf8)

        return DFManager.session.dataTaskPublisher(for: request)
            .map { $0 }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct DeleteFavoriteRequest {
    let gid: String

    var publisher: AnyPublisher<Any, AppError> {
        let url = Defaults.URL.ehFavorites()
        let parameters: [String: String] = [
            "ddact": "delete",
            "modifygids[]": gid,
            "apply": "Apply"
        ]

        var request = URLRequest(url: url.safeURL())

        request.httpMethod = "POST"
        request.httpBody = parameters.jsonString().data(using: .utf8)

        return DFManager.session.dataTaskPublisher(for: request)
            .map { $0 }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct SendDownloadCommandRequest {
    let archiveURL: String
    let resolution: String

    var publisher: AnyPublisher<Resp?, AppError> {
        let parameters: [String: String] = [
            "hathdl_xres": resolution
        ]

        var request = URLRequest(url: archiveURL.safeURL())

        request.httpMethod = "POST"
        request.httpBody = parameters.jsonString().data(using: .utf8)

        return DFManager.session.dataTaskPublisher(for: request)
            .tryMap { try Kanna.HTML(html: $0.data, encoding: .utf8) }
            .tryMap(Parser.parseDownloadCommandResponse)
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct RateRequest {
    let apiuid: Int
    let apikey: String
    let gid: Int
    let token: String
    let rating: Int

    var publisher: AnyPublisher<Any, AppError> {
        let url = Defaults.URL.ehAPI()
        let params: [String: Any] = [
            "method": "rategallery",
            "apiuid": apiuid,
            "apikey": apikey,
            "gid": gid,
            "token": token,
            "rating": rating
        ]

        var request = URLRequest(url: url.safeURL())

        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization
            .data(withJSONObject: params, options: [])

        return DFManager.session.dataTaskPublisher(for: request)
            .map { $0 }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct CommentRequest {
    let content: String
    let detailURL: String

    var publisher: AnyPublisher<Any, AppError> {
        let fixedContent = content.replacingOccurrences(of: "\n", with: "%0A")
        let parameters: [String: String] = ["commenttext_new": fixedContent]

        var request = URLRequest(url: detailURL.safeURL())

        request.httpMethod = "POST"
        request.httpBody = parameters.jsonString().data(using: .utf8)

        return DFManager.session.dataTaskPublisher(for: request)
            .map { $0 }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct EditCommentRequest {
    let commentID: String
    let content: String
    let detailURL: String

    var publisher: AnyPublisher<Any, AppError> {
        let fixedContent = content.replacingOccurrences(of: "\n", with: "%0A")
        let parameters: [String: String] = [
            "edit_comment": commentID,
            "commenttext_edit": fixedContent
        ]

        var request = URLRequest(url: detailURL.safeURL())

        request.httpMethod = "POST"
        request.httpBody = parameters.jsonString().data(using: .utf8)

        return DFManager.session.dataTaskPublisher(for: request)
            .map { $0 }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}

struct VoteCommentRequest {
    let apiuid: Int
    let apikey: String
    let gid: Int
    let token: String
    let commentID: Int
    let commentVote: Int

    var publisher: AnyPublisher<Any, AppError> {
        let url = Defaults.URL.ehAPI()
        let params: [String: Any] = [
            "method": "votecomment",
            "apiuid": apiuid,
            "apikey": apikey,
            "gid": gid,
            "token": token,
            "comment_id": commentID,
            "comment_vote": commentVote
        ]

        var request = URLRequest(url: url.safeURL())

        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization
            .data(withJSONObject: params, options: [])

        return DFManager.session.dataTaskPublisher(for: request)
            .map { $0 }
            .mapError(mapAppError)
            .eraseToAnyPublisher()
    }
}
