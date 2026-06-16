#!/bin/bash
#
# import_bewerbungen.sh
#
# Demo-/Test-Werkzeug: Spielt die 15 fiktiven Bewerbungen aus bewerbungen.json
# nacheinander in den produktiven Webhook-Eingang ein (Workflow 1).
#
# Jede Bewerbung wird als eigener HTTP-POST verschickt - genau so, wie ein
# echtes Formular (z.B. Tally) eine einzelne Bewerbung an n8n schicken wuerde.
# Das ist bewusst KEIN Bulk-Import-Feature, sondern simuliert realistischen
# Eingang ueber den bestehenden Webhook-Kanal.
#
# Nutzung:
#   chmod +x import_bewerbungen.sh
#   ./import_bewerbungen.sh bewerbungen.json
#
# Voraussetzung: jq muss installiert sein (json-Parser)
#   sudo apt-get install -y jq
#
# Optional: WEBHOOK_URL und PAUSE per Umgebungsvariable ueberschreiben
#   WEBHOOK_URL="https://..." PAUSE=5 ./import_bewerbungen.sh bewerbungen.json

set -e

WEBHOOK_URL="${WEBHOOK_URL:-https://n8n-f8uj.srv1748804.hstgr.cloud/webhook/bewerbung}"
PAUSE="${PAUSE:-3}"
INPUT_FILE="${1:-bewerbungen.json}"

if [ ! -f "$INPUT_FILE" ]; then
  echo "Datei nicht gefunden: $INPUT_FILE"
  echo "Nutzung: $0 bewerbungen.json"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "jq ist nicht installiert. Installiere mit: sudo apt-get install -y jq"
  exit 1
fi

COUNT=$(jq '.bewerbungen | length' "$INPUT_FILE")
echo "Gefunden: $COUNT Bewerbungen in $INPUT_FILE"
echo "Ziel: $WEBHOOK_URL"
echo "Pause zwischen Requests: ${PAUSE}s"
echo "---"

for i in $(seq 0 $((COUNT - 1))); do
  BEWERBUNG=$(jq ".bewerbungen[$i]" "$INPUT_FILE")
  NAME=$(echo "$BEWERBUNG" | jq -r '.name')
  ID=$(echo "$BEWERBUNG" | jq -r '.id')

  # externe_id mitschicken, damit der Datensatz in NocoDB der Quelle zuordenbar bleibt.
  # Alle anderen Felder werden 1:1 durchgereicht - der Normalizer in Workflow 1
  # erwartet exakt dieses flache Bewerbungs-Format.
  PAYLOAD=$(echo "$BEWERBUNG" | jq '. + {externe_id: .id}')

  echo "[$((i + 1))/$COUNT] Sende: $NAME ($ID)"

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

  if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo "    -> OK ($HTTP_CODE)"
  else
    echo "    -> FEHLER ($HTTP_CODE)"
  fi

  if [ "$i" -lt $((COUNT - 1)) ]; then
    sleep "$PAUSE"
  fi
done

echo "---"
echo "Alle $COUNT Bewerbungen wurden eingespielt."
echo "Pruefe das Ergebnis in NocoDB: http://46.202.154.208:8080"
