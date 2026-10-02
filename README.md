# Money Out — office expense app (Flutter + Supabase)

Records money going out only: amount, date, category, paid by, paid to, particulars and bill number. Monthly total, day-wise list and a category breakdown. Data is stored in your Supabase project, so the same account works on any phone.

## 1. Set up the database

Supabase dashboard → SQL Editor → New query → paste `supabase/schema.sql` → Run.

Then Authentication → Providers → Email, and keep email sign-in on. For a private office app, turn off "Allow new users to sign up" after you create your own account, so nobody else can register.

## 2. Settings

`src/.env` already holds your project values:

```
SUPABASE_URL=https://ktngqyiebtbrqrdbhmcu.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

The publishable key is meant to be shipped inside apps. Row Level Security is what protects the data, which the schema file sets up.

The Postgres connection string is **not** used by the app and must never be put in it, because anyone can open an APK and read what is inside. Keep it on your laptop or server only. A sample is in `.env.server.example`.

## 3. Build the APK on your computer

Needs Flutter and the Android SDK installed.

```bash
bash setup.sh            # creates ./app and copies the sources in
cd app
flutter build apk --release
```

The file lands at `app/build/app/outputs/flutter-apk/app-release.apk`. Copy it to your phone and install it, allowing "Install unknown apps" for your file manager.

It is signed with Flutter's debug key, which is fine for installing on your own phone. For Play Store upload, create a keystore and add `android/key.properties`.

To test on a connected phone first: `flutter run --release`.

## 4. Or build the APK without a computer setup

Push this folder to a GitHub repo. The workflow in `.github/workflows/build-apk.yml` runs on every push to `main`, or from the Actions tab using "Run workflow". When it finishes, open that run and download the `money-out-apk` artifact, which contains the APK.

To keep the keys out of the repo, add `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` as repository secrets and delete `src/.env`.

## Project layout

```
src/lib/main.dart                  app start, theme, auth gate
src/lib/env.dart                   reads .env or --dart-define
src/lib/models/expense.dart        expense model, categories, formatting
src/lib/services/expense_service.dart   all Supabase queries
src/lib/pages/login_page.dart      email sign in and sign up
src/lib/pages/expenses_page.dart   month view and list
src/lib/pages/expense_form.dart    add, edit and delete sheet
supabase/schema.sql                table, indexes and RLS policies
setup.sh                           generates the android project and copies sources
```

Designed by AnnexCode
