# Inbox app

This is a simple Android app for taking inbox notes. Main goals are speed and
simplicity. All taken notes are saved as local files, which then can be
synced/sent however you want.

<img src="https://github.com/UnkwUsr/inbox-app/assets/49063932/19527869-022d-4b5b-b6b3-a075e3cfe0c7" width="180" height="320">
<img src="https://github.com/UnkwUsr/inbox-app/assets/49063932/8a54afd3-4610-4c66-bd19-9db5e11600ae" width="180" height="320">

Idea of this app is that inbox should be taken quickly, while later, for
example on computer, with comfortable setup (and real full-fledged text
editor), we can process them all, sort, categorize and so on.

## Installation

You can download latest .apk build from
[releases](https://github.com/UnkwUsr/inbox-app/releases) page (choose by your
processor architecture, or try each one if don't know yours).

Minimal supported Android version: 5.0

## Features

* take text notes
* record voice notes
* shortcut button in quick settings, allowing you to quickly take notes when
  you reading books or surfing web, without distracting main activity
* taken notes saved in plain text files (or per file, for voice records)
  allowing you to use sync tool of your choice
  * P.S. path to saved notes: `~/txts/phone_inbox/`
  * P.P.S. as voice records are just audio files, you might need some solution
    for speech recognition, for quicker analysing incoming inbox
* keyboard automatically pops up on app open

## FAQ

### Q: I want to edit previous saved note!

Don't! Just add another one, describing what you wanted to edit in previous
one.

Why so? Because it's much more hussle to edit something on phone.

### Q: I want multiline note!

Don't! Taking inbox notes should be as much faster and easier as possible, but
when you wanting to write multiline note, you're already trying to structure
note. Just leave it for future when you'll be on computer or in any better text
editor.

## Background

Previously I was using ticktick for inbox notes, but from time to time it was
taking few seconds just for start (when app was unloaded from cache by system)
and it was killing me. Also I wanted feature for voice recording, but
ticktick's voice record uses google speech recognition service, which works
only with internet connection.
