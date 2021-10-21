//
//  MediaDetailViewModel.swift
//  SpotifyClone
//
//  Created by Gabriel on 9/24/21.
//

import Foundation

protocol MediaDetailSectionsProtocol {}

class MediaDetailViewModel: ObservableObject {
  var api = MediaDetailsPageAPICalls()

  /// `mainItem` -  The item that was clicked to originate the current DetailView.
  var mainVM: MainViewModel
  @Published var mainItem: SpotifyModel.MediaItem?
  @Published var imageColorModel = RemoteImageModel(urlString: "")

  @Published var mediaCollection = [MediaDetailSection:[SpotifyModel.MediaItem]]()
  @Published var isLoading = [MediaDetailSection:Bool]()
  @Published var numberOfLoadedItemsInSection = [MediaDetailSection:Int]()
  @Published var accessToken: String?

  var detailScreenOrigin: DetailScreenOrigin?
  @Published var followedIDs = [String: CurrentFollowingState]()

  enum CurrentFollowingState {
    case isFollowing
    case isNotFollowing
    case error
  }

  enum DetailScreenOrigin {
    case home(homeVM: HomeViewModel)
    case search(searchVM: SearchViewModel)
    case myLibrary(myLibraryVM: MyLibraryViewModel)
  }

  init(mainVM: MainViewModel) {
    self.mainVM = mainVM
    cleanAllSection()
  }


  func getArtistScreenData() {
    MediaDetailAPICalls.UserInfoAPICalls.checksIfUserFollows(.artist, mediaVM: self,
                                                             itemID: self.mainItem!.id)
    MediaDetailAPICalls.ArtistAPICalls.getTopTracksFromArtist(mediaVM: self)
    MediaDetailAPICalls.ArtistAPICalls.getAlbumsFromArtist(mediaVM: self)
    MediaDetailAPICalls.ArtistAPICalls.getPlaylistFromArtist(mediaVM: self)
  }

  func getPlaylistScreenData(currentUserID: String) {
    MediaDetailAPICalls.UserInfoAPICalls.checksIfUserFollows(.playlist(userID: currentUserID),
                                                             mediaVM: self, itemID: self.mainItem!.id)
    MediaDetailAPICalls.PlaylistAPICalls.getTracksFromPlaylist(mediaVM: self, loadMoreEnabled: true)
  }

  func getAlbumScreenData() {
    MediaDetailAPICalls.UserInfoAPICalls.getArtistBasicInfo(mediaVM: self)
    MediaDetailAPICalls.UserInfoAPICalls.checksIfUserFollows(.album, mediaVM: self,
                                                             itemID: self.mainItem!.id)
    MediaDetailAPICalls.AlbumAPICalls.getTracksFromAlbum(mediaVM: self, loadMoreEnabled: true)
  }

  func getShowsScreenData() {
    MediaDetailAPICalls.ShowsAPICalls.getEpisodesFromShows(mediaVM: self, loadMoreEnabled: true)
  }

  func getEpisodesScreenData() {
    MediaDetailAPICalls.UserInfoAPICalls.checksIfUserFollows(.show, mediaVM: self,
                                                             itemID: self.mainItem!.id)
    MediaDetailAPICalls.EpisodeAPICalls.getEpisodeDetails(mediaVM: self)
  }



  // MARK: - API Auxiliary Functions

  func trimAndCommunicateResult(medias: [SpotifyModel.MediaItem],
                                section: MediaDetailSection,
                                limit: Int = 10,
                                loadMoreEnabled: Bool = false,
                                deleteAlmostDuplicateResults: Bool = false) {

    let noDuplicateMedias = getNonDuplicateItems(for: medias,
                                                 deleteAlmostDuplicateResults: deleteAlmostDuplicateResults)

    // If the api got more than `limit` items, return just the elements within the `limit`
    let mediasWithinTheLimit = noDuplicateMedias.count >= limit ? Array(noDuplicateMedias.prefix(limit)) : noDuplicateMedias


    if loadMoreEnabled {
      mediaCollection[section]! += noDuplicateMedias
    } else {
      mediaCollection[section] = mediasWithinTheLimit
    }

    isLoading[section] = false
  }

  func getNumberOfLoadedItems(for section: MediaDetailSection) -> Int {
    return numberOfLoadedItemsInSection[section]!
  }

  func increaseNumberOfLoadedItems(for section: MediaDetailSection, by amount: Int) {
    numberOfLoadedItemsInSection[section]! += amount
  }

  // If we are reaching the end of the scroll, fetch more data
  func shouldFetchMoreData(basedOn media: SpotifyModel.MediaItem,
                           inRelationTo medias: [SpotifyModel.MediaItem]) -> Bool {
    if medias.count > 5 {
      if media.id == medias[medias.count - 4].id {
        return true
      }
    }
    return false
  }



  // MARK: - Auxiliary Functions not related to API calls

  func clean() {
    mainItem = nil
    detailScreenOrigin = nil
    followedIDs.removeAll()
    cleanAllSection()
  }

  func setVeryFirstImageInfoBasedOn(_ firstImageURL: String) {
    imageColorModel = RemoteImageModel(urlString: firstImageURL)
  }

  func returnBasicArtistsInfo() -> [SpotifyModel.MediaItem] {
    return mediaCollection[.artistBasicInfo(.artistBasicInfo)]!
  }
  
  // MARK: - Private functions

  private func cleanAllSection() {
    cleanSection(MediaDetailSection.ArtistSections.self)
    cleanSection(MediaDetailSection.PlaylistSections.self)
    cleanSection(MediaDetailSection.AlbumSections.self)
    cleanSection(MediaDetailSection.ShowsSections.self)
    cleanSection(MediaDetailSection.EpisodeSections.self)
    cleanSection(MediaDetailSection.ArtistSections.self)
    cleanSection(MediaDetailSection.ArtistBasicInfo.self)
  }

  private func cleanSection<DetailSection: MediaDetailSectionsProtocol & CaseIterable>(_ section: DetailSection.Type) {

    for subSection in section.allCases {
      var sectionInstance: MediaDetailSection?

      if section == MediaDetailSection.ArtistSections.self {
        sectionInstance = .artist(subSection as! MediaDetailSection.ArtistSections)

      } else if section == MediaDetailSection.PlaylistSections.self {
        sectionInstance = .playlist(subSection as! MediaDetailSection.PlaylistSections)

      } else if section == MediaDetailSection.AlbumSections.self {
        sectionInstance = .album(subSection as! MediaDetailSection.AlbumSections)

      } else if section == MediaDetailSection.ShowsSections.self {
        sectionInstance = .shows(subSection as! MediaDetailSection.ShowsSections)

      } else if section == MediaDetailSection.EpisodeSections.self {
        sectionInstance = .episodes(subSection as! MediaDetailSection.EpisodeSections)

      } else if section == MediaDetailSection.ArtistBasicInfo.self {
        sectionInstance = .artistBasicInfo(subSection as! MediaDetailSection.ArtistBasicInfo)
      }
      
      isLoading[sectionInstance!] = true
      mediaCollection[sectionInstance!] = []
      numberOfLoadedItemsInSection[sectionInstance!] = 0
    }
  }

  private func getNonDuplicateItems(for medias: [SpotifyModel.MediaItem],
                                    deleteAlmostDuplicateResults: Bool = false) -> [SpotifyModel.MediaItem] {
    var trimmedMedias = [SpotifyModel.MediaItem]()
    var noDuplicateMedias = [SpotifyModel.MediaItem]()

    // Why we check for duplicate items? -
    //  Some API results are exactly the same(same id) which causes crashes

    // Why to use `deleteAlmostDuplicateResults`?
    //  to avoid results like: ["Album Name","Album Name (Radio)"], we delete those almost duplicate items.

    if !deleteAlmostDuplicateResults {
      var mediaIDs = [String]()

      for media in medias {
        if !mediaIDs.contains(media.id) {
          mediaIDs.append(media.id)
          noDuplicateMedias.append(media)
        }
      }
    } else {

      for media in medias {
        var trimmedMedia = media

        if media.title.contains("(") {
          let firstOccurrenceBraces = media.title.firstIndex(of: "(")!
          let lastIndex = media.title.endIndex

          // Remove everything after the first "("
          trimmedMedia.title.removeSubrange(firstOccurrenceBraces ..< lastIndex)
          // Remove the " " ("Album Name " -> "Album Name")
          if trimmedMedia.title.last == " " {
            trimmedMedia.title.removeLast()
          }
        }
        trimmedMedias.append(trimmedMedia)
      }

      var noDuplicateMedias = [SpotifyModel.MediaItem]()

      for media in trimmedMedias {
        var containsDuplicate = false

        if noDuplicateMedias.isEmpty {
          noDuplicateMedias.append(media)
        } else {
          for noDuplicateMedia in noDuplicateMedias {
            // .lowercased to compare only the letters, ignoring upper/lower case
            if media.title.lowercased() == noDuplicateMedia.title.lowercased() {
              containsDuplicate = true
            }
          }
          if !containsDuplicate { noDuplicateMedias.append(media) }
        }
      }
    }
    return noDuplicateMedias
  }

}
