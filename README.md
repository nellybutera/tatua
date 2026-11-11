# Tatua: Campus Incident Reporting App

*Tatua* is Swahili for "solve". The app lets ALU students report campus problems such as broken facilities, water shortages, power cuts, sanitation and safety issues, and follow each report until it is fixed. Authorised staff review the reports and move them through a clear status workflow.

Built with **Flutter**, **Firebase Authentication**, **Cloud Firestore**, **Riverpod** and **Cloudinary**. Runs on Android (emulator or device) and iOS.

> **Image storage note:** the brief asks for Firebase Storage. Storage now needs the paid Blaze plan, so the facilitator approved Cloudinary as the image store for this project. Photos go to Cloudinary through an unsigned upload preset, and only the HTTPS link is saved in Firestore.

## Features

| Area | What it does |
|---|---|
| Authentication | Sign up with an `@alustudent.com` email, email verification, log in, password reset, logout |
| Roles | Students and staff (`@alueducation.com` with `role: staff`), enforced by Firestore security rules |
| Report an issue | Category, title, description, location, urgency, optional photo (camera or gallery, compressed), optional anonymous reporting |
| Browse | Home summary, My Reports with status filter, Explore with search, category, status and location filters, and sorting |
| Track | Incident details with a status timeline (Submitted → In Review → In Progress → Resolved / Rejected) and staff notes |
| Manage (owner) | Edit or delete your own report while it is still "Submitted" |
| Staff | Dashboard (new today, open, in progress, resolved), "needs attention" list ordered by urgency, category breakdown, status updates with a note |
| Privacy | Anonymous reports store **no** reporter fields on the public document. Only the owner and staff can read the private owner record |

## Architecture

```
lib/
├── core/
│   ├── constants/   app_constants.dart (enums: category, urgency, status), cloudinary_config.dart
│   └── theme/       app_theme.dart (design tokens + Material 3 theme)
├── models/          app_user.dart, incident.dart (Firestore <-> Dart)
├── services/        auth_service.dart, incident_service.dart, cloudinary_service.dart
├── providers/       providers.dart (Riverpod), filter_provider.dart (Notifier)
├── widgets/         common.dart (status badge, cards, empty/error states)
├── screens/
│   ├── auth/        welcome, sign up, log in, verify email, forgot password
│   ├── student/     shell, home, report form, success, my reports
│   ├── staff/       shell, dashboard, update status sheet
│   ├── shared/      explore, incident details, profile, restricted
│   └── auth_gate.dart  decides which part of the app to show
└── main.dart
```

The code has three layers:
- **UI widgets** only read Riverpod providers and call services.
- **Services** hold all Firebase and HTTP code.
- **Models** convert Firestore documents.

Live data comes from Firestore `snapshots()` streams exposed as `StreamProvider`s, so every screen updates in real time.

## Firestore data model

```
users/{uid}                               name, email, role ('student' | 'staff'), createdAt
users/{uid}/myReports/{incidentId}        createdAt (private list of the user's own reports)
incidents/{incidentId}                    title, description, category, location, urgency, status,
                                          photoUrl, isAnonymous, [reporterId, reporterName], lastNote,
                                          createdAt, updatedAt
incidents/{incidentId}/private/owner      reporterId, reporterName (owner + staff only)
incidents/{incidentId}/statusHistory/{id} status, note, changedBy, changedAt
```

Multi-document writes use **batched writes**: creating a report, deleting a report, and a status change plus its history entry. The rules validate them together with `getAfter()`.

## Security rules (summary)

See [`firestore.rules`](firestore.rules).

- Only signed-in, **verified** ALU students and staff can read reports.
- A student can create a report only as themselves, and it must start as `submitted`. Field types, lengths and allowed values are all validated.
- The owner can edit or delete a report only while it is `submitted`, and can never change its status.
- Only staff can change `status`, `lastNote` and `updatedAt`, and add timeline entries.
- Nobody can make themselves staff. The role can only be set in the Firebase console.
- Photo links must point to this project's Cloudinary account.

Rule tests: `node tool/rules_test.js firestore.rules` runs 23 allow/deny cases through the Firebase Rules test API. You must be logged in with the Firebase CLI first.

## Getting started

Prerequisites: Flutter 3.4x, an Android emulator or device, and the Firebase CLI and FlutterFire CLI if you use your own Firebase project.

```bash
git clone https://github.com/nellybutera/tatua.git
cd tatua
flutter pub get
flutter run            # with an emulator running
```

To use your own backend:
1. Create a Firebase project and enable Email/Password sign-in and Firestore.
2. Run `flutterfire configure`.
3. Deploy the rules with `firebase deploy --only firestore:rules`.
4. Create an unsigned Cloudinary upload preset, and put your cloud name and preset in `lib/core/constants/cloudinary_config.dart`.

**Creating a staff account:**
1. Firebase console → Authentication → Add user, with an `@alueducation.com` email.
2. In Firestore, create `users/<uid>` with `name`, `email`, `role: "staff"` and `createdAt`.

## Testing

```bash
flutter analyze                        # static analysis (0 issues)
flutter test                           # unit tests: search, filter and sort logic
node tool/rules_test.js firestore.rules   # 23 security-rule cases
```

The main workflows were also tested by hand on an Android emulator against the live Firebase project:
- sign up and verification
- reporting with a photo, and anonymously
- edit and delete
- search
- staff status updates through to Resolved

## Author

Nelly Teta Butera, African Leadership University, Mobile Application Development (Formative 2).
