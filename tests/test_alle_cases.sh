#!/bin/bash
#
# test_alle_cases.sh
#
# Demo-/Test-Werkzeug: Spielt 8 konstruierte Testfaelle in den produktiven
# Webhook-Eingang ein (Workflow 1), um jeden Pfad des Routing-Switches,
# das Scoring und den Spam-Filter gezielt durchzutesten.
#
# Namensschema: TestXX_<Hinweis zum Szenario>_<erwarteter Weg und Ausgang>
#
# Abgedeckte Faelle:
#   1) PLZ schlecht, alles vollstaendig          -> direkte Absage
#   2) PLZ unbekannt, alles vollstaendig         -> Grenzfall (Telegram)
#   3) Daten fehlen, PLZ gut                     -> Rueckfrage, danach Einladung
#   4) alles perfekt                             -> Scoring & Routing -> Einladung
#   5) mittlerer Score                           -> Scoring & Routing -> Grenzfall
#   6) gemischte PLZ (bester Wert gewinnt)       -> Scoring & Routing -> Einladung
#   7) Spam-Heuristik                            -> aussortiert
#   8) Daten fehlen UND PLZ schlecht             -> direkte Absage, KEINE Rueckfrage
#
# Nutzung:
#   chmod +x test_alle_cases.sh
#   ./test_alle_cases.sh
#
# Hinweis zu Test 3: Dieser Test sendet zunaechst nur die initiale Bewerbung
# (loest die Rueckfrage-Mail aus). Der Rueckfrage-Loop (Antwort per E-Mail
# mit REF-ID, Subworkflow) muss danach manuell durchgespielt werden, da er
# auf einem echten Gmail-Postfach basiert und nicht headless simulierbar ist.
#
# Optional: WEBHOOK_URL und PAUSE per Umgebungsvariable ueberschreiben
#   WEBHOOK_URL="https://..." PAUSE=5 ./test_alle_cases.sh

set -e

URL="${WEBHOOK_URL:-https://n8n-f8uj.srv1748804.hstgr.cloud/webhook/bewerbung}"
PAUSE="${PAUSE:-3}"

echo "Ziel: $URL"
echo "Pause zwischen Requests: ${PAUSE}s"
echo "---"

echo "Test 1: Test01_PLZ schlecht alles vollstaendig_direkte Absage"
curl -X POST "$URL" -H "Content-Type: application/json" -d '{
  "name": "Test01_PLZ schlecht alles vollstaendig_direkte Absage",
  "email": "marcusflock@web.de",
  "telefon": "030 1111111",
  "wohnort": "Berlin",
  "plz_wohnort": "10115",
  "abgedeckte_plz": ["10","12"],
  "max_fahrtweg_km": 40,
  "berufserfahrung_jahre": 5,
  "vorheriger_beruf": "Makler",
  "verfuegbarkeit_stunden_pro_woche": 20,
  "iso_zertifizierung": false,
  "fuehrerschein": true,
  "kurzmotivation": "Ich moechte mich als Objektbesichtiger bewerben und bin sehr motiviert."
}'
echo ""
sleep "$PAUSE"

echo "Test 2: Test02_PLZ unbekannt alles vollstaendig_Grenzfall manuelle Pruefung"
curl -X POST "$URL" -H "Content-Type: application/json" -d '{
  "name": "Test02_PLZ unbekannt alles vollstaendig_Grenzfall manuelle Pruefung",
  "email": "marcusflock@web.de",
  "telefon": "0911 2222222",
  "wohnort": "Nuernberg",
  "plz_wohnort": "90402",
  "abgedeckte_plz": ["91"],
  "max_fahrtweg_km": 50,
  "berufserfahrung_jahre": 6,
  "vorheriger_beruf": "Immobilienverwalter",
  "verfuegbarkeit_stunden_pro_woche": 20,
  "iso_zertifizierung": false,
  "fuehrerschein": true,
  "kurzmotivation": "Ich verwalte seit Jahren Wohnimmobilien und moechte meine Erfahrung einbringen."
}'
echo ""
sleep "$PAUSE"

echo "Test 3: Test03_Daten fehlen PLZ gut_Rueckfrage und anschliessend Einladung"
curl -X POST "$URL" -H "Content-Type: application/json" -d '{
  "name": "Test03_Daten fehlen PLZ gut_Rueckfrage und anschliessend Einladung",
  "email": "marcusflock@web.de",
  "telefon": "0491 4444444",
  "wohnort": "Leer",
  "plz_wohnort": "26789",
  "abgedeckte_plz": ["26","27"],
  "max_fahrtweg_km": 50,
  "berufserfahrung_jahre": 12,
  "vorheriger_beruf": "Bausachverstaendiger",
  "verfuegbarkeit_stunden_pro_woche": null,
  "iso_zertifizierung": true,
  "fuehrerschein": true,
  "kurzmotivation": "Ich bin seit 12 Jahren als Bausachverstaendiger taetig und kenne die Region Ostfriesland sehr gut."
}'
echo ""
echo "  -> ACHTUNG: Test 3 erzeugt eine Rueckfrage-Mail. Antworte darauf mit"
echo "     'Verfuegbarkeit: 25 Stunden pro Woche' um den Rueckfrage-Loop"
echo "     manuell zu testen (Ergebnis sollte Einladung sein)."
sleep "$PAUSE"

echo "Test 4: Test04_alles perfekt_Scoring und Routing Einladung"
curl -X POST "$URL" -H "Content-Type: application/json" -d '{
  "name": "Test04_alles perfekt_Scoring und Routing Einladung",
  "email": "marcusflock@web.de",
  "telefon": "0251 3333333",
  "wohnort": "Muenster",
  "plz_wohnort": "48149",
  "abgedeckte_plz": ["48","49"],
  "max_fahrtweg_km": 60,
  "berufserfahrung_jahre": 8,
  "vorheriger_beruf": "Architekt",
  "verfuegbarkeit_stunden_pro_woche": 25,
  "iso_zertifizierung": true,
  "fuehrerschein": true,
  "kurzmotivation": "Ich bin seit 8 Jahren als Architekt taetig und moechte meine Erfahrung einbringen."
}'
echo ""
sleep "$PAUSE"

echo "Test 5: Test05_mittlerer Score_Scoring und Routing manuelle Pruefung"
curl -X POST "$URL" -H "Content-Type: application/json" -d '{
  "name": "Test05_mittlerer Score_Scoring und Routing manuelle Pruefung",
  "email": "marcusflock@web.de",
  "telefon": "0521 5555555",
  "wohnort": "Bielefeld",
  "plz_wohnort": "33602",
  "abgedeckte_plz": ["33"],
  "max_fahrtweg_km": 30,
  "berufserfahrung_jahre": 1,
  "vorheriger_beruf": "Quereinsteiger",
  "verfuegbarkeit_stunden_pro_woche": 12,
  "iso_zertifizierung": false,
  "fuehrerschein": true,
  "kurzmotivation": "Ich interessiere mich fuer die Taetigkeit."
}'
echo ""
sleep "$PAUSE"

echo "Test 6: Test06_gemischte PLZ bester Wert gewinnt_Scoring und Routing Einladung"
curl -X POST "$URL" -H "Content-Type: application/json" -d '{
  "name": "Test06_gemischte PLZ bester Wert gewinnt_Scoring und Routing Einladung",
  "email": "marcusflock@web.de",
  "telefon": "030 6666666",
  "wohnort": "Berlin",
  "plz_wohnort": "10629",
  "abgedeckte_plz": ["10","12","13","14"],
  "max_fahrtweg_km": 40,
  "berufserfahrung_jahre": 3,
  "vorheriger_beruf": "Immobilienmaklerin",
  "verfuegbarkeit_stunden_pro_woche": 25,
  "iso_zertifizierung": true,
  "fuehrerschein": true,
  "kurzmotivation": "Suche flexiblen Nebenverdienst zu meiner Maklertaetigkeit."
}'
echo ""
sleep "$PAUSE"

echo "Test 7: Test07_Spam Heuristik_aussortiert"
curl -X POST "$URL" -H "Content-Type: application/json" -d '{
  "name": "WICHTIG SOFORT LESEN",
  "email": "marcusflock@web.de",
  "telefon": "+44 700 0000000",
  "wohnort": "weltweit",
  "plz_wohnort": "00000",
  "abgedeckte_plz": ["00"],
  "max_fahrtweg_km": 9999,
  "berufserfahrung_jahre": 99,
  "vorheriger_beruf": "Krypto-Investor",
  "verfuegbarkeit_stunden_pro_woche": 168,
  "iso_zertifizierung": true,
  "fuehrerschein": true,
  "kurzmotivation": "BESTE IMMOBILIEN INVESTMENTS GARANTIERT KLICKEN SIE HIER FUER RENDITE Einzigartige Gelegenheit"
}'
echo ""
sleep "$PAUSE"

echo "Test 8: Test08_Daten fehlen und PLZ schlecht_direkte Absage keine Rueckfrage"
curl -X POST "$URL" -H "Content-Type: application/json" -d '{
  "name": "Test08_Daten fehlen und PLZ schlecht_direkte Absage keine Rueckfrage",
  "email": "marcusflock@web.de",
  "telefon": "030 7777777",
  "wohnort": "Berlin",
  "plz_wohnort": "10115",
  "abgedeckte_plz": ["10","12"],
  "max_fahrtweg_km": 40,
  "berufserfahrung_jahre": 4,
  "vorheriger_beruf": "Verwaltungsangestellte",
  "verfuegbarkeit_stunden_pro_woche": null,
  "iso_zertifizierung": false,
  "fuehrerschein": true,
  "kurzmotivation": "Ich moechte mich als Objektbesichtigerin bewerben."
}'
echo ""

echo "---"
echo "Alle 8 Testfaelle wurden eingespielt."
echo "Pruefe das Ergebnis in NocoDB: http://46.202.154.208:8080"
