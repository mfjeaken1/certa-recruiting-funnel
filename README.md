# Certa Recruiting-Funnel

Automatisierter Recruiting-Funnel für Objektbesichtiger:innen. Eingehende Bewerbungen werden gegen eine Bedarfskarte geprüft, automatisch bewertet, in die passende Pipeline einsortiert und die jeweilige Folgekommunikation versendet — Grenzfälle werden der Mitarbeiterin in einem Kanban-Dashboard und per Telegram-Push zur Entscheidung vorgelegt.

**Case Study für die Bewerbung als Head of Operations bei Certa GmbH.**

---

## Inhaltsverzeichnis

1. [Was das System macht](#was-das-system-macht)
2. [Architektur](#architektur)
3. [Setup](#setup)
4. [Die drei Eingangskanäle](#die-drei-eingangskanäle)
5. [Die Bewertungslogik](#die-bewertungslogik)
6. [Mitarbeiter-Prozesse pro Status](#mitarbeiter-prozesse-pro-status)
7. [Testen](#testen)
8. [Repo-Struktur](#repo-struktur)
9. [Weitere Dokumente](#weitere-dokumente)

---

## Was das System macht

Eine Bewerbung kommt über einen der drei Eingangskanäle rein (E-Mail, Online-Formular als Simulation eurer Karriere-Seite oder direkter API-Call). Das System:

1. **Erkennt Spam** über eine deterministische Punkte-Heuristik
2. **Erkennt Relevanz**, sodass bei einem geteilten Postfach nur die gewünschten Bewerbungen prozessiert werden
3. **Prüft die abgedeckten PLZ-Bereiche** gegen die aktuelle Bedarfskarte
4. **Berechnet einen Eignungsscore** (0–100) aus PLZ-Match, Verfügbarkeit, Vollständigkeit und ISO-Zertifizierung
5. **Routet** die Bewerbung in eine von fünf Pipelines:
   - **Einladung** (Score ≥ 70 und PLZ-Match gut) → automatische Einladungsmail mit Kalender-Buchungslink
   - **Absage** (alle PLZ-Bereiche überbesetzt) → automatische, freundliche Absage mit Pool-Hinweis
   - **Rückfrage** (Pflichtfelder fehlen) → automatische Rückfrage-Mail mit Liste der fehlenden Felder
   - **Manuelle Prüfung** (Grenzfall) → Push-Nachricht an die Mitarbeiterin per Telegram mit KI-Begründung, plus Anzeige im Kanban
   - **Spam-Aussortierung** → Datensatz wird markiert, keine Bearbeitung
6. **Verarbeitet Rückfrage-Antworten** automatisch (Antwort-Mail mit `[REF:ID]` im Betreff → bestehender Datensatz wird aktualisiert, neu bewertet und somit keine Dublette erzeugt)

Die Mitarbeiterin sieht im Kanban auf einen Blick, welche Bewerber im Pool sind und wo Aufmerksamkeit gebraucht wird. Grenzfälle erscheinen zusätzlich als Telegram-Nachricht mit zwei Inline-Buttons (✅ Einladen / ❌ Absagen).

---

## Architektur

```
┌─────────────────────────────────────────────────────────────┐
│   Hostinger KVM 2 VPS (Docker Compose)                      │
│                                                             │
│   ┌──────────────┐   ┌─────────────┐   ┌─────────────┐      │
│   │     n8n      │◄──┤ PostgreSQL  ├──►│   NocoDB    │      │
│   │ Orchestrator │   │  (Source    │   │ (Kanban-UI) │      │
│   │              │   │  of Truth)  │   │             │      │
│   └───┬──────────┘   └─────────────┘   └──────┬──────┘      │
│       │                                       │             │
│       ▼ (Telegram, Gmail, Tally, Claude API)  │             │
│       ▼ (Webhook bei Statusänderung)          │             │
│       └───────────────────────────────────────┘             │
└─────────────────────────────────────────────────────────────┘
```

**Drei n8n-Workflows:**

| Workflow | Zweck |
|---|---|
| **Workflow 1 - Bewerbungseingang** | Hauptworkflow: Eingang, Bewertung, Routing, Mail-Versand |
| **Sub-Workflow 1 - Rueckfrage** | Verarbeitet Antworten auf Rückfrage-Mails (REF:ID erkennen, Datensatz updaten, Bewertung neu anstoßen) |
| **Sub-Workflow 1 - Manuelle-Entscheidung** | Wird über NocoDB-Webhook ODER Telegram-Button-Klick getriggert, versendet Einladungs- oder Absage-Mail bei manuell bearbeiteten Datensätzen |

**Externe Anbindungen:**

- Gmail (eingehende Bewerbungen, ausgehende Mails)
- Claude API (`claude-sonnet-4-6`) — ausschließlich für E-Mail-Parsing
- Telegram Bot (aktive Benachrichtigung und Inline-Button-Entscheidung)
- Tally (standardisiertes Bewerbungsformular) 
- Motion (Kalender-Buchungslink in Einladungsmail, hier als Mock-Verbindung mit Alexander Rausch eingerichtet)

Für die ausführliche Begründung der Architektur und der Tech-Stack-Wahl siehe [DECISIONS.md](./DECISIONS.md).

---

## Setup

### Voraussetzungen

- Linux-Server (getestet auf Hostinger KVM 2, Ubuntu 24, 8 GB RAM, 2 vCPU)
- Docker und Docker Compose
- Eine Gmail-Adresse mit App-Passwort
- Ein Telegram-Bot (BotFather) mit Token und Chat-ID
- Ein Claude-API-Key (anthropic.com/api) mit $5 Token

### Schritt 1: Repository klonen und Container starten

```bash
git clone <repo-url>
cd certa-recruiting-funnel

cp .env.example .env
# .env editieren: Postgres-Passwort, Domain/IP, etc.

docker compose up -d
```

Damit laufen drei Container:
- `n8n` auf Port 5678
- `postgres` (intern, Port 5432)
- `nocodb` auf Port 8080

### Schritt 2: Datenbank-Schema und Bedarfskarte importieren

```bash
docker compose exec postgres psql -U certa -d nocodb -f /sql/schema.sql
docker compose exec postgres psql -U certa -d nocodb -f /sql/bedarfskarte_import.sql
```

(Beide SQL-Dateien liegen unter `db/`.)

### Schritt 3: n8n-Workflows importieren

1. n8n unter `http://<server-ip>:5678` öffnen, Admin-Account anlegen
2. In den Settings die Credentials anlegen:
   - **Postgres** (`certa` / Passwort aus `.env`)
   - **Gmail OAuth2**
   - **Claude API** (Bearer Token)
   - **Telegram Bot** (Bot-Token von BotFather)
3. Über "Import from File" die drei Workflow-JSONs aus `n8n/workflows/` importieren
4. Die Credentials in jedem Workflow den importierten Nodes zuweisen
5. Alle drei Workflows aktivieren

### Schritt 4: NocoDB verbinden und Kanban einrichten

1. NocoDB unter `http://<server-ip>:8080` öffnen, Admin-Account anlegen
2. Neue Data Source → PostgreSQL, mit denselben Credentials
3. Schema `pga7yket86jj0rl` einbinden (Name variiert je nach NocoDB-Initialisierung)
4. Auf der Tabelle `bewerbungen` eine Kanban-View anlegen, gruppiert nach `status_`
5. Karten-Felder konfigurieren: `name`, `plz_wohnort`, `ki_begruendung`, `manuelle_entscheidung`
6. NocoDB-Webhook anlegen: Event "After Update" auf `bewerbungen`, Bedingung `manuelle_entscheidung is not blank`, Ziel-URL `https://<n8n-url>/webhook/manuelle-entscheidung`

### Schritt 5: Testen

Siehe Abschnitt [Testen](#testen).

---

## Die drei Eingangskanäle

Alle drei Kanäle münden im selben Normalisierungs-Code und durchlaufen ab dort denselben Bewertungspfad.

### Kanal 1: Gmail

E-Mails an das konfigurierte Postfach werden vom Gmail-Trigger erkannt. Ein Betreff-Filter (sucht "bewerbung"/"objektbesichtiger"/"ob stelle") schützt vor irrelevanten Mails, da kein dediziertes Postfach im Einsatz ist. Die Claude API parst den E-Mail-Text in mein strukturiertes Schema — explizit mit Robustheits-Hinweis im Prompt, damit Tippfehler, Synonyme und ungewöhnliche Formulierungen sinngemäß interpretiert werden.

E-Mails mit `[REF:ID]` im Betreff werden als Rückfrage-Antwort erkannt und über den Sub-Workflow Rueckfrage verarbeitet (keine neue Bewerbung).

### Kanal 2: Tally-Formular

Ein Online-Formular bei Tally.so sendet die Felder per Webhook an n8n. Der Normalisierungs-Code erkennt das Tally-Format (Array `data.fields` mit Label/Value-Paaren), löst MULTIPLE_CHOICE-Felder über das `options`-Mapping auf und liefert ein einheitliches Bewerbungs-Objekt. Dadurch werden typische Inkonsistenzen und Fehlerquellen wie bei den simulierten Testdatensätzen vermieden und die Verarbeitung realer Formulareinsendungen ist deutlich robuster.

### Kanal 3: HTTP-Webhook (Direkt-JSON)

Für Tests und Subworkflow-Aufrufe: ein direkter POST mit einem JSON-Body im Format der `bewerbungen.json` aus dem Case-Material. Das Demo-Script `import_bewerbungen.sh` nutzt diesen Kanal.

---

## Die Bewertungslogik

Pro Bewerbung läuft folgende Sequenz:

1. **Spam-Check** (Relevanz, Punkte-Heuristik, Schwellenwert → `spam_aussortiert`)
2. **Vollständigkeitsprüfung** (Telefon, PLZ, Verfügbarkeit, Berufserfahrung, ...)
3. **PLZ-Match** gegen Bedarfskarte (SQL-Query, liefert besten Bedarfsstatus, alle gleichwertigen besten PLZ-Bereiche und Liste unbekannter Bereiche)
4. **Routing-Switch** mit 4 Ausgängen:
   - PLZ bekannt und schlecht (Score ≤ 20) → direkte Absage
   - PLZ unbekannt (nicht in Bedarfskarte) → manuelle Prüfung
   - Pflichtfelder fehlen → Rückfrage
   - Alles OK → weiter zum Scoring
5. **Scoring** (Gewichtungen: PLZ 50 % / Verfügbarkeit 25 % / Vollständigkeit 15 % / ISO 10 %)
6. **Finale Routing-Entscheidung:**
   - Score ≥ 70 und PLZ-Match gut → Einladung versenden mit Kalender-Buchungsfunktion
   - Score 40–69 → manuelle Prüfung mit Tendenz "einladen wenn Beruf relevant"
   - Score < 40 → manuelle Prüfung mit Tendenz "absagen"
   - Verfügbarkeit < 10 h/Woche → manuelle Prüfung mit Frage "Ausnahme sinnvoll?"

Für die Hintergründe der Gewichtungs- und Schwellen-Entscheidungen siehe [DECISIONS.md](./DECISIONS.md).

---

## Mitarbeiter-Prozesse pro Status

Die Mitarbeiterin sieht im Kanban-Dashboard sechs Spalten. Hier was sie pro Status tun kann oder soll:

| Status | Was die Mitarbeiterin sieht/tut |
|---|---|
| **einladung_versendet** | Bewerber hat eine Einladung mit Kalender-Buchungslink erhalten. Nichts weiter zu tun, bis Termin stattfindet. Nach erfolgtem Gespräch und CRM-Übernahme: Karte manuell in `abgeschlossen` ziehen. |
| **absage_versendet** | Bewerber hat eine freundliche Absage erhalten und ist im Pool (`im_pool=true`). Nichts weiter zu tun. |
| **rueckfrage_offen** | System wartet auf Antwort des Bewerbers. Sobald sie kommt (mit `[REF:ID]` im Betreff), wird der Datensatz automatisch aktualisiert und erneut bewertet. Nichts zu tun. |
| **manuell_pruefen** | **Hier wird die Mitarbeiterin aktiv.** Sie sieht in der Karte die KI-Begründung und entscheidet auf einem von drei Wegen: |
| | (a) Im Kanban die Bewerber-Karte öffnen → Dropdown `manuelle_entscheidung` auf "einladen" oder "absagen" stellen |
| | (b) In Telegram die Push-Nachricht öffnen und auf ✅ Einladen oder ❌ Absagen tippen |
| | (c) Mit einem Kommentar an der Karte interne Notizen hinterlegen (z.B. "Telefonat mit dem Bewerber am 12.06., schickt PLZ nach") |
| **spam_aussortiert** | Datensatz für Nachvollziehbarkeit gespeichert. Nichts zu tun. Standardmäßig eingeklappt. |
| **abgeschlossen** | Endzustand, Bewerber wurde im CRM weitergeführt. Status wird **manuell** gesetzt durch Drag&Drop nach dem Telefongespräch. |

**Die Mitarbeiterin muss das System nie verlassen, um eine Entscheidung umzusetzen.** Mail-Versand und Status-Update laufen automatisch, sobald sie sich für einladen oder absagen entschieden hat.

---

## Testen

### 1. Alle 15 Demo-Bewerbungen auf einmal importieren

```bash
./tests/import_bewerbungen.sh
```

Das Script sendet jede der 15 Bewerbungen aus `bewerbungen.json` einzeln per Webhook (simuliert echten Eingang, kein Bulk-Insert). Erwartete Ergebnisse nach Durchlauf:

| Anzahl | Status |
|---|---|
| 9 | `einladung_versendet` |
| 1 | `absage_versendet` (BW-0155) |
| 1 | `rueckfrage_offen` (Tobias R.) |
| 3 | `manuell_pruefen` (Petra, Conrad, Yvonne — siehe DECISIONS.md für Begründung) |
| 1 | `spam_aussortiert` (BW-0150) |

### 2. Routing-Pfade einzeln testen

```bash
./tests/test_alle_cases.sh
```

8 konstruierte Testfälle, die jeden Switch-Ausgang und jeden Scoring-Bereich exemplarisch durchspielen — von "klare Einladung" über "PLZ unbekannt" bis "Spam".

### 3. Rückfrage-Loop testen

Nach Eingang einer unvollständigen Bewerbung erhält der Bewerber eine Rückfrage-Mail mit `[REF:ID]` im Betreff. Eine Antwort auf diese Mail (mit den fehlenden Angaben im Text) triggert den Rückfrage-Loop, aktualisiert den Datensatz und stößt die Bewertung erneut an.

### 4. Manuelle Entscheidung testen

In NocoDB bei einem `manuell_pruefen`-Datensatz das Feld `manuelle_entscheidung` auf "einladen" setzen → der Webhook triggert Sub-Workflow 1, eine Mail wird versendet, der Status wechselt. Alternativ in Telegram auf einen Inline-Button tippen.

---

## Repo-Struktur

```
.
├── docker-compose.yml              # n8n, Postgres, NocoDB
├── .env.example                    # Umgebungsvariablen-Vorlage
├── db/
│   ├── schema.sql                  # CREATE TABLE bewerbungen, bedarfskarte
│   └── bedarfskarte_import.sql     # Import der Bedarfskarte aus CSV
├── n8n/
│   └── workflows/
│       ├── Workflow_1_Bewerbungseingang.json
│       ├── Sub-Workflow_1_Rueckfrage.json
│       └── Sub-Workflow_1_Manuelle-Entscheidung.json
├── tests/
│   ├── import_bewerbungen.sh       # Sendet alle 15 Demo-Bewerbungen
│   └── test_alle_cases.sh          # 8 konstruierte Routing-Tests
├── case-material/                  # Originaldateien von Certa
│   ├── aufgabe.md
│   ├── README.md
│   ├── bewerbungen.json
│   ├── bedarfskarte.csv
│   └── kommunikationsvorlagen.md
├── README.md                       # diese Datei
├── DECISIONS.md                    # Architektur-Entscheidungen
└── requirements_status.csv        # Anforderungs-Tracking mit Zitatzuordnung
```

---

## Weitere Dokumente

- **[DECISIONS.md](./DECISIONS.md)** — Architektur-Entscheidungen, KI-Einsatz-Strategie, Umgang mit Mehrdeutigkeit, bewusste Nicht-Umsetzungen, Phase-2-Roadmap
- **[requirements_status.csv](./requirements_status.csv)** — vollständige Anforderungsliste mit Zuordnung zur ursprünglichen `aufgabe.md` als schlanker Projektplan und zur eigenen Konzeption, Status pro Punkt

---

**Demo-Video (Loom):** siehe Link in der Abgabe-Nachricht.

**Kontakt:** Marcus Flock — Bewerbung als Head of Operations bei Certa GmbH.
