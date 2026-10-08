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
3. Auf dem iPhone in Zwerg: **Einstellungen → Gerät hinzufügen (QR-Code scannen)** → Code scannen → **Mit Face ID bestätigen**.
4. Der Laptop meldet sich innerhalb weniger Sekunden an und bleibt angemeldet.
5. Tipp: In Edge/Chrome über das Menü **Apps → Zwerg installieren** bekommt ihr ein eigenes Fenster.

---

## Teil B – Testen

### Etappe 1 testen

| Was | So testet ihr es |
|---|---|
| Schnellerfassung | Auf der Startseite oder über das **Plus** eine Notiz festhalten. Ideen legt ihr unter **Gedanken & Ideen → +** an (erste Zeile = Titel). |
| Diktat | iPhone: Mikrofon auf der Tastatur. Windows: im Textfeld **Windows-Taste + H**. |
| Live-Abgleich | Beide gleichzeitig in Zwerg: Eine neue Idee des einen erscheint beim anderen sofort. |
| „Neu“-Markierung | Neue Ideen und Kommentare des anderen stehen auf der Startseite unter „Neu von …“ und tragen ein **neu**-Schild, bis man die Idee öffnet. |
| Kommentare | Idee öffnen → unten kommentieren. Eigene Kommentare lassen sich löschen. |
| Ideen bearbeiten | Titel, Beschreibung, Suchfeld, Schlagworte und Links direkt in der Idee ändern – wird beim Verlassen des Feldes gespeichert. |
| Offline | iPhone in den Flugmodus, Idee erfassen („Offline gespeichert“), Flugmodus aus → die Idee wird automatisch abgeglichen. |
| Suchfelder | **Einstellungen → Suchfelder**: umbenennen, sortieren, archivieren, neu anlegen. |
| Darstellung | **Einstellungen → Darstellung**: System/Hell/Dunkel und eure persönliche Akzentfarbe. |
| Geräte | **Einstellungen → Geräte**: alle angemeldeten Geräte, einzeln sperrbar. |
| Neues iPhone | **Einstellungen → Geräte → Link für …** erzeugt einen 24-Stunden-Einladungslink. |

### Etappe 2 testen

| Was | So testet ihr es |
|---|---|
| Gewichtung | **Gedanken & Ideen → Ranking → Gewichtung**. Jeder legt für sich fest, wie wichtig jeder Faktor ist (0–5) und gibt ab. Erst danach sieht man die Werte des anderen; große Unterschiede sind markiert. Dann gemeinsam festlegen (gestrichelt = Vorschlag aus dem Mittelwert). |
| Bewertung | Idee öffnen → **Bewertung**. Jeder bewertet alle Faktoren 1–5 (5 = gut für uns) und markiert ggf. KO-Kriterien. Die Werte des anderen bleiben verborgen, bis man selbst abgegeben hat – das prüft die Datenbank. |
| Vergleich & Endbewertung | Nach beiden Abgaben: Abweichungen ab 2 Punkten sind hervorgehoben. Gemeinsame Punkte wählen (oder Mittelwerte übernehmen), KO gemeinsam festlegen, **Endbewertung festlegen**. |
| Ranking | **Gedanken & Ideen → Ranking**: sortiert nach Punkten (0–100). „vorläufig“ = Mittel der Einzelbewertungen. KO-Ideen stehen gesondert. Mit dem Stern 2–3 Favoriten markieren. |
| Vergleich | **Gedanken & Ideen → Vergleich**: bis zu drei Ideen als Netzdiagramm und Tabelle. |
| Parkplatz | Idee öffnen → **Auf den Parkplatz** mit Begründung. Unter **Gedanken & Ideen → Liste → Parkplatz** jederzeit reaktivieren. |
| Faktoren & KO-Kriterien | **Einstellungen → Bewertungsfaktoren / KO-Kriterien**: umbenennen, erklären, sortieren, archivieren, ergänzen. |

### Etappe 3 testen (nach Teil E)

| Was | So testet ihr es |
|---|---|
| Stufe je Person | **Einstellungen → KI-Unterstützung**: Aus / Nur auf Anfrage / Aktiv mit Hinweisen. Bei „Aus“ verschwinden alle KI-Knöpfe für diese Person. |
| Ideen vorschlagen | **Gedanken & Ideen → KI-Vorschläge**: Suchfeld wählen, optional Hinweise, „Vorschläge erzeugen“. Einzelne Vorschläge „Als Idee übernehmen“. |
| Kritische Einschätzung | Idee öffnen → **KI-Sparring → Einschätzung**. Getrennt nach Fakten, Schätzungen, Annahmen, mit Bewertungsvorschlag je Faktor (klar als KI-Vorschlag markiert, fließt nicht in eure Wertung ein). |
| Marktrecherche | **KI-Sparring → Recherche**, optional mit eigener Frage. Ergebnis mit Quellenliste. |
| Chat | **KI-Sparring → Chat**: Sparring zur Idee, für beide sichtbar. |
| Bewertung | Nach beiden Abgaben zeigt der Vergleich auch den KI-Vorschlag je Faktor – erst dann, damit eure Bewertung unbeeinflusst bleibt. |
| Kostenbremse | **Einstellungen → KI-Unterstützung**: Verbrauch des Monats und Limit. Ist es erreicht, sperrt Zwerg die KI bis Monatsende. |

### Etappe 4 testen

| Was | So testet ihr es |
|---|---|
| Phasen | **Plan → Phasen**: Ziel, Ergebnis, Hinweise und Abschlusskriterien je Phase. Kriterien abhaken, über **Bearbeiten** Texte und Kriterien ändern. **In Phase X wechseln** fragt nach einer Begründung und protokolliert den Wechsel. Nichts wird erzwungen. |
| Phase je Idee | In der Idee oben **Phase der Idee** wählen (wird ebenfalls protokolliert). |
| Aufgaben | **Plan → Aufgaben** oder in der Idee unter **Aufgaben**: mit Zuständigkeit, Fälligkeit, Status, Idee und Phase. Überfällige stehen oben in Rot; auf der Startseite steht „Meine Aufgaben“. |
| Business Case | Idee → **Business Case**: Investition, Fixkosten, variable Kosten, Preis und Absatz je Szenario (vorsichtig/realistisch/optimistisch) → Umsatz, Marge, Ergebnis, Break-even, Amortisation. |
| Pilot-Feedback | Idee → **Pilot-Feedback**: Gespräche und Tests mit Problemstärke, Kaufinteresse, Zahlungsbereitschaft, Zitat und Erkenntnissen. |
| Entscheidungen | **Plan → Entscheidungen**: wer hat wann was entschieden und warum. Phasenwechsel und Parken landen automatisch im Protokoll. Ändern und löschen kann nur, wer den Eintrag angelegt hat. |

### Notizen testen

| Was | So testet ihr es |
|---|---|
| Notiz festhalten | **Plus** antippen, Gedanken eintippen oder diktieren, **Speichern**. Notizen sind für euch beide sichtbar. |
| Notizen ansehen | Unten **Notizen**: Angeheftete oben, sonst die neuesten zuerst. Neue Notizen des anderen tragen ein **neu**-Schild und stehen auf der Startseite unter „Neu von …“. |
| Bearbeiten | Notiz antippen → Text ändern, **Anheften**, **Zur Idee machen** (legt eine Idee an, die Notiz bleibt und verweist darauf) oder löschen. |
| Neue Idee direkt | **Gedanken & Ideen → +** oben rechts,. |
| Einstellungen | Am Handy über euren Kürzel-Kreis oben rechts auf der Startseite, am Laptop in der Seitenleiste. |

### Besprechungen testen

| Was | So testet ihr es |
|---|---|
| Anlegen | **Notizen → Meetings → Neue Besprechung**: Titel, Datum, Uhrzeit, Ort, wer dabei war, Gäste. |
| Notizen im Meeting | Das große Feld **Notizen** unter den Kopfdaten nimmt alles Freie auf, was ihr während des Meetings festhalten wollt. |
| Tagesordnung | Punkte hinzufügen, je Punkt **Notiz** und **Ergebnis** eintragen, mit den Pfeilen umsortieren. Punkte ohne Ergebnis haben links einen gelben Rand, erledigte einen farbigen. |
| Aufgaben und Entscheidungen | Am Punkt **+ Aufgabe** (erscheint auch unter Plan → Aufgaben) oder **+ Entscheidung** (übernimmt Ergebnis und Notiz ins Entscheidungsprotokoll; geht erst, wenn ein Ergebnis drinsteht). |
| Offene Punkte übernehmen | Neue Besprechung anlegen → oben erscheint **Offene Punkte übernehmen**, wenn die vorige Besprechung Punkte ohne Ergebnis hat. Übernommene Punkte zeigen, woher sie stammen. |
| Live | Beide in derselben Besprechung: Änderungen des anderen erscheinen, sobald er ein Feld verlässt. |

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

## Teil E – KI einrichten (optional)

Die KI-Funktionen sind eingebaut, bleiben aber aus, bis ein API-Schlüssel hinterlegt ist. Der Schlüssel liegt nur auf dem
Server (Supabase), nie in der App oder im Browser.

1. **Konto bei Anthropic:** <https://console.anthropic.com> öffnen und registrieren (Firmenkonto).
2. **Guthaben:** Unter **Billing** Prepaid-Guthaben kaufen, z. B. 10 $. Es wird nur verbraucht, was ihr nutzt.
3. **Zweite Sicherung:** Unter **Limits** ein Monatslimit setzen (z. B. 15 $) – zusätzlich zur Kostenbremse in Zwerg.
4. **Schlüssel:** Unter **API Keys → Create Key**, Name `zwerg`. Den Schlüssel (beginnt mit `sk-ant-`) kopieren.
   **Nicht in den Chat schreiben.**
5. **Im Supabase-Projekt hinterlegen:** <https://supabase.com/dashboard/project/znxplygfxvghmtyqbwvb/functions/secrets>
   öffnen → **Add new secret** → Name `ANTHROPIC_API_KEY`, Wert: der Schlüssel → **Save**.
6. In Zwerg unter **Einstellungen → KI-Unterstützung** Modell und Monatslimit prüfen. Fertig.

Datenschutz: Nur beim Benutzen einer KI-Funktion wird die betroffene Idee (Titel, Beschreibung, Kommentare) an Anthropic
(USA) übermittelt; Anthropic verwendet API-Daten nicht zum Training. Ein Auftragsverarbeitungsvertrag (DPA) ist in den
Anthropic-Bedingungen enthalten.

---

## Gut zu wissen

- **Pausieren:** Kostenlose Supabase-Projekte pausieren nach etwa einer Woche ohne Zugriff. Der Ablauf
  „Supabase wachhalten“ verhindert das. GitHub schaltet solche Zeitpläne nach 60 Tagen ohne Änderungen im
  Repository ab und schickt vorher eine Mail – dann unter **Actions** einfach wieder aktivieren.
  Ist das Projekt doch pausiert: im Supabase-Dashboard auf **Restore project** klicken.
- **Gerät verloren:** Am anderen Gerät **Einstellungen → Geräte → Sperren**. Für ein neues iPhone den Partner um einen
  Einladungslink bitten (oder selbst unter **Einstellungen → Geräte → Link für …** erzeugen).
- **Kosten:** 0 €. Die KI-Funktionen (Etappe 3) bleiben aus, bis ihr einen Schlüssel hinterlegt.
