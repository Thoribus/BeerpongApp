# BeerpongApp — Task Tracker

- Bitchcup kommt nicht
- Achievements Progress Bar funktioniert nicht
- Achievements yellow lines
- Account Screen performance issues
- add friends username not found (wenn username nicht vorhanden)
- lobby screen kommt nicht ins spectate wenn das game startet
- add friends performance issues (firendlist allgemein)
- friendlist wird nicht geupdated, wenn mich jemand als freund hinzufügt
- spectate bug (muss spezifiziert werden)
- push notifications gehen nicht
- lobby screen selected rules anzeigen (zeigt nur an, wenn rules bereits vorher ausgewählt wurden, kein update)
- lobby spieler werden nicht aus lobby screen geworfen, wenn sie aus der lobby vom host gekickt werden
- lobby screen eingeladene Spieler können Lobby nicht verlassen
- game start exception: (default)/documents/invitations/OQCoyKEJKBJwdD8im7gU, cause=null}.
E/flutter (24208): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: [cloud_firestore/not-found] Some requested document was not found.
E/flutter (24208): #0      FirebaseFirestoreHostApi.documentReferenceUpdate (package:cloud_firestore_platform_interface/src/pigeon/messages.pigeon.dart:1059:7)
E/flutter (24208): <asynchronous suspension>
E/flutter (24208): #1      MethodChannelDocumentReference.update (package:cloud_firestore_platform_interface/src/method_channel/method_channel_document_reference.dart:55:7)     
E/flutter (24208): <asynchronous suspension>
E/flutter (24208): #2      InvitationRepository.updateInvitationGameId (package:beerpongapp/repositories/invitation_repository.dart:55:5)
E/flutter (24208): <asynchronous suspension>
E/flutter (24208): #3      _GameModeDetailsScreenState._onStartGame (package:beerpongapp/screens/home/game_mode_details_screen.dart:294:7)
E/flutter (24208): <asynchronous suspension>
E/flutter (24208): #4      _GameModeDetailsScreenState._onStart (package:beerpongapp/screens/home/game_mode_details_screen.dart:283:7)
E/flutter (24208): <asynchronous suspension>
