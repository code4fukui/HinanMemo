# HinanMemo
HinanMemo for iOS9 in Swift2.2

## Features
- Uses CoreData and CoreLocation to store and retrieve emergency facility data near the user's location
- Displays a list of nearby facilities and allows opening their locations in a mapping app
- Allows clearing the stored data

## Requirements
- iOS 9 or later
- Swift 2.2

## Usage
1. Clone the repository and open the Xcode project.
2. Build and run the app on an iOS device or simulator.
3. Click the "Get" button to retrieve and display nearby emergency facilities.
4. Tap on a facility in the list to open its location in a mapping app.
5. Click the "Clear" button to delete the stored data.

## Data / API
The app uses the SPARQL endpoint at `http://sparql.odp.jig.jp/data/sparql` to query for emergency facilities near the user's location.

## License
This project is licensed under the [CC BY Code for Fukui](https://creativecommons.org/licenses/by/4.0/deed.ja) license.