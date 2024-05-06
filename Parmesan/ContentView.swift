import SwiftUI
import Panel

enum PanelItem: String, Identifiable {
    case matched
    var id: String { self.rawValue }
}

struct ContentView: View {
    @State private var people: [Person] = [ // 使用 Person 結構
        Person(name: "John", age: 30, city: "New York"),
        Person(name: "Emily", age: 25, city: "Los Angeles"),
        Person(name: "Max", age: 35, city: "Chicago"),
        Person(name: "Luca", age: 29, city: "Miami"),
        Person(name: "Sean", age: 27, city: "San Francisco"),
        Person(name: "寶寶", age: 2, city: "台北")
    ].reversed()
    
    @StateObject private var panelManager = PanelManager()
    @State private var selectedItem: PanelItem? = nil
    
    var body: some View {
        VStack {
            HStack {
                Text("Welcome!")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Image("capybara")
                    .resizable()
                    .frame(maxWidth: 50, maxHeight: 50)
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(50)
            }
            .padding(.horizontal)
            .frame(maxHeight: 100)
            
            Spacer()
            Button("Print People Array") {
                print("Current People Array: \(people)")
            }
            ZStack {
                Text("You reached the daily limit!")
                    .font(.headline)
                    .bold()
                    
                ForEach(Array(people.indices.reversed()), id: \.self) { index in
                    CardView(person: people[index], onRemove: {
                        withAnimation {
                            print("Before Removing: \(people)")
                            people.remove(at: index)
                            print("After Removing: \(people)")
                        }
                    }, panelManager: panelManager)
                    .offset(x: 0, y: CGFloat(index * -10))
                }

            }
            HStack {
                Button(action: {
                    dislikeTopCard()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    likeTopCard()
                }) {
                    Image(systemName: "heart.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.green)
                }
            }
            .padding(.top, 36)
            
            Spacer()
            
        }
        .padding()
        .panel(item: $panelManager.selectedItem,
               onCancel: { print("cancelled") },
               content: { item in
                    if let currentPerson = people.first {
                        MatchedView(person: currentPerson.name, item: self.$panelManager.selectedItem)
                    }
                })
        .environmentObject(panelManager)
    }
    
    func likeTopCard() {
        guard !people.isEmpty else { return }
        let person = people.removeFirst()
        print("(Clicked) Liked \(person.name), New People Array: \(people)")
        panelManager.showMatchedPanel(for: person.name) // Trigger popup
        panelManager.isPanelPresented = true
    }
    
    func dislikeTopCard() {
        guard !people.isEmpty else { return }
        let person = people.removeFirst()
        print("(Clicked) Disliked \(person.name), New People Array: \(people)")
    }
}


struct MatchedView: View {
    let person: String
    @Binding var item: PanelItem?
    var body: some View {
        VStack(spacing: 24) {
            Text("Matched with \(person)!")
                .font(.title)
                .foregroundColor(.black)
                .bold()
            
            Image(systemName: "heart.fill")
                .font(.system(size: 100))
                .foregroundColor(.red)
            
            Text("You and \(person) have liked each other.")
                .multilineTextAlignment(.center)
            
            Button(action: {
                self.item = nil
            }, label: {
                Text("Close")
                    .frame(maxWidth: .infinity)
            })
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
