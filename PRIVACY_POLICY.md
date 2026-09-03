# Privacy Policy

Thank you for using MyNihongo!!!!!. We take your privacy seriously. This privacy policy explains how the app handles your data.

Last reviewed against the shipped behaviour on 2026-09-03, for version 0.2.1.

## Data Collection

MyNihongo!!!!! does not collect, upload, or share any personal information. The app contains no analytics, advertising trackers, crash reporting, or data collection of any kind. It has no accounts and no server of its own.

## Data Storage

All data the app creates — your learning progress and your settings — is stored locally on your device, in the app's own folder or in a folder you choose in Settings. The kana, vocabulary, and grammar content is bundled inside the app and is never sent anywhere.

## Network Access

MyNihongo!!!!! accesses the internet only in the following situations, each of which you have to turn on yourself:

- **WebDAV sync**: If you enable WebDAV cloud sync, the app sends your learning progress to a WebDAV server that you configure yourself. The app does not send data to any other server.
- **Network speech recognition**, only if you turn on the switch described under Speech Recognition below. It is off by default.
- **Downloading an on-device AI model**, only if you turn on On-device AI assistance and then tap Download. The download is performed by the Android AICore system service, not by the app.

No other network communication takes place. The app requests the `INTERNET` permission for this and nothing else.

Two details worth stating plainly:

- **Your WebDAV credentials are stored in plain text** in the app's folder, as they are in the other apps in this series. Anyone with access to that folder — including a device backup that includes it — can read them. Use an app password rather than your main account password where your server offers one.
- Your device is kept awake while a sync is running, so a sync is not interrupted mid-upload. It is released as soon as the sync finishes or fails.

## Data Backup, Export and Import

The app provides a local backup feature and a ZIP export and import. Backup files are stored on your device; an export goes to the folder you pick. Both contain your learning progress. Where these files go afterwards is entirely under your control — the app never uploads them.

Picking a folder or a file uses the system picker, which grants the app access to that one location and requires no storage permission.

## Text to Speech

The app can read Japanese aloud — kana, words and example sentences. This uses the text-to-speech engine that is already installed on your device (Android's, Apple's, or the Windows speech platform): the text is handed to that engine and the audio is produced on the device. Nothing is sent anywhere, nothing is recorded, and no audio file is written. Your chosen speaking speed and voice are stored on the device only.

If no Japanese voice is installed, nothing is spoken and the app says so; installing one is done in your system settings, not in the app.

## Speech Recognition

Pronunciation practice listens to you and compares what the speech recognizer understood with the item's reading. Recognition is done by the speech service already on your device — Android's, Apple's, or the Windows speech platform.

By default the app asks for offline recognition only. On a device with no offline Japanese data installed the attempt fails and the app tells you so, rather than quietly sending your voice anywhere. Settings has a switch, off by default, that allows a fallback to the system's network recognition; only when you turn it on can what you say be sent to the system speech service to be transcribed. On most Android devices that service is Google's.

No audio is recorded to a file, and nothing you say is stored. The microphone is used only while you are recording an attempt, and the permission is requested the first time you tap record, with a reason.

## On-device AI Assistance

On an Android phone that has Google's AICore system service, the sentence lab can explain one of its own findings in more words, explain a sentence, and suggest a rewrite. This is **off by default**; nothing happens until you turn on On-device AI assistance in Settings.

When it is on, the sentence you typed — together with the app's own analysis of it and the app's own grammar notes — is handed to a model that runs **on your phone**, through AICore. Nothing is sent to a server, nothing is recorded, and nothing generated is saved: it is gone when you change the sentence or leave the page.

One part of this does use the network, and only when you ask for it: the first time you tap **Download** for a feature, the AICore system service fetches that model from Google. The app does not perform the download and does not send anything with it. Once the model is on your phone, the feature works with no network at all.

Generated text is always labelled as generated. It can be wrong, it never changes the app's own analysis, and it is never written into the app's dictionary or grammar content.

## Changes to This Policy

This privacy policy may be updated from time to time. Updated versions will be published within the app or on the relevant distribution channels. Text to speech, speech recognition and on-device AI assistance are described above. Any future feature that could send anything off the device will be described here before it ships, and will be off unless you turn it on.
