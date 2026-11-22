package com.example.feniksflutter

import com.ryanheise.audioservice.AudioServiceActivity

// Shares its Flutter engine with the media service, which keeps the radio
// playing while the app is in the background.
class MainActivity : AudioServiceActivity()
