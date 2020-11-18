//
//  IconSetModel.swift
//  Buman
//
//  Created by Sergey Volkov on 16.06.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import Foundation

struct IconModel: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    var isSelected: Bool
}

var IconSet = [
    IconModel(icon: "list.bullet", isSelected: false),
    IconModel(icon: "house.fill", isSelected: false),
    IconModel(icon: "flag.fill", isSelected: false),
    IconModel(icon: "mappin", isSelected: false),
    IconModel(icon: "car.fill", isSelected: false),
    IconModel(icon: "pencil", isSelected: false),
    IconModel(icon: "trash.fill", isSelected: false),
    IconModel(icon: "paperplane.fill", isSelected: false),
    IconModel(icon: "tray.2.fill", isSelected: false),
    IconModel(icon: "calendar", isSelected: false),
    IconModel(icon: "book.fill", isSelected: false),
    IconModel(icon: "bookmark.fill", isSelected: false),
    IconModel(icon: "paperclip", isSelected: false),
    IconModel(icon: "person.2.fill", isSelected: false),
    IconModel(icon: "sun.max.fill", isSelected: false),
    IconModel(icon: "moon.fill", isSelected: false),
    IconModel(icon: "snow", isSelected: false),
    IconModel(icon: "umbrella.fill", isSelected: false),
    IconModel(icon: "music.note", isSelected: false),
    IconModel(icon: "mic.fill", isSelected: false),
    IconModel(icon: "star.fill", isSelected: false),
    IconModel(icon: "bell.fill", isSelected: false),
    IconModel(icon: "tag.fill", isSelected: false),
    IconModel(icon: "bolt.fill", isSelected: false),
    IconModel(icon: "camera.fill", isSelected: false),
    IconModel(icon: "message.fill", isSelected: false),
    IconModel(icon: "phone.fill", isSelected: false),
    IconModel(icon: "video.fill", isSelected: false),
    IconModel(icon: "envelope.fill", isSelected: false),
    IconModel(icon: "ellipsis.circle.fill", isSelected: false),
    IconModel(icon: "gear", isSelected: false),
    IconModel(icon: "scissors", isSelected: false),
    IconModel(icon: "cart.fill", isSelected: false),
    IconModel(icon: "speedometer", isSelected: false),
    IconModel(icon: "hifispeaker.fill", isSelected: false),
    IconModel(icon: "paintbrush.fill", isSelected: false),
    IconModel(icon: "hammer.fill", isSelected: false),
    IconModel(icon: "link", isSelected: false),
    IconModel(icon: "bandage.fill", isSelected: false),
    IconModel(icon: "sportscourt.fill", isSelected: false),
    IconModel(icon: "alarm.fill", isSelected: false),
    IconModel(icon: "gamecontroller.fill", isSelected: false),
    IconModel(icon: "hand.thumbsup.fill", isSelected: false),
    IconModel(icon: "hand.thumbsdown.fill", isSelected: false),
    IconModel(icon: "chart.pie.fill", isSelected: false),
    IconModel(icon: "waveform.path", isSelected: false),
    IconModel(icon: "gift.fill", isSelected: false),
    IconModel(icon: "airplane", isSelected: false),
    IconModel(icon: "burn", isSelected: false),
    IconModel(icon: "lightbulb.fill", isSelected: false),
    IconModel(icon: "info", isSelected: false),
    IconModel(icon: "questionmark", isSelected: false),
    IconModel(icon: "exclamationmark", isSelected: false),
    IconModel(icon: "plus", isSelected: false),
    IconModel(icon: "minus", isSelected: false)
]

