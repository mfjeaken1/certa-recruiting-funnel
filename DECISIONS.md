# DECISIONS

Dieses Dokument fasst die zentralen Entscheidungen zusammen, die ich bei der Umsetzung des Recruiting-Funnels getroffen habe. Jede Entscheidung ist mit Begründung dokumentiert — nicht nur was gebaut wurde, sondern warum.

Die Entscheidungen sind grob in der Reihenfolge sortiert, in der sie im System wirksam werden — von der Architektur ganz oben bis zur konkreten UX am Ende.

---

## 1. Architektur und Tech-Stack

### 1.1 n8n statt eigenem Code

Die Aufgabe verbietet "ein zusammengeklicktes No-Code-Setup", erlaubt aber ausdrücklich jede Technologie, die "am schnellsten zu einem funktionierenden Ergebnis" führt. n8n ist die richtige Wahl, weil:

- Der Prozess besteht zu großen Teilen aus Integration (Gmail, Postgres, Telegram, NocoDB, Claude API) — genau das Feld, in dem n8n stark ist.
- Die Bewertungslogik selbst läuft in Code-Nodes (JavaScript). Das ist kein No-Code, sondern Code an der richtigen Stelle — der Glue-Code dazwischen muss nicht selbst gebaut werden.
- Workflows sind visuell nachvollziehbar. Für eine spätere Übergabe an eine andere Person ist das ein echter Vorteil gegenüber einem Python-Skript, das nur ich verstehe.
- Workflow-Exports liegen als JSON im Repo — versionierbar, diffbar, reproduzierbar.

Der Unterschied zu "zusammengeklickt": Die gesamte fachliche Logik (Scoring, Routing, Spam-Erkennung, Normalisierung, Begründungstext-Generierung) ist eigener, lesbarer Code, kein Drag-and-Drop einer fertigen Vorlage.

### 1.2 Self-hosted auf Hostinger VPS statt n8n Cloud

- Volle Kontrolle über Datenbank, Logs und Webhook-URLs
- Postgres und NocoDB im selben Docker-Netzwerk, ohne Cloud-Latenz
- Kosten überschaubar (~8 €/Monat KVM 2)
- Zusätzlicher Fokus auf digitale Souvernität, Open Source und maximal kostensparend
- Realistisches Produktions-Setup, das man identisch bei Certa hosten könnte

### 1.3 PostgreSQL als Single Source of Truth, NocoDB nur als UI-Schicht

Der wichtigste Punkt dieser Entscheidung: **NocoDB schreibt nichts Eigenes in eine separate Datenbank**, sondern liest und schreibt direkt in Postgres. Das bedeutet:

- Es gibt eine Wahrheit über den Zustand einer Bewerbung — keine Synchronisationsprobleme.
- Workflows (n8n) und Frontend (NocoDB) sehen immer dasselbe.
- Wenn die UI später ausgetauscht würde, bleibt die Datenbank intakt.

### 1.4 Live-Verarbeitung statt Batch

Jede Bewerbung wird im Moment des Eingangs verarbeitet, nicht in einem nächtlichen Batch. Das passt zur Realität einer Mitarbeiterin in Teilzeit: Wenn sie morgens ins System schaut, ist alles schon verteilt und sortiert.

---

## 2. KI-Einsatz: gezielt und sparsam

Die Aufgabe fragt explizit: "Wenn Du KI einsetzt, interessiert uns, an welchen Stellen Du das tust und wo Du bewusst darauf verzichtest." Hier meine Antwort.

### 2.1 KI einsetzen für: Freitext-Parsing

Claude wird **ausschließlich** beim Eingang von E-Mail-Bewerbungen genutzt. Eine E-Mail enthält Freitext in beliebiger Struktur ("Hallo, ich heiße Anna, wohne in 48149 Münster…"). Diesen Text in unser strukturiertes Schema zu bringen, ist genau die Aufgabe, für die ein LLM gut ist: variable, menschliche Sprache in feste Felder übersetzen.

Der Prompt enthält explizit einen Robustheits-Hinweis ("interpretiere robust — Rechtschreibfehler, Synonyme, abgekürzte Wörter und ungewöhnliche Formulierungen sollen sinngemäß extrahiert werden"), damit das System nicht an menschlicher Sprachvariabilität scheitert.

### 2.2 KI bewusst NICHT einsetzen für:

- **PLZ-Match gegen die Bedarfskarte:** Eine SQL-Lookup-Query gegen eine Tabelle ist deterministisch, nachvollziehbar und schnell. Ein LLM hier wäre eine Verschlechterung in jeder Dimension.
- **Score-Berechnung:** Der Score muss erklärbar sein. Eine gewichtete Formel (Annahme: PLZ 50 % / Verfügbarkeit 25 % / Vollständigkeit 15 % / ISO 10 %) ist nachvollziehbar — eine LLM-Bewertung würde nur eine Black-Box-Zahl liefern. Wenn Alexander mich fragt "warum hat dieser Bewerber 67 Punkte?", kann ich es exakt zerlegen.
  - **Beispiel:** BW-0142 Markus Weidmann (06: dringend): PLZ-Score = 100 (Bereich 06); Verfügbarkeit = round(20/30 × 100) = 67; Vollständigkeit = 5/5 × 100 = 100; ISO = 0
  - Score = 100×0,50 + 67×0,25 + 100×0,15 + 0×0,10 = 50 + 16,75 + 15 + 0 = 81,75 ≈ 82
- **Routing-Entscheidungen:** Die Schwellen (Annahme: ≥ 70 → einladen, 40–69 → manuell, < 40 → manuell mit Tendenz absagen) sind klare Geschäftsregeln. Diese gehören in Code, nicht in einen Prompt, der sich morgen leicht anders verhält.
- **Spam-Erkennung:** Eine Punkte-Heuristik (PLZ ungültig, Großbuchstaben-Name, Werbe-Begriffe etc.) ist schnell, kostenlos und vorhersagbar. Sie fängt offensichtliche Fälle wie BW-2026-0150 zuverlässig — KI bräuchte ich nur für Grenzfälle, die in der Praxis selten sind.
- **Begründungstexte:** Werden aus den Regeln selbst gebaut ("Score 67/100 — knapp unter Einladungsschwelle. Bereich 33: Aufstockung sinnvoll. Beruf: Bankangestellte, 15h/Woche."). Das ist robust, kostet nichts pro Bewerbung und ist exakt mit den Daten konsistent, die zur Entscheidung geführt haben.

### 2.3 Abweichung von meiner Ausgangskonzeption

In der Konzeption hatte ich vorgesehen, dass Claude bei Grenzfällen zusätzlich Berufshintergrund und Motivation qualitativ bewertet (0–100). Im Bau habe ich mich dagegen entschieden, weil:

- Die deterministische Begründung der Mitarbeiterin bereits alle Entscheidungsgrundlagen klar liefert.
- Eine LLM-Bewertung des Profils würde die Mitarbeiterin in einer Black Box bestätigen, statt ihr die Daten zur eigenen Bewertung in die Hand zu geben.
- Die Mitarbeiterin sieht ohnehin das Profil — sie ist der Bewertungs-Experte, die KI nicht.

Das ist eine bewusste Korrektur, kein vergessenes Feature. Wenn Certa später feststellt, dass die Mitarbeiterin sich öfter eine Profil-Einschätzung wünscht, lässt sich der LLM-Zweig in Workflow 1 nachträglich ergänzen — die Architektur ist offen dafür.

---

## 3. Drei Eingangskanäle, ein gemeinsamer Pfad

Die Aufgabe nennt einen Eingang ("Bewerbung kommt rein"). Ich habe drei gebaut, weil das die Realität besser abbildet:

| Kanal | Anwendungsfall |
|---|---|
| **Tally-Formular** | Hauptkanal — Open Source Online-Formular auf der Karriereseite (standardisiert mit Pflichtfeldern) |
| **Gmail-Trigger** | Freitext-Bewerbungen per E-Mail an ein Postfach inkl. Rückfrage-Loop |
| **HTTP-Webhook (Direkt-JSON)** | Tests, API-Integration, Subworkflow-Aufrufe (Rückfrage-Loop) |

**Entscheidende Eigenschaft:** Alle drei Kanäle münden im selben Normalisierungs-Node (`Webhook - Daten normalisieren`), der das Format automatisch erkennt und auf ein einheitliches Schema bringt. Ab diesem Punkt ist die weitere Verarbeitung **identisch**. Kein Duplikat-Code, kein Spaghetti.

Das hat sich auch architektonisch ausgezahlt: Der Rückfrage-Loop (Sub-Workflow Rueckfrage) ruft Workflow 1 über genau diesen Webhook erneut auf — eine beantwortete Rückfrage durchläuft dieselbe Bewertung wie ein Erst-Eingang. Keine zweite Bewertungslogik, kein zweiter Mail-Versand-Code, kein doppelter DB-Eintrag.

---

## 4. Routing-Architektur: Switch statt verschachtelter Ifs

Nach dem PLZ-Match steht eine zentrale Switch-Node mit vier Ausgängen:

| Ausgang | Bedingung | Folge |
|---|---|---|
| 1 | PLZ bekannt und schlecht (Score ≤ 20) | Direkte Absage |
| 2 | PLZ unbekannt (nicht in Bedarfskarte) | Grenzfall → manuelle Prüfung |
| 3 | Pflichtfelder fehlen | Rückfrage |
| 4 | Alles OK | Weiter zu Scoring und Routing |

### 4.1 Priorisierung: PLZ vor Vollständigkeit

Eine wichtige bewusste Entscheidung: Wenn jemand in einer überfüllten Region wohnt und gleichzeitig Pflichtfelder fehlen, geht **die Absage vor**. Es ist nicht im Interesse des Bewerbers, erst Daten nachzureichen, nur um dann eine Absage zu bekommen, die sich bereits auf gelieferte Daten bezieht. Das spart sowohl der Mitarbeiterin als auch dem Bewerber Zeit — und ist genau die Art "wo automatisierst du sinnvoll"-Reflexion, die mir wichtig war.

### 4.2 Unterscheidung "PLZ schlecht" vs. "PLZ unbekannt"

Diese Trennung ist subtil, aber wichtig: Wenn die PLZ in der Bedarfskarte steht und voll besetzt ist → wir wissen, dass dort kein Bedarf ist → automatische Absage ist verantwortbar. Wenn die PLZ **nicht in der Bedarfskarte erfasst ist** → wir wissen es schlicht nicht → Mitarbeiterin sollte einmal kurz prüfen, ob wir die Bedarfskarte erweitern sollten oder ob die Region wirklich uninteressant ist. Das System gibt der Mitarbeiterin dabei einen konkreten Hinweis im Text der Telegram-Nachricht.

---

## 5. Umgang mit Mehrdeutigkeit (der wichtigste Reflexionspunkt der Aufgabe)

Die Aufgabe sagt explizit: "Was uns besonders interessiert, ist Dein Umgang mit Mehrdeutigkeit." Hier die wichtigsten Stellen, an denen ich Mehrdeutigkeit aktiv behandle:

### 5.1 Mehrere abgedeckte PLZ-Bereiche

Ein Bewerber gibt zum Beispiel `["80", "81", "82", "85"]` an. In der Bedarfskarte ist nur 85 "Aufstockung sinnvoll", 80 ist "voll besetzt", 81 und 82 sind gar nicht erfasst. Drei Fragen entstehen:

1. **Welcher Wert zählt fürs Scoring?** → Der beste. Wenn auch nur ein abgedeckter Bereich gesucht ist, ist der Bewerber interessant.
2. **Was, wenn mehrere Bereiche gleichwertig sind?** → Alle gleichwertigen werden im Begründungstext genannt (z.B. "Bereich 44, 58: Aufstockung sinnvoll").
3. **Was mit den unbekannten Bereichen?** → Werden separat als Hinweis in der Begründung erwähnt, sodass die Mitarbeiterin entscheiden kann, ob die Bedarfskarte erweitert werden sollte.

Die SQL-Query liefert all diese Informationen in einer einzigen, robusten Abfrage zurück — auch wenn null Treffer kommen (COALESCE).

### 5.2 Mehrdeutige Bewerbungen

Beispiele aus den 15 Demo-Bewerbungen:

- **Petra Sonntag (BW-0146):** PLZ 70 voll besetzt, PLZ 71 unbekannt. Automatische Absage wäre falsch (vielleicht gibt es in 71 Bedarf?). System leitet zur manuellen Prüfung mit klarem Hinweis weiter.
- **Conrad-Maximilian (BW-0148):** Top-Profil, 22 Jahre Erfahrung, aber nur 8 h/Woche. System leitet zur manuellen Prüfung mit Frage "Ausnahme sinnvoll?" — denn 8 < 10 h ist normalerweise zu wenig, aber dieses Profil ist Sonderfall-würdig.
- **Tobias R. (BW-0145):** Sehr unvollständig (kein PLZ, kein Beruf-Detail). System triggert Rückfrage — kein automatisches Verwerfen, kein automatisches Einladen. Das hat mich dazu bewegt Certa's aktuellen Bewerbungsprozess zu prüfen und ein standardisiertes Formular mit Pflichtfeldern nachzubauen.

In allen Mehrdeutigkeits-Fällen ist der Default: **lieber zur Mitarbeiterin eskalieren als falsch automatisieren**. Die KI-Begründung gibt ihr alle relevanten Daten, sodass die Entscheidung in ~2 Minuten möglich ist.

---

## 6. Mitarbeiter-UX: drei Eingangswege, ein Subworkflow

Die Aufgabe stellt klar: "ob Du an die Mitarbeiterin gedacht hast, die Dein Tool später bedient". Hier die konkrete UX:

### 6.1 Drei Eingangswege für manuelle Entscheidung

Die Mitarbeiterin kann eine Entscheidung auf **drei** Wegen treffen:

1. **NocoDB Kanban-Karte öffnen** und im `manuelle_entscheidung`-Dropdown "einladen" oder "absagen" wählen.
Sie kann sich die Ansicht so konfigurieren wie es für sie am sinnvollsten ist. Ich habe es nach meiner Empfehlung konfiguriert.
2. **Telegram-Push-Nachricht** mit Inline-Buttons (✅ Einladen / ❌ Absagen) direkt aus der Nachricht heraus
3. **NocoDB-Kommentar** für interne Notizen (nicht entscheidungsauslösend, aber für Nachvollziehbarkeit)

Alle drei Wege münden **denselben** Subworkflow (Sub-Workflow 1 - Manuelle-Entscheidung), der Switch + DB-Update + Mail-Versand enthält. Kein Duplikat-Code, alle Wege verhalten sich gleich, beide Trigger-Formate (NocoDB-Webhook und Telegram-Callback) werden vom Normalizer erkannt und einheitlich behandelt. Alle manuellen Trigger sind bewusst robust designt, sodass die Mitarbeiterin in production nicht ausversehen denselben Datensatz mehrfach bearbeiten kann.

### 6.2 Reduktion der Entscheidungs-Optionen auf zwei

Meine ursprüngliche Konzeption hatte vier Optionen im Dropdown (`einladen` / `absagen_region` / `absagen_profil` / `rueckfrage`). Im Bau habe ich auf **zwei** reduziert (`einladen` / `absagen`), weil:

- Zum Zeitpunkt der manuellen Prüfung liegen alle Infos vor — eine Rückfrage hier wäre eine Verzögerung ohne Mehrwert.
- Die zwei Absage-Varianten unterscheiden sich für den Bewerber kaum (er kommt in beiden Fällen in den Pool) — eine separate "absagen_profil"-Vorlage ist als Future Feature vorgesehen, sodass der Bewerber dann nicht mehr in den Pool kommt.

Zwei statt vier Optionen reduziert Friktion für die Mitarbeiterin. Das ist UX-Design.

### 6.3 Endstatus durch manuelles Drag&Drop

Eine Bewerbung wechselt **nicht** automatisch von `einladung_versendet` zu `abgeschlossen`. Stattdessen verschiebt die Mitarbeiterin die Karte im Kanban manuell, nachdem das Telefongespräch geführt und der Bewerber ins CRM übernommen wurde. Bewusste Nicht-Automatisierung:

- Die CRM-Anbindung ist außerhalb des Prototyp-Scopes (laut Aufgabe: "Du musst nichts an unsere Systeme anbinden").
- Der finale Akt der Mitarbeiterin ("ich habe das erledigt") ist ein bewusster Schritt, keine technische Aktion. Eine Automatisierung hier würde nur scheinbar Arbeit sparen.
- Der NocoDB-Webhook feuert hier korrekterweise nicht (er triggert nur, wenn `manuelle_entscheidung` neu gesetzt wird und der Datensatz sich im Status `manuell_pruefen` befindet, nicht bei reiner Status-Verschiebung) — keine ungewollte Folgeaktion.

### 6.4 Interne Notizen über NocoDB-Kommentare statt eigene Spalte

Meine ursprüngliche Konzeption sah ein Feld `individueller_zusatz` vor. Im Bau habe ich das durch NocoDB's eingebaute **Kommentar-Funktion** ersetzt, weil:

- Kommentare sind zeitgestempelt und mit Autor versehen (besser nachvollziehbar)
- Mehrere Einträge möglich (Verlauf statt nur "letzter Stand")
- Native UI ohne Custom-Feld

Das ist UX-Verbesserung, die sich erst im Bau ergeben hat.

---

## 7. Robustheit: Worauf das System vorbereitet ist

Die Aufgabe fragt: "ob Dein System scheitert, wenn jemand eine kaputte Bewerbung schickt". Hier die Schutzmaßnahmen:

| Risiko | Schutzmaßnahme |
|---|---|
| Leere/fehlende PLZ | Switch erkennt `abgedeckte_plz=[]` und routet zur Rückfrage |
| Null Treffer in Bedarfskarte | COALESCE in SQL liefert garantiert eine Zeile (`plz_score=-1`) |
| Mehrfache Verarbeitung desselben Datensatzes | `ON CONFLICT (id) DO UPDATE` in allen INSERTs |
| Endlosschleife durch NocoDB-Webhook | Filter prüft `status_ === 'manuell_pruefen'` — eigene Status-Updates werden ignoriert |
| Doppelklick auf Telegram-Button | Statusprüfung im Subworkflow, zweiter Klick bricht sauber ab (return []) |
| Spam/Unsinn-Bewerbungen | Heuristik mit Schwellenwert-Logik (BW-0150 als Beispiel) |
| Tippfehler in E-Mail-Bewerbung | Robustheits-Hinweis im Claude-Prompt |
| Telegram-Callback-Timeout | Statt `answerCallbackQuery` (das wegen n8n-Long-Polling unzuverlässig ist) wird eine neue Bestätigungs-Nachricht versendet |
| Mehrere gleichwertige PLZ-Treffer | Query liefert alle gleichwertigen besten Bereiche als String zurück |

Jede dieser Maßnahmen hat einen konkreten Anlass im Bau gehabt — keine prophylaktischen Best Practices, sondern Reaktionen auf real beobachtete oder kalkulierte Probleme.

---

## 8. Bewusst nicht umgesetzt

Folgende Punkte habe ich **bewusst** nicht umgesetzt — entweder weil sie außerhalb des Scopes liegen oder das Aufwand-Nutzen-Verhältnis nicht stimmt:

### 8.1 Kanban-Sortierung nach abgedeckten PLZ-Bereichen

`abgedeckte_plz` enthält pro Bewerbung mehrere Werte als kommagetrennten String. Eine eindeutige Sortierung darauf wäre nur mit einem geänderten Datenmodell möglich (Verknüpfungstabelle Bewerbung↔PLZ). Für den Prototyp nicht gerechtfertigt — die Mitarbeiterin kann stattdessen nach `plz_wohnort` filtern. Das ist genau die "wo automatisierst du bewusst nicht"-Reflexion, die ich nicht vermeiden, sondern aktiv treffen wollte.

### 8.2 LLM-basierte Profilbewertung

War in der Konzeption vorgesehen, im Bau verworfen — siehe Punkt 2.3. Erklärbarkeit der Bewertung ist mir wichtiger als zusätzliche LLM-Tiefe.

### 8.3 Separate Mail-Vorlage für `absagen_profil`

Aktuell teilen sich beide Absage-Gründe die "Region voll"-Vorlage. Für den Bewerber ist das in der Wirkung gleich (Pool-Hinweis). Als Future Feature vorgesehen.

### 8.4 Google-Drive-Upload für Lebensläufe

Konzeptionell sinnvoll, aber kein Pflichtbestandteil. Future Feature.

### 8.5 Automatische CRM-Übernahme

Außerhalb des Scopes der Aufgabe. Endstatus läuft manuell.

---

## 9. Was als Phase 2 sinnvoll wäre

Wenn Certa diese Lösung in Produktion bringen würde, wären folgende Schritte sinnvoll:

1. **Bedarfskarte aus echtem System ziehen** — heute statisch importiert, in echt sollte sie aus dem Auftragssystem aktuell gehalten werden.
2. **Pool-Reaktivierung** — wenn sich der Bedarfsstatus einer Region ändert, alle Bewerber mit `im_pool=true` aus dieser Region erneut bewerten und ggf. einladen mit einer separaten Vorlagen.
3. **CRM-Anbindung** — automatische Übernahme bei `status='eingestellt'` (statt manuellem Drag&Drop).
4. **Loom-/Audio-Schnipsel** als zusätzliche Bewerbungs-Eingangsform (Stimme parsen).
5. **Authentifizierung** und Rollenmodell für Mitarbeiterin/Admin.
6. **KI-Einsatz** — Optimierungen mit OpenClaw oder AI Agents im Generellen 
7. **Wiederkehrende Reports** ("Wie viele Bewerbungen im letzten Monat? In welchen PLZ-Bereichen wurden keine eingeladen?").
8. **Dashboard** zur visuellen Darstellung der Skalierung, Kosten- und Zeiteinsparung mit bspw:

| Bewerbungen insgesamt | Prozent |
|---|---|
| Bewerbungen insgesamt:|  22 (100%)| 
| einladung_versendet:|   9 (41%)| 
| manuell_pruefen:|       5 (23%)| 
| absage_versendet:|      3 (14%)| 
| rueckfrage_offen:|     2 (9%)| 
| spam_aussortiert:|      2 (9%)| 
| abgeschlossen: |        1 (5%)| 


| Durchschnittlicher Score (eingeladene):|84|
|---|---|
|Häufigste PLZ-Bereiche im Pool: |33, 48, 67|
|Spam-Quote: |9% (2/22)|
|Im Pool für spätere Reaktivierung: | 4|

Alle diese Punkte bauen auf der bestehenden Architektur auf, ohne sie zu brechen.

---

## 10. Einsatz von KI-Tools beim Bauen dieser Lösung

Da die Aufgabe explizit danach fragt: Ich habe diese Lösung mit Claude als Pair-Programming-Partner gebaut.

**Wo Claude geholfen hat:**

- Konkrete n8n-Node-Konfiguration (welche Parameter, welche Expressions)
- SQL-Queries (insbesondere die Subquery-Konstrukte für `unbekannte_plz` und `beste_plz_bereiche`)
- Debugging von Edge Cases (z.B. das Polling-Delay-Problem mit `answerCallbackQuery`, das nicht offensichtlich war)
- Schreiben der Sticky-Note-Texte in den Workflows
- Strukturieren dieser Dokumentation

**Wo ich selbst entschieden habe:**

- Architektur (drei Eingangskanäle, ein Subworkflow, Postgres als Single Source of Truth) inkl. Auswahl der Open Source Tools
- Konfiguration von NocoDB, Tally, Google-API und Telegram-API
- Weitere Testszenarien und Möglichkeiten zur Härtung der Applikation
- Bewertungsschema (Gewichtungen, Schwellenwerte)
- KI-Einsatz-Strategie (welche Aufgabe LLM, welche deterministisch)
- Mitarbeiter-UX (zwei Optionen statt vier, NocoDB-Kommentare statt eigene Spalte, drei Eingangswege)
- Edge-Case-Behandlung (Priorisierung PLZ vor Vollständigkeit, Endstatus-Logik)
- Welche Features ich bewusst umgesetzt habe und welche nicht

Konkret heißt das: Ich habe in jeder Iteration Vorschläge gegeben oder bekommen, sie geprüft, oft hinterfragt, manchmal abgelehnt, manchmal komplett umgekrempelt. Die Architektur stammt von mir, die Entscheidungen auch — das Tool hat das Tippen beschleunigt.

Ein konkretes Beispiel: Als wir die Telegram-Buttons gebaut haben, hatte ich ursprünglich keinen klaren Plan, ob das Editieren der Original-Nachricht oder eine neue Bestätigungs-Nachricht besser ist. Im Dialog mit Claude haben wir das `answerCallbackQuery`-Timing-Problem entdeckt, ich habe das Polling-Verhalten in der n8n-Doku verifiziert, und dann gemeinsam die robuste Lösung gebaut (neue Nachricht statt Edit). Das ist die Art Pair-Programming, die ich für gute Praxis halte: Tempo durch das Tool, Entscheidungen durch den Menschen.
