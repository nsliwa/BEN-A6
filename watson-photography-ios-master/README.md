Getting Started
======================

This is a sample iOS application for the IBM Watson Mobile Developer Challenge.

![image](https://raw.githubusercontent.com/IBMMobileCoC/watson-photography-ios/master/readme-assets/splash.png?token=532119__eyJzY29wZSI6IlJhd0Jsb2I6SUJNTW9iaWxlQ29DL3dhdHNvbi1waG90b2dyYXBoeS1pb3MvbWFzdGVyL3JlYWRtZS1hc3NldHMvc3BsYXNoLnBuZyIsImV4cGlyZXMiOjEzOTkzODIxNTd9--aac615438b5e8e42b0f0578337bbeef74ef7f7e9) &nbsp;
![image](https://raw.githubusercontent.com/IBMMobileCoC/watson-photography-ios/master/readme-assets/overview.gif?token=532119__eyJzY29wZSI6IlJhd0Jsb2I6SUJNTW9iaWxlQ29DL3dhdHNvbi1waG90b2dyYXBoeS1pb3MvbWFzdGVyL3JlYWRtZS1hc3NldHMvb3ZlcnZpZXcuZ2lmIiwiZXhwaXJlcyI6MTM5OTM4MjEwMX0%3D--e10b0780b932dfd321df06a7aa6a42493c524b25)

## Getting the Code

1. Clone this Github repository.

2. Open the Xcode project: `cd watson-photography-ios && open WatsonPhotography.xcodeproj`

3. Find the `config.plist` file in the `Supporting Files` group and add a username, a password and the watson instance id number to contact the Watson API. If no username or password is provided, the application will get data from `fake.json` which is also in the the `Supporting Files` group. 

4. Run the application!

## FAQ

**Q:** What if I want to run this on older versions of iOS?

**A:** Change the deployment target: Project > Build Setting > Deployment tab > iOS Deployment Target.

-----

## Overview

* **WPAppDelegate.m** - This is the entry point of our application (after `main.m`). Here you can add code before the UI is loaded, for example in  `application:didFinishLaunchingWithOptions:` we make a call to style the navigation bar. You can also add code to run when the application returns from the background and other lifecycle events.

* **Main.storyboard** - This is where the flow of the application is defined. If you want to add new views (UI), this is where you would do it.

* **Images.xcassets** - All images used in the project are here. Including the splash screen and application icon image.

* **Supporting Files/fake.json** - Fake data in case we don't have access to the Watson API, or lack network connectivity, or we want to test with a slightly faster version (network communication is slow). The data is based on the 'what is aperture?' question.

* **Supporting Files/config.plist** - This is what `WPWatson.m` will read to find the username, password and instance id to access the Watson API. If there's no username or password, `fake.json` will be used as the data source instead.

* **Controllers/WPMainViewController.m** - This is the first view controller that is loaded when the application starts. It has a text field (`self.questionTextField`) for getting question input from the user. It also has an 'Ask Watson' button that will trigger a call to `WPWatson.m` to get data and populate a table (our next view) with the answers.

* **Controllers/WPResultsTableViewController.m** - This is the second view users would see, they get here by clicking on the 'Ask Watson' button. It's a table view with all the answers from the data source selected by `WPWatson.m`. Learn more about UITableViewControllers [here](http://blog.teamtreehouse.com/introduction-to-the-ios-uitableviewcontroller).

* **Controllers/WPResultsDetailsViewController.m** - This is the third view controller that is loaded, it's loaded when a cell containing an answer is clicked in the previous view. It shows Watson's confidence in the answer, the full answer and a random piece of evidence to back up the answer.

* **Classes/WPWatson.m** - Singleton that sends questions to the Watson API if a username, password and instance id are found in `Supporting Files/config.plist`, otherwise it returns data from `Supporting Files/fake.json`. Questions are cached, if a user asks the same question again it will get it from the cache instead of contacting the server again. The cache is cleared after the forth question. Apple's [NSURLConnection](https://developer.apple.com/library/ios/documentation/cocoa/reference/foundation/classes/NSURLConnection_Class/Reference/Reference.html) API is used to make an asynchronous request to Watson's API, it's the same library that popular libraries like [AFNetworking](https://github.com/AFNetworking/AFNetworking) use internally.

* **Classes/WPWatsonQuestionResponse.m** - Simple object that will hold answers and evidence relevant to a specific question.

* **Classes/WPUtils.m** - Class full of class methods for various miscellaneous operations. Here's code to: style the navigation bar, build a busy indicator, get a random number with a range, etc.

* **Classes/WPConstants.m** - Constants used in the application. The header is available everywhere because it's part of the pre-compiled headers (`Supporting Files/WatsonPhotography-Prefix.pch`)

* **WatsonPhotographyTests/WatsonPhotographyTests.m** - Some very basic tests for some parts of the code described above.

* **Frameworks** - Notice the project has **no** dependancies beyond the frameworks that Apple ships for iOS development.



