# Zwerg – Anleitung für Einrichtung, Updates und Backups

Zwerg läuft komplett kostenlos:

| Teil | Wo | Wofür |
|---|---|---|
| App (Oberfläche) | GitHub Pages: <https://el-programs.github.io/zwerg/> | Wird bei jeder Änderung automatisch neu veröffentlicht |
| Daten, Anmeldung | Supabase, Rechenzentrum Frankfurt | Ideen, Kommentare, Passkeys – geschützt durch Zugriffsregeln |
| Backups | Privates Repository `el-programs/zwerg-backup` | Jede Nacht verschlüsselt, 30 Tage aufbewahrt |

Der Programmcode ist öffentlich, eure Daten nicht: Ohne Anmeldung mit Passkey bzw. gekoppeltem Gerät
liefert die Datenbank keine einzige Zeile.

---

## Teil A – Einmalige Einrichtung (ca. 20 Minuten)

### A1. Zugangsschlüssel bei Supabase erzeugen

1. <https://supabase.com/dashboard/account/tokens> öffnen.
2. **Generate new token**, Name `github-zwerg`, Ablauf „Never“ (oder 1 Jahr), **Generate**.
3. Den Token (beginnt mit `sbp_`) kopieren. **Nicht in den Chat schreiben.**

### A2. Secrets im Repository `zwerg` hinterlegen

1. <https://github.com/el-programs/zwerg/settings/secrets/actions> öffnen.
2. **New repository secret**:
   - Name `SUPABASE_ACCESS_TOKEN`, Wert: der Token aus A1.
3. Noch einmal **New repository secret**:
   - Name `SUPABASE_DB_PASSWORD`, Wert: das Datenbank-Passwort, das ihr beim Anlegen des Supabase-Projekts gespeichert habt.

GitHub verschlüsselt Secrets; niemand kann sie wieder auslesen – auch nicht bei einem öffentlichen Repository.

### A3. GitHub Pages einschalten

1. <https://github.com/el-programs/zwerg/settings/pages> öffnen.
2. Unter **Build and deployment → Source** die Option **GitHub Actions** wählen.

### A4. Öffentliche Registrierung bei Supabase abschalten

1. Supabase-Projekt `zwerg` → **Authentication → Sign In / Providers**.
2. **Allow new users to sign up** ausschalten und speichern.
   (Zwerg legt eure zwei Konten selbst an. „Email“ als Anbieter bitte **eingeschaltet** lassen.)

### A5. Veröffentlichen

Sobald die Änderungen im Zweig `main` liegen, laufen unter
<https://github.com/el-programs/zwerg/actions> zwei Abläufe:

- **Supabase aktualisieren** – legt Tabellen, Zugriffsregeln und die Anmelde-Funktion an.
- **App veröffentlichen** – stellt die App unter <https://el-programs.github.io/zwerg/> bereit.

Beide müssen einen grünen Haken bekommen. Ein rotes Kreuz? Screenshot an Claude schicken.

### A6. Einrichtungs-Links erzeugen

1. Supabase → **SQL Editor** → **New query**.
2. Eingeben und **Run** klicken:

   ```sql
   select * from create_setup_links();
   ```

3. Es erscheinen zwei Links, einer für Florian, einer für Igor (7 Tage gültig).
   Jeder schickt sich seinen Link selbst, z. B. per Mail oder Notiz. Den Befehl könnt ihr jederzeit erneut ausführen.

### A7. iPhone einrichten (jeder für sich)

1. Den eigenen Link auf dem iPhone **in Safari** öffnen.
2. **Passkey einrichten** → mit Face ID bestätigen. Ihr seid angemeldet.
3. In Safari unten auf **Teilen** → **Zum Home-Bildschirm** → **Hinzufügen**.
4. Zwerg über das neue Symbol auf dem Home-Bildschirm öffnen → **Mit Passkey anmelden** → Face ID.
   (Die Home-Bildschirm-App hat einen eigenen Speicher, deshalb einmal neu anmelden.)

### A8. Laptop koppeln (jeder für sich)

1. Am Laptop <https://el-programs.github.io/zwerg/> in Edge oder Chrome öffnen.
2. **Mit dem iPhone verbinden** – ein QR-Code erscheint.
3. Auf dem iPhone in Zwerg: **Mehr → Gerät hinzufügen (QR-Code scannen)** → Code scannen → **Mit Face ID bestätigen**.
4. Der Laptop meldet sich innerhalb weniger Sekunden an und bleibt angemeldet.
5. Tipp: In Edge/Chrome über das Menü **Apps → Zwerg installieren** bekommt ihr ein eigenes Fenster.

---

## Teil B – Etappe 1 testen

| Was | So testet ihr es |
|---|---|
| Schnellerfassung | Auf der Startseite oder über das **Plus** eine Idee notieren. Erste Zeile = Titel. |
| Diktat | iPhone: Mikrofon auf der Tastatur. Windows: im Textfeld **Windows-Taste + H**. |
| Live-Abgleich | Beide gleichzeitig in Zwerg: Eine neue Idee des einen erscheint beim anderen sofort. |
| „Neu“-Markierung | Neue Ideen und Kommentare des anderen stehen auf der Startseite unter „Neu von …“ und tragen ein **neu**-Schild, bis man die Idee öffnet. |
| Kommentare | Idee öffnen → unten kommentieren. Eigene Kommentare lassen sich löschen. |
| Ideen bearbeiten | Titel, Beschreibung, Suchfeld, Schlagworte und Links direkt in der Idee ändern – wird beim Verlassen des Feldes gespeichert. |
| Offline | iPhone in den Flugmodus, Idee erfassen („Offline gespeichert“), Flugmodus aus → die Idee wird automatisch abgeglichen. |
| Suchfelder | **Mehr → Suchfelder**: umbenennen, sortieren, archivieren, neu anlegen. |
| Darstellung | **Mehr → Darstellung**: System/Hell/Dunkel und eure persönliche Akzentfarbe. |
| Geräte | **Mehr → Geräte**: alle angemeldeten Geräte, einzeln sperrbar. |
| Neues iPhone | **Mehr → Geräte → Link für …** erzeugt einen 24-Stunden-Einladungslink. |

---

## Teil C – Updates

Neue Etappen und Korrekturen liefert Claude über GitHub. Sobald sie im Zweig `main` sind,
veröffentlichen die Abläufe unter **Actions** alles automatisch – ihr müsst nichts installieren.
Auf den Geräten lädt Zwerg die neue Version beim nächsten Öffnen von selbst.

---

## Teil D – Tägliche Backups

Das Backup läuft im privaten Repository `zwerg-backup`, jede Nacht gegen 3 Uhr.

1. Eine lange **Backup-Passphrase** ausdenken (z. B. fünf zufällige Wörter) und im Passwort-Manager speichern.
   **Ohne sie lassen sich Backups nicht öffnen.**
2. <https://github.com/el-programs/zwerg-backup/settings/secrets/actions> öffnen und drei Secrets anlegen:
   - `SUPABASE_ACCESS_TOKEN` – derselbe Token wie in A1
   - `SUPABASE_DB_PASSWORD` – das Datenbank-Passwort
   - `BACKUP_PASSPHRASE` – die Passphrase aus Schritt 1
3. Einmal von Hand testen: **Actions → Tägliches Backup → Run workflow**. Danach liegt im Ordner `backups` eine Datei
   `zwerg-JJJJ-MM-TT.tar.gz.gpg`.

Wiederherstellen: siehe `WIEDERHERSTELLEN.md` im Repository `zwerg-backup`.

---

## Gut zu wissen

- **Pausieren:** Kostenlose Supabase-Projekte pausieren nach etwa einer Woche ohne Zugriff. Der Ablauf
  „Supabase wachhalten“ verhindert das. GitHub schaltet solche Zeitpläne nach 60 Tagen ohne Änderungen im
  Repository ab und schickt vorher eine Mail – dann unter **Actions** einfach wieder aktivieren.
  Ist das Projekt doch pausiert: im Supabase-Dashboard auf **Restore project** klicken.
- **Gerät verloren:** Am anderen Gerät **Mehr → Geräte → Sperren**. Für ein neues iPhone den Partner um einen
  Einladungslink bitten (oder selbst unter **Mehr → Geräte → Link für …** erzeugen).
- **Kosten:** 0 €. Die KI-Funktionen (Etappe 3) bleiben aus, bis ihr einen Schlüssel hinterlegt.
