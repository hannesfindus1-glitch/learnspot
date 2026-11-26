1. setup-social.sql in Supabase SQL Editor ausführen.
2. Nur die sechs Webdateien zu GitHub hochladen (index.html, config.js, sw.js, manifest.webmanifest, beide PNGs).
3. KI benötigt noch eine authentifizierte Supabase Edge Function learnspot-ai und einen serverseitigen KI-Anbieter. Kein API-Schlüssel in GitHub oder config.js. Erwartet JSON {question,material:{text,images},cards}, antwortet {answer,cards:[{q,a}]}. Diese Funktion ist noch nicht eingerichtet.
