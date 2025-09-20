import SwiftUI
import MapKit
import CoreLocation

struct MapLocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLocation: CLLocation?
    @Binding var mapRegion: MKCoordinateRegion
    
    @State private var tempLocation: CLLocation?
    @State private var showingPin = false
    @State private var currentMapRegion: MKCoordinateRegion
    
    init(selectedLocation: Binding<CLLocation?>, mapRegion: Binding<MKCoordinateRegion>) {
        self._selectedLocation = selectedLocation
        self._mapRegion = mapRegion
        self._currentMapRegion = State(initialValue: mapRegion.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map
                Map(coordinateRegion: $currentMapRegion, annotationItems: pinItems) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        VStack(spacing: 0) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 20, height: 20)
                                )
                                .shadow(radius: 3)
                                .offset(y: -10) // Adjust pin position to be more precise
                            
                            Text("Selected")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(4)
                                .background(.white)
                                .cornerRadius(4)
                                .shadow(radius: 2)
                                .offset(y: -5)
                        }
                    }
                }
                .ignoresSafeArea()
                
                // Center crosshair to show where pin will be placed
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            let coordinate = currentMapRegion.center
                            print("📍 Pin dropped at center: \(coordinate.latitude), \(coordinate.longitude)")
                            tempLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                        }) {
                            VStack(spacing: 2) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.red)
                                    .frame(width: 30, height: 30)
                                    .background(
                                        Circle()
                                            .fill(.white)
                                            .shadow(radius: 3)
                                    )
                                
                                Text("Drop Pin")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                    .padding(4)
                                    .background(.white)
                                    .cornerRadius(4)
                                    .shadow(radius: 2)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                    .padding(.bottom, 150)
                }
                
                
                // Instructions
                VStack {
                    HStack {
                        Text("Swipe to move map, tap + to drop pin at center")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.black.opacity(0.7))
                            )
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Confirm Location") {
                        selectedLocation = tempLocation
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(tempLocation != nil ? .blue : .gray)
                    .disabled(tempLocation == nil)
                }
            }
        }
    }
    
    private var pinItems: [MapPinItem] {
        if let location = tempLocation {
            return [MapPinItem(coordinate: location.coordinate)]
        }
        return []
    }
    
    
}

struct MapPinItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    MapLocationPickerView(
        selectedLocation: .constant(nil),
        mapRegion: .constant(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    )
}
