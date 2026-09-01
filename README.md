# TimeTracker

A time-tracking app for iOS and Android. Start a live timer for a category
(Work, Study, Entertainment, or your own), stop it when you're done, and see
day / week / month breakdowns with charts.

**The app works fully offline** — all data is stored on the phone itself, no
account or server needed. A reset button in the app wipes everything and
starts fresh. The `backend/` folder and `docker-compose.yml` are kept in the
repo as an optional future upgrade if online sync across devices is ever
wanted, but the app does not need them.

## What's in here

```
timetracker/
├── app/                 The Flutter app (iOS + Android)
├── backend/             The API server (Node.js + Express)
├── docker-compose.yml   Runs the API + PostgreSQL database in production
└── README.md            You are here
```

## Running the backend (production)

The backend and database run together with Docker Compose.

1. Set two secrets. From the project folder:

   ```bash
   export DB_PASSWORD="a-strong-password"
   export JWT_SECRET="a-long-random-string"
   ```

2. Start everything:

   ```bash
   docker compose up -d --build
   ```

3. Confirm it's alive — this should return `{"ok":true}`:

   ```bash
   curl http://localhost:3000/health
   ```

The database tables are created automatically on first start. Your data is
stored in a Docker volume (`db_data`) so it survives restarts.

## Running the app

The `app/` folder contains the complete app source. To build and run it you
need the Flutter toolchain (https://flutter.dev). A developer — or Claude Code
with Flutter installed — can do this:

```bash
cd app
flutter create .          # generates the Android/iOS project scaffolding
flutter pub get           # installs dependencies
flutter run               # runs on a connected device or emulator
```

Point the app at your server by setting the API address when you run it:

```bash
# Android emulator talking to a backend on your own computer:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# A real device or production server:
flutter run --dart-define=API_BASE_URL=https://your-domain.com
```

## API overview

| Method | Path                 | Purpose                          |
|--------|----------------------|----------------------------------|
| POST   | /auth/register       | Create an account                |
| POST   | /auth/login          | Log in                           |
| GET    | /categories          | List your categories             |
| POST   | /categories          | Add a category                   |
| DELETE | /categories/:id      | Remove a category                |
| POST   | /entries/start       | Start a timer for a category     |
| POST   | /entries/:id/stop    | Stop a running timer             |
| GET    | /entries/running     | The currently running timer      |
| GET    | /entries             | Your recent history              |
| GET    | /stats?period=week   | Totals per category (day/week/month) |

## A note on publishing

Getting the app onto the App Store and Google Play is a separate step that
needs an Apple Developer account, a Google Play account, and app signing.
That part can't be automated from here, but the code is ready for it.
