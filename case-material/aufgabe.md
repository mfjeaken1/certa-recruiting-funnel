# Case: Recruiting-Funnel für Objektbesichtiger

**Für Kandidat:innen der Rolle Head of Operations bei Certa**

---

## Worum es geht

Bei Certa arbeiten wir mit einem deutschlandweiten Netz festangestellter Objektbesichtiger (kurz OBs). Sie nehmen Immobilien für unsere Gutachten vor Ort auf — Fotos, Maße, Zustandsdokumentation. Damit wir bundesweit liefern können, brauchen wir kontinuierlich neue OBs in genau den Postleitzahlgebieten, in denen Aufträge auflaufen.

Heute sieht der Recruiting-Prozess so aus: Wir bekommen pro Woche zwischen zwanzig und vierzig Bewerbungen. Eine Mitarbeiterin sichtet jede einzelne Bewerbung manuell, prüft die Postleitzahl gegen unsere aktuelle Bedarfskarte, schiebt passende Bewerber:innen in ein Tool, das automatisierte Nachfass-Mails versendet, und antwortet den unpassenden Bewerber:innen einzeln. Das funktioniert, aber es kostet jede Woche viele Stunden Aufmerksamkeit. Und es skaliert nicht, wenn wir wachsen.

Wir wollen einen automatisierten Recruiting-Funnel, der eingehende Bewerbungen entgegennimmt, bewertet, in die richtige Pipeline einsortiert und die richtigen Antworten verschickt — ohne dass dafür jemand jede Bewerbung einzeln in die Hand nehmen muss.

Bau uns dafür einen funktionsfähigen Prototyp.

## Deine Aufgabe

Stell Dir vor, Du bekommst diesen Auftrag an Deinem ersten Arbeitstag bei Certa. Du hast einen halben bis ganzen Arbeitstag Zeit (rund vier bis acht Stunden) und keine bestehende Codebase, an die Du Dich halten musst.

Der Kern der Aufgabe ist, dass Du eine eigene, lauffähige Plattform baust. Kein Konzeptpapier, keine reine Skizze und kein zusammengeklicktes No-Code-Setup, sondern eine Anwendung, die man starten kann und die den Prozess tatsächlich durchläuft. Mit welchen Werkzeugen, welcher Sprache und welchem Framework Du das machst, ist uns völlig egal. Nimm, womit Du am schnellsten zu einem funktionierenden Ergebnis kommst.

Bau eine Anwendung, die folgenden End-to-End-Prozess abbildet. Eine Bewerbung kommt rein, mit Name, E-Mail, Wohnort, abgedeckten Postleitzahlen, Berufserfahrung, Verfügbarkeit pro Woche, Kurzmotivation und optional einer kleinen Selbsteinschätzung der relevanten Skills. Die Anwendung soll diese Bewerbung gegen unseren aktuellen Bedarf prüfen, eine Eignungsbewertung vornehmen, die Bewerbung in eine sinnvolle Pipeline einsortieren und automatisch die passende Folgekommunikation auslösen. Am Ende soll eine zuständige Mitarbeiterin in einer übersichtlichen Oberfläche sehen können, welche Bewerber:innen aktuell im Pool sind, in welchem Status sie stehen und wo manuelle Aufmerksamkeit gebraucht wird.

Wie Du das im Detail umsetzt, liegt komplett bei Dir. Welche Datenstrukturen Du wählst, welches Frontend Du baust (oder ob ein Admin-Tool wie eine kleine Streamlit- oder Next.js-Oberfläche reicht), wie Du die Bewertungslogik gestaltest, wo Du KI einsetzt und wo bewusst nicht, welche Edge Cases Du behandelst — alles Deine Entscheidung. Wir wollen sehen, wie Du an so ein Problem rangehst, nicht eine Lösung, die nach Schema F gebaut wurde.

## Was Du an Material bekommst

Wir stellen Dir drei Dinge als Input bereit.

Erstens eine fiktive Bedarfskarte als CSV. Sie listet rund fünfzig Postleitzahlbereiche in Deutschland mit aktuellem Bedarf, zum Beispiel „dringend gesucht", „Aufstockung sinnvoll", „aktuell voll besetzt" oder „nicht gefragt". Die Karte ist absichtlich nicht perfekt sauber. Es gibt Lücken, Inkonsistenzen und eine Spalte mit Freitext-Notizen.

Zweitens fünfzehn fiktive Bewerbungen als JSON-Dump. Manche sind perfekte Kandidat:innen für gesuchte Gebiete, manche bewerben sich für Regionen mit Überbestand, manche haben unvollständige Angaben, und mindestens eine Bewerbung ist offensichtlich nicht ernst gemeint.

Drittens unsere bestehende Standardkommunikation als drei kurze Textvorlagen: eine Einladung zum nächsten Schritt, eine freundliche Absage für nicht passende Regionen und eine Rückfrage bei unklaren Angaben.

Die Datensätze geben wir Dir nach Bestätigung der Case-Teilnahme als ZIP.

## Worauf wir achten werden

Wir bewerten nicht die Schönheit Deines Codes. Wir schauen darauf, ob Du das Problem verstanden und sinnvoll zerlegt hast, ob Deine Lösung tatsächlich Arbeit spart oder nur Arbeit verschiebt, und ob Du dort, wo es sinnvoll ist, automatisierst statt aus Prinzip alles zu automatisieren. Wir achten darauf, ob Du an die Mitarbeiterin gedacht hast, die Dein Tool später bedient, ob Dein System scheitert, wenn jemand eine kaputte Bewerbung schickt, und ob Du in den richtigen Momenten zu früh oder zu spät automatisierst. Wenn Du KI einsetzt, interessiert uns, an welchen Stellen Du das tust und wo Du bewusst darauf verzichtest, weil deterministische Logik die bessere Wahl ist.

Was uns besonders interessiert, ist Dein Umgang mit Mehrdeutigkeit. Die Bedarfskarte ist nicht eindeutig, die Bewerbungen sind unterschiedlich vollständig, und es gibt keine objektiv richtige Schwelle, ab der jemand „qualifiziert" ist. Wie Du damit umgehst, sagt uns mehr über Dich als die Frage, ob Dein Code in Python oder TypeScript geschrieben ist.

Was wir nicht erwarten: produktionsreifen Code, fertige Tests, perfekte UI, vollständige Authentifizierung. Es ist ein Prototyp. Wenn etwas nicht geschafft wurde, dokumentier es kurz und erklär, was Du als nächstes gebaut hättest.

## Wie Du abgibst

Du schickst uns ein Repository (GitHub, GitLab oder als ZIP), das Deinen Code enthält, eine kurze README mit Setup-Anleitung und Deinen wichtigsten Entscheidungen, und idealerweise einen Screenshot oder ein kurzes Loom-Video, das die Lösung in Aktion zeigt. Drei bis fünf Minuten Loom reichen völlig. Wichtig ist, dass wir die Plattform bei uns starten oder zumindest im Video laufen sehen können.

Wenn Du im Bau KI-Tools genutzt hast, freuen wir uns über einen kurzen Hinweis darauf, wie Du damit gearbeitet hast. Wo sie Dir geholfen haben, wo Du eingegriffen hast und was Du bewusst selbst entschieden hast. Das ist nicht Pflicht, aber für uns aufschlussreich.

## Wie es weitergeht

Wir melden uns innerhalb von drei Werktagen nach Deiner Abgabe. Wenn Deine Lösung uns überzeugt, laden wir Dich zu einem etwa neunzigminütigen Live-Gespräch mit Alex Rausch und Matthias Mertens (Geschäftsführung) ein. In diesem Gespräch gehen wir gemeinsam durch Deine Lösung, diskutieren Deine Entscheidungen und erweitern die Aufgabe live um zwei oder drei Folge-Szenarien. Es geht uns dabei nicht ums Verteidigen, sondern ums gemeinsame Denken.

Wenn Du im Laufe der Bearbeitung Fragen hast, schreib uns einfach. Antworten auf Klärungsfragen sind kein Punktabzug, sondern Teil einer normalen Arbeitsbeziehung.

Viel Erfolg. Wir freuen uns darauf zu sehen, was Du baust.
