//
//  HomeScreen.swift
//  SpotifyClone
//
//  Created by Gabriel on 8/31/21.
//

// TODO: Reduce duplicated code
// TODO: Convert to arrays and render using ForEach
// TODO: Separate into different items

import SwiftUI

struct HomeScreen: View {
  var body: some View {
    RadialGradientBackground()
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading) {
        SmallSongCardsGrid()
          .padding(.horizontal, lateralPadding)
          .padding(.bottom, paddingSectionSeparation)
        RecentlyPlayedScrollView()
          .padding(.bottom, paddingSectionSeparation)
        TopPodcastScrollView()
          .padding(.bottom, paddingSectionSeparation)
        RecommendedArtistScrollView()
          .padding(.bottom, paddingSectionSeparation)
        BigSongCoversScrollView()
          .padding(.bottom, paddingBottomSection)
      }.padding(.vertical, lateralPadding)
    }
  }
}



// MARK: - Constants

var lateralPadding: CGFloat = 25
var titleFontSize: CGFloat = 26
var paddingBottomSection: CGFloat = 135
var spacingSmallItems: CGFloat = 12
var spacingBigItems: CGFloat = 20

fileprivate var paddingSectionSeparation: CGFloat = 50

