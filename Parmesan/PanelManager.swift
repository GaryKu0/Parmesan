//
//  PanelManager.swift
//  Tinder-like
//
//  Created by 郭粟閣 on 2024/3/11.
//

import Foundation
import Combine

class PanelManager: ObservableObject {
    @Published var selectedItem: PanelItem?
    @Published var currentPerson: String?
    @Published var isPanelPresented: Bool = false

    func showMatchedPanel(for person: String) {
        self.currentPerson = person
        self.selectedItem = .matched
    }
}

