import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            MealsView()
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
            SupplementsView()
                .tabItem { Label("Supps", systemImage: "pills.fill")
                }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill")
                }
            AppsView()
                           .tabItem { Label("Apps", systemImage: "square.grid.2x2") }
        }
    }
}
