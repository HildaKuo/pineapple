# Pineapple

A simple strength-training logger for iPhone, built with SwiftUI and SwiftData.

## Features (v0.1)

- Log workouts: add exercises, enter weight and reps, check off sets
- Rest timer that starts when a set is checked off
- Exercise library with about 90 built-in exercises, plus custom ones
- Routines you can start with one tap
- Workout history, with "Save as Routine"
- Progress chart per exercise (est. 1RM, heaviest weight, volume) and personal records
- Previous weight and reps shown while logging
- kg or lb

All data stays on the phone. There is no account or server.

## Run it

Requires Xcode 16 or newer and iOS 17 or newer.

1. Open `Pineapple.xcodeproj` in Xcode.
2. Select the **Pineapple** target, then **Signing & Capabilities**, and choose your team.
3. If Xcode says the bundle ID is taken, change `com.hildakuo.pineapple` to something unique.
4. Pick an iPhone simulator or your phone and press Run.

## Project layout

```
Pineapple/
  App/       App entry point and tab bar
  Models/    SwiftData models, units, built-in exercise list
  Views/     Screens
```
