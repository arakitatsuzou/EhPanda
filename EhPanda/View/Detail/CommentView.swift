//
//  CommentView.swift
//  EhPanda
//
//  Created by 荒木辰造 on R 3/01/02.
//

import SwiftUI
import Kingfisher
import TTProgressHUD

struct CommentView: View, StoreAccessor {
    @EnvironmentObject var store: Store
    @Environment(\.colorScheme) private var colorScheme

    @State private var commentJumpID: String?
    @State private var isNavActive = false

    @State private var hudVisible = false
    @State private var hudConfig = TTProgressHUDConfig(
        hapticsEnabled: false
    )

    private let gid: String
    private let depth: Int

    init(gid: String, depth: Int) {
        self.gid = gid
        self.depth = depth
    }

    // MARK: CommentView
    var body: some View {
        ZStack {
            NavigationLink(
                "",
                destination: DetailView(
                    gid: commentJumpID ?? gid,
                    depth: depth + 1
                ),
                isActive: $isNavActive
            )
            ScrollView {
                VStack {
                    ForEach(comments) { comment in
                        CommentCell(
                            editCommentContent: trimContents(
                                comment.contents
                            ),
                            gid: gid,
                            comment: comment,
                            linkAction: onLinkTap
                        )
                    }
                }
                .padding(.horizontal)
            }
            TTProgressHUD($hudVisible, config: hudConfig)
        }
        .navigationBarItems(
            trailing:
                Button(action: toggleDraft, label: {
                    Image(systemName: "square.and.pencil")
                    Text("Post Comment")
                })
                .sheet(item: environmentBinding.commentViewSheetState) { item in
                    switch item {
                    case .comment:
                        DraftCommentView(
                            content: commentContentBinding,
                            title: "Post Comment",
                            postAction: onDraftCommentViewPost,
                            cancelAction: onDraftCommentViewCancel
                        )
                        .accentColor(accentColor)
                        .preferredColorScheme(colorScheme)
                        .blur(radius: environment.blurRadius)
                        .allowsHitTesting(environment.isAppUnlocked)
                    }
                }
        )
        .onAppear(perform: onAppear)
        .onChange(
            of: environment.mangaItemReverseID,
            perform: onJumpIDChange
        )
        .onChange(
            of: environment.mangaItemReverseLoading,
            perform: onFetchFinish
        )
    }
}

private extension CommentView {
    var comments: [MangaComment] {
        store.appState.cachedList.items?[gid]?.detail?.comments ?? []
    }

    var detailInfoBinding: Binding<AppState.DetailInfo> {
        $store.appState.detailInfo
    }
    var environmentBinding: Binding<AppState.Environment> {
        $store.appState.environment
    }
    var commentInfoBinding: Binding<AppState.CommentInfo> {
        $store.appState.commentInfo
    }
    var commentContent: String {
        commentInfo.commentContent
    }
    var commentContentBinding: Binding<String> {
        commentInfoBinding.commentContent
    }

    func onAppear() {
        replaceMangaCommentJumpID(gid: nil)
    }
    func onFetchFinish(_ value: Bool) {
        if !value {
            dismissHUD()
        }
    }
    func onLinkTap(_ link: URL) {
        if isValidDetailURL(url: link) && isTokenMatched {
            let gid = link.pathComponents[2]
            if cachedList.hasCached(gid: gid) {
                replaceMangaCommentJumpID(gid: gid)
            } else {
                fetchMangaWithDetailURL(link.absoluteString)
                showHUD()
            }
        } else {
            UIApplication.shared.open(link, options: [:], completionHandler: nil)
        }
    }
    func onJumpIDChange(_ value: String?) {
        if value != nil {
            commentJumpID = value
            isNavActive = true

            replaceMangaCommentJumpID(gid: nil)
        }
    }
    func onDraftCommentViewPost() {
        if !commentContent.isEmpty {
            postComment()
            toggleCommentViewSheetNil()
        }
    }
    func onDraftCommentViewCancel() {
        toggleCommentViewSheetNil()
    }

    func showHUD() {
        hudConfig = TTProgressHUDConfig(
            type: .loading,
            title: "Loading...".localized()
        )
        hudVisible = true
    }
    func dismissHUD() {
        hudVisible = false
        hudConfig = TTProgressHUDConfig(
            hapticsEnabled: false
        )
    }

    func trimContents(_ contents: [CommentContent]) -> String {
        contents
            .filter {
                [.plainText, .linkedText, .singleLink]
                    .contains($0.type)
            }
            .compactMap {
                if $0.type == .singleLink {
                    return $0.link
                } else {
                    return $0.text
                }
            }
            .joined()
    }

    func postComment() {
        store.dispatch(.comment(gid: gid, content: commentContent))
        store.dispatch(.cleanCommentViewCommentContent)
    }
    func fetchMangaWithDetailURL(_ detailURL: String) {
        store.dispatch(.fetchMangaItemReverse(detailURL: detailURL))
    }
    func replaceMangaCommentJumpID(gid: String?) {
        store.dispatch(.replaceMangaCommentJumpID(gid: gid))
    }

    func toggleDraft() {
        store.dispatch(.toggleCommentViewSheetState(state: .comment))
    }
    func toggleCommentViewSheetNil() {
        store.dispatch(.toggleCommentViewSheetNil)
    }
}

// MARK: CommentCell
private struct CommentCell: View, StoreAccessor {
    @EnvironmentObject var store: Store
    @Environment(\.colorScheme) private var colorScheme
    @State private var editCommentContent: String
    @State private var isPresented = false

    private let gid: String
    private var comment: MangaComment
    private let linkAction: (URL) -> Void

    init(
        editCommentContent: String,
        gid: String,
        comment: MangaComment,
        linkAction: @escaping (URL) -> Void
    ) {
        _editCommentContent = State(
            initialValue: editCommentContent
        )
        self.gid = gid
        self.comment = comment
        self.linkAction = linkAction
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(comment.author)
                    .fontWeight(.bold)
                    .font(.subheadline)
                Spacer()
                Group {
                    if comment.votedUp {
                        Image(systemName: "hand.thumbsup.fill")
                    } else if comment.votedDown {
                        Image(systemName: "hand.thumbsdown.fill")
                    }
                    if let score = comment.score {
                        Text(score)
                    }
                    Text(comment.commentTime)
                }
                .font(.footnote)
                .foregroundColor(.secondary)
            }
            ForEach(comment.contents) { content in
                switch content.type {
                case .plainText:
                    if let text = content.text {
                        LinkedText(text, linkAction)
                    }
                case .linkedText:
                    if let text = content.text,
                       let link = content.link
                    {
                        Text(text)
                            .foregroundColor(.accentColor)
                            .onTapGesture {
                                linkAction(link.safeURL())
                            }
                    }
                case .singleLink:
                    if let link = content.link {
                        LinkedText(link, linkAction)
                    }
                default:
                    generateWebImages(
                        imgURL: content.imgURL,
                        secondImgURL: content.secondImgURL,
                        link: content.link,
                        secondLink: content.secondLink
                    )
                }
            }
            .padding(.top, 1)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .contentShape(
            RoundedRectangle(
                cornerRadius: 15,
                style: .continuous
            )
        )
        .sheet(isPresented: $isPresented) {
            DraftCommentView(
                content: $editCommentContent,
                title: "Edit Comment",
                postAction: onDraftCommentViewPost,
                cancelAction: onDraftCommentViewCancel
            )
            .accentColor(accentColor)
            .preferredColorScheme(colorScheme)
        }
        .contextMenu {
            if comment.votable {
                Button(action: voteUp) {
                    Text("Agree")
                    if comment.votedUp {
                        Image(systemName: "hand.thumbsup.fill")
                    } else {
                        Image(systemName: "hand.thumbsup")
                    }
                }
                Button(action: voteDown) {
                    Text("Disagree")
                    if comment.votedDown {
                        Image(systemName: "hand.thumbsdown.fill")
                    } else {
                        Image(systemName: "hand.thumbsdown")
                    }
                }
            }
            if comment.editable {
                Button(action: togglePresented) {
                    Text("Edit")
                    Image(systemName: "square.and.pencil")
                }
            }
        }
    }
}

private extension CommentCell {
    var detailInfoBinding: Binding<AppState.DetailInfo> {
        $store.appState.detailInfo
    }

    func generateWebImages(
        imgURL: String?,
        secondImgURL: String?,
        link: String?,
        secondLink: String?
    ) -> some View {
        Group {
            // Double
            if let imgURL = imgURL,
               let secondImgURL = secondImgURL
            {
                HStack(spacing: 0) {
                    if let link = link,
                       let secondLink = secondLink
                    {
                        KFImage(URL(string: imgURL))
                            .resizable()
                            .scaledToFit()
                            .frame(width: screenW / 4)
                            .onTapGesture {
                                linkAction(link.safeURL())
                            }
                        KFImage(URL(string: secondImgURL))
                            .resizable()
                            .scaledToFit()
                            .frame(width: screenW / 4)
                            .onTapGesture {
                                linkAction(secondLink.safeURL())
                            }
                    } else {
                        KFImage(URL(string: imgURL))
                            .resizable()
                            .scaledToFit()
                            .frame(width: screenW / 4)
                        KFImage(URL(string: secondImgURL))
                            .resizable()
                            .scaledToFit()
                            .frame(width: screenW / 4)
                    }
                }
            }
            // Single
            else if let imgURL = imgURL {
                if let link = link {
                    KFImage(URL(string: imgURL))
                        .resizable()
                        .scaledToFit()
                        .frame(width: screenW / 2)
                        .onTapGesture {
                            linkAction(link.safeURL())
                        }
                } else {
                    KFImage(URL(string: imgURL))
                        .resizable()
                        .scaledToFit()
                        .frame(width: screenW / 2)
                }
            }
        }
    }

    func onDraftCommentViewPost() {
        if !editCommentContent.isEmpty {
            editComment()
            togglePresented()
        }
    }
    func onDraftCommentViewCancel() {
        togglePresented()
    }

    func voteUp() {
        store.dispatch(.voteComment(gid: gid, commentID: comment.commentID, vote: 1))
    }
    func voteDown() {
        store.dispatch(.voteComment(gid: gid, commentID: comment.commentID, vote: -1))
    }
    func editComment() {
        store.dispatch(.editComment(gid: gid, commentID: comment.commentID, content: editCommentContent))
    }
    func togglePresented() {
        isPresented.toggle()
    }

}

// MARK: Definition
enum CommentViewSheetState: Identifiable {
    var id: Int { hashValue }

    case comment
}
