# Tatua

Tatua is a campus incident reporting app for ALU. If something breaks on campus, like a leaking tap, a power cut or a broken lock, students can report it in a few taps and follow it until it gets fixed. Staff see the reports, deal with the urgent ones first, and update the status so the student always knows what's happening.

I built it with **Flutter**, **Firebase Authentication**, **Cloud Firestore**, **Riverpod** and **Cloudinary**. It runs on Android and the same code builds for iOS.

**Demo video:** https://youtu.be/ozp9sAL4onA

> **Note on photos:** the assignment asks for Firebase Storage, but it now needs the paid Blaze plan. The facilitator allowed me to use Cloudinary instead. Photos go to Cloudinary and only the link is saved in Firestore.

---

## What the app does

**Students can:**
- sign up with an `@alustudent.com` email (and they have to verify it first)
- report a problem with a category, title, description, location, urgency and a photo
- report anonymously if they don't want their name on it
- see their own reports and everyone else's, then search and filter them
- follow a report's timeline, with notes from staff
- edit or delete their report while it's still "Submitted"

**Staff can:**
- see a dashboard with new, open, in-progress and resolved reports
- see a "needs attention" list, with urgent and older reports at the top
- move a report from Submitted to In Review, In Progress, then Resolved or Rejected
- add a note with each update (a note is required when closing a report)

---

## How the code is organised

```
lib/
├── core/        theme and fixed values (categories, urgency, statuses)
├── models/      turn Firestore documents into Dart objects
├── services/    the only code that talks to Firebase and Cloudinary
├── providers/   Riverpod providers that share data with the screens
├── widgets/     reusable pieces (status badge, report card, empty state)
├── screens/     auth, student, staff and shared screens + auth_gate.dart
└── main.dart
```

The idea is simple: **screens never talk to Firebase directly.** They read data from providers, and the providers get it from the services. That keeps the screens clean and means a change (like moving from Firebase Storage to Cloudinary) only touches one file.

`auth_gate.dart` decides where each user goes: the welcome screen, the verify-email screen, the student app, the staff app or an "access restricted" screen.

---

## How the data is stored (Firestore)

| Collection | What's in it |
|---|---|
| `users/{uid}` | name, email and role (`student` or `staff`) |
| `users/{uid}/myReports/{id}` | a private list of my own reports |
| `incidents/{id}` | the report: title, description, category, location, urgency, status, photo link, timestamps |
| `incidents/{id}/private/owner` | who actually sent the report (only the owner and staff can read this) |
| `incidents/{id}/statusHistory/{id}` | every status change, with the note, who changed it and when |

Anonymous reports have **no name or user ID** on them at all. The real owner is only in the private `owner` document.

---

## Security

The app hides buttons, but the real protection is in [`firestore.rules`](firestore.rules), which run on Google's servers. In short:

- only verified ALU students and staff can see reports
- students can only create reports as themselves, and every report starts as "Submitted"
- students can only edit or delete their own report, and only before staff start working on it
- only staff can change a status, and they can't change what the student wrote
- nobody can make themselves staff (the role is set by hand in the Firebase console)

---

## Running it yourself

You'll need Flutter (3.4x or newer) and an Android emulator or phone.

```bash
git clone https://github.com/nellybutera/tatua.git
cd tatua
flutter pub get
flutter run
```

That connects to my Firebase project. If you want to use your own instead:

1. Create a Firebase project and turn on **Email/Password** sign-in and **Firestore**.
2. Run `flutterfire configure` to connect the app to it.
3. Deploy the rules: `firebase deploy --only firestore:rules`
4. Create an **unsigned upload preset** on Cloudinary and put your cloud name and preset in `lib/core/constants/cloudinary_config.dart`.

**Making a staff account:**
1. In the Firebase console, go to Authentication and add a user with an `@alueducation.com` email.
2. In Firestore, create `users/<their uid>` with `name`, `email`, `role: "staff"` and `createdAt`.

---

## Testing

```bash
flutter analyze                          # no issues
flutter test                             # 8 unit tests for search, filter and sort
node tool/rules_test.js firestore.rules  # 23 security rule tests (log in to the Firebase CLI first)
```

I also tested every flow by hand on an Android emulator with the real Firebase project: signing up and verifying, reporting with a photo, anonymous reports, editing and deleting, searching and filtering, and staff updating a report all the way to Resolved.

---

## Author

Teta Butera Nelly, African Leadership University, Mobile Application Development (Formative Assignment 2)
