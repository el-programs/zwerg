# Zwerg

Web-App für zwei Gesellschafter, die gemeinsam eine neue Firma entwickeln – von der Ideensammlung bis zur Gründung.

- App: <https://el-programs.github.io/zwerg/>
- Einrichtung, Tests, Updates, Backups: [ANLEITUNG.md](ANLEITUNG.md)

## Technik

- Oberfläche: Vue 3 + Vite, installierbar als PWA, offline-fähig (Service Worker, IndexedDB-Warteschlange)
- Daten: Supabase (Postgres mit Row Level Security, Realtime), Region Frankfurt
- Anmeldung: Passkeys (WebAuthn) und Geräte-Kopplung per QR-Code über die Edge Function `supabase/functions/auth`
- Veröffentlichung: GitHub Actions → GitHub Pages bzw. Supabase

## Entwicklung

```
npm install
npm run dev      # lokale Vorschau
npm run build    # Produktionsstand in dist/
npm run icons    # App-Icons neu erzeugen
```

Datenbank-Änderungen gehören als neue Datei nach `supabase/migrations/`.
