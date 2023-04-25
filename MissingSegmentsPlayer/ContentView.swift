//
//  ContentView.swift
//  AVPlayer
//
//  Created by Damiaan Dufaux on 29/03/2023.
//

import SwiftUI
import AVKit
import MediaPlayer

struct PlayerWithItem {
    let player: AVPlayer
    let item: AVPlayerItem
    
    init(item: AVPlayerItem) {
        self.item = item
        self.player = AVPlayer(playerItem: item)
    }
}

let manifestWithMissingSegments = URL(string: "https://shiny-kheer-30103a.netlify.app/BigBuckBunny-4-MissingSegments-ServerDown/big_buck_bunny.m3u8")!
let videoWithMissingSegments = AVPlayerItem(url: manifestWithMissingSegments)
let player = AVPlayer(playerItem: videoWithMissingSegments)

struct ContentView: View {
    @State var playSpeed: Float = 1
    @State var currentVideoFrameRate: Float = 0
    @State var currentTime = -1.0
    @State var errorCount = 0
    @State var errorEventDates = Set<Date>()
    @State var playerError: Error?
    @State var readyState = 0
    @State var lastUpdate = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            VideoPlayer(player: player)
                .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
            
            Text(videoWithMissingSegments.asset.description).font(.system(size: 7))
            
            Button("Play video") { player.play() }
            Text("\(errorCount) error logs | current time \(currentTime)")
            Text("Player error: ").bold() + Text(playerError?.localizedDescription ?? "nil")
            Text("Playhead in loaded range: ").bold() + Text(playHeadInLoadedRange().description)
            Text("Rendered video framerate: ").bold() + Text("\(currentVideoFrameRate)")
            Text("Playback speed: ").bold() + Text("\(playSpeed)")
            Text("Ready state: ").bold() + Text("\(readyState)")
            Text("Updated at: ").bold() + Text(lastUpdate.formatted(date: .omitted, time: .complete))
        }.onReceive(timer, perform: updateTexts)
    }
    
    func updateTexts(date: Date) {
        lastUpdate = date
        playSpeed = player.rate
        currentTime = player.currentTime().seconds
        playerError = (player.error ?? player.currentItem?.error)
        readyState = player.status.rawValue

        if let rate = videoWithMissingSegments.tracks.first(where: { $0.assetTrack?.mediaType == .video })?.currentVideoFrameRate {
            currentVideoFrameRate = rate
        }
        if let log = videoWithMissingSegments.errorLog() {
            for event in log.events {
                let seenBefore: Bool
                if let date = event.date { seenBefore = errorEventDates.contains(date) }
                else { seenBefore = false }
                if !seenBefore {
                    print(event.date, event.errorDomain, event.errorStatusCode, event.errorComment, event.uri)
                }
            }
            errorEventDates = errorEventDates.union(log.events.compactMap(\.date))
            errorCount = errorEventDates.count
        }
    }
    
    func playHeadInLoadedRange() -> Bool {
        let time = videoWithMissingSegments.currentTime()
        for range in videoWithMissingSegments.loadedTimeRanges.map(\.timeRangeValue) {
            if range.containsTime(time) {
                print(range.start.seconds, range.end.seconds, time.seconds)
                return true
            }
        }
        return false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
