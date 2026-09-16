# ImageDup

Applicazione visuale Windows VCL, scritta in Delphi 13, per trovare possibili duplicati visivi in JPEG, PNG e BMP. La finestra principale e definita in `ImageDup.Main.dfm` ed e modificabile con il designer di Delphi.

## Avvio e compilazione

Aprire `ImageDup.dproj` in Delphi 13 e compilare per Windows 64 bit, oppure da PowerShell:

```powershell
.\build.ps1
.\build\ImageDup.exe
```

Lo script genera la GUI `build\ImageDup.exe` e conserva la versione command line in `build\ImageDup.CLI.exe`. La GUI usa Virtual Treeview 8.3, gia presente nel Catalog Repository di questa installazione. I percorsi Delphi e Virtual Treeview possono essere indicati con `-DelphiRoot` e `-VirtualTreeRoot`.

## Interfaccia

- Il pannello superiore contiene i pulsanti classici per cartelle, sessioni, ricerca, selezioni, Cestino e dettagli errori. I comandi si abilitano secondo lo stato della scansione e dei risultati.
- Inserire una cartella per riga, oppure usare **Aggiungi cartella...**. La ricerca confronta le immagini anche tra cartelle diverse.
- **Includi le sottocartelle** applica la ricorsione a tutti i percorsi. Percorsi uguali o sovrapposti non fanno rileggere lo stesso file; non vengono seguite junction nelle sottocartelle.
- **Thread elaborazione** imposta quanti decoder/firme lavorano in parallelo, da 1 a 64; il valore iniziale e 3. Il coordinatore mantiene l'ordine di enumerazione, quindi il numero di thread non cambia la composizione dei gruppi.
- **Avvia ricerca** avvia il coordinatore in background e i worker configurati. I risultati arrivano progressivamente, mentre la finestra resta utilizzabile. **Interrompi** conserva i risultati raccolti; durante la decodifica attende la fine delle immagini correnti.
- Virtual Treeview mostra tutti i gruppi in un unico albero a colonne. Ogni gruppo e espandibile e contiene i relativi file; ogni file compare una sola volta.
- Ogni nodo file ha un checkbox indipendente e riporta percorso, dimensioni in pixel, byte, data/ora dell'ultima modifica e punteggio di qualita. Distanza, errore RGB, DPI e SSIM non sono mostrati; le verifiche percettive restano attive nel motore di confronto. Le righe dei gruppi mostrano testo soltanto nella prima colonna.
- I membri sono ordinati per qualita decrescente. Il primo e il riferimento del gruppo ed appare nero con carattere normale; i file percettivamente identici al riferimento sono verdi, gli altri duplicati ammessi sono rosso scuro.
- Un click su **File / gruppo** alterna l'ordinamento crescente e decrescente dei gruppi per numero di file. Gli altri header alternano l'ordinamento della relativa colonna dentro ogni gruppo; riferimento, checkbox e selezione corrente restano associati al file.
- **Selezioni** apre un menu che contrassegna in ogni gruppo il file piu piccolo, con meno pixel, tutti i file con qualita inferiore, i file identici al riferimento oppure il meno recente. Ogni criterio azzera prima le selezioni precedenti. Il menu puo inoltre garantire almeno un elemento non selezionato per gruppo oppure eseguire **Deseleziona tutto**. I checkbox indicano i file da spostare nel Cestino con il relativo comando.
- **Pulisci sessione** azzera percorsi, risultati, selezioni, errori, anteprime e avanzamento, ripristinando ricorsione attiva, distanza 8 e 3 thread. Non elimina alcun file.
- **Sposta nel Cestino** chiede conferma e usa `IFileOperation` con `FOFX_RECYCLEONDELETE`. Se Windows non offre il Cestino, la cancellazione definitiva viene bloccata. I file spostati vengono rimossi dai risultati; quelli non spostati restano selezionati e sono riportati nei dettagli errori.
- La status bar contiene un meter: durante l'enumerazione e indeterminato, poi mostra l'avanzamento sui file trovati. Riporta inoltre la somma delle dimensioni dei file selezionati, aggiornata immediatamente quando cambia un checkbox o viene applicata una selezione automatica.
- Il punteggio tecnico va da 0 a 100 ed e calcolato relativamente ai membri dello stesso gruppo: risoluzione e nitidezza pesano 24 punti ciascuna; seguono assenza di artefatti 14, basso rumore 10, profondita colore 7, clipping 7, banding 5, rischio di upscaling 4, profilo colore 3 e chroma subsampling 2. DPI e dimensione del file non partecipano al punteggio. Nitidezza, rumore, artefatti, clipping, banding e upscaling sono stime euristiche ottenute dai pixel; profondita e profilo provengono da WIC, mentre il sottocampionamento JPEG viene letto dal segmento SOF.
- Selezionare un gruppo o uno dei suoi file per mostrare in basso tutte le immagini appartenenti al gruppo. La galleria calcola dinamicamente righe e colonne in base al numero di membri, alle proporzioni originali e allo spazio disponibile, scegliendo la disposizione che rende complessivamente piu grandi le immagini. Ogni riquadro mostra nome, dimensioni, peso, data/ora e metriche; il file selezionato viene evidenziato. Un clic sull'anteprima o un doppio clic sulla riga file apre l'immagine alla dimensione originale, senza interpolazione. Se supera l'area disponibile del monitor, la finestra viene limitata allo schermo e l'immagine si puo trascinare per esplorarla. Il visualizzatore usa un controllo a doppio buffer e modifica l'offset di disegno, evitando lo sfarfallio durante il trascinamento. Un clic sul margine esterno, un clic fuori dalla finestra, un clic sull'immagine senza trascinamento oppure `Esc` richiude la vista.
- **Salva sessione...** e **Carica sessione...** usano i dialoghi moderni di Windows. Il formato proprietario ha estensione `.idup` e contiene JSON versionato con criteri, numero di thread, totale analizzato, percorsi, gruppi, metadati, metriche e checkbox. Le sessioni precedenti restano leggibili; se manca `threadCount` viene usato 3 e se manca `scannedFiles` il conteggio risulta non disponibile. Il caricamento ricostruisce subito l'albero senza rieseguire la scansione e ripropone totale e meter nella status bar. Se un'immagine non esiste piu, i dati restano visibili e l'anteprima segnala l'assenza.
- La finestra e ridimensionabile. Trascinare il separatore orizzontale sopra le anteprime per distribuire lo spazio tra albero e immagini.
- Gli errori sono conteggiati nella barra di stato e consultabili con **Dettagli errori...** (primi 200). Un file rimosso dopo la scansione viene indicato come anteprima non disponibile.
- Le dimensioni dei file e la risoluzione sono informazioni di confronto visuale, non criteri usati per decidere la somiglianza.

La scansione e il confronto non modificano le immagini. I file vengono spostati nel Cestino soltanto usando esplicitamente il relativo pulsante e confermando l'operazione. Le soglie sono euristiche: i risultati sono candidati da controllare.

## Sorgenti

- `ImageDup.dpr` / `ImageDup.dproj`: applicazione VCL.
- `ImageDup.Main.pas` / `ImageDup.Main.dfm`: finestra, albero Virtual Treeview, checkbox, selezione e anteprime.
- `ImageDup.Groups.pas`: raggruppamento prudente, con verifica di tutti i membri e senza concatenazioni transitive.
- `ImageDup.Session.pas`: lettura e scrittura del formato JSON di sessione versione 1.
- `ImageDup.Scan.pas`: coordinatore e coda limitata per i worker, deduplicazione percorsi, ordine deterministico, metadati e aggiornamenti a blocchi protetti da lock. Nessun thread accede ai controlli.
- `ImageDup.Core.pas`: decoder WIC, firma percettiva e confronto condiviso; usa `POPCNT` su CPU compatibili e il percorso Pascal sulle altre.
- `ImageDup.CLI.dpr`: CLI precedente, incluso export CSV.

## Test della GUI

```powershell
.\test-gui.ps1
```

Compila GUI e CLI, genera le immagini sintetiche, esegue la regressione CLI e poi il test di integrazione VCL con controlli di range/overflow attivi. Il test istanzia il DFM reale e verifica: struttura gruppo/file, checkbox su ogni file, cinque colonne, celle gruppo pulite, byte, pixel, qualita, data/ora, ordinamento, colori, meter, menu di selezione, anteprime, salvataggio e caricamento completo della sessione, numero di thread, geometria minima, file scomparsi, ricerca vuota, arresto e chiusura. Confronta l'albero prodotto con 1 e 3 worker e ripete dieci scansioni con il ciclo messaggi VCL attivo.

La verifica automatica di comportamento e geometria e passata. Il controllo interattivo via automazione desktop non e stato disponibile per un errore di avvio del sandbox; i tentativi di rendering fuori schermo non sono stati usati come verifica visiva conclusiva. Il layout non e stato verificato manualmente a DPI diversi.

## CLI conservata

```powershell
.\build\ImageDup.CLI.exe "D:\Foto" --recursive --csv "D:\candidati.csv"
```

Il CSV e disponibile nella CLI. Deve essere un file nuovo: un file esistente non viene sovrascritto.

## Confronto e gruppi

1. Decodifica JPEG/PNG/BMP tramite Windows Imaging Component, con decoder indipendenti per i lavori concorrenti, senza usare nome, peso, data o risoluzione come criteri di uguaglianza. I pixel con trasparenza vengono composti su bianco.
2. Ricampiona per area a 64 x 64 RGB su sfondo bianco. Mantiene una vista 32 x 32 per l'hash DCT a 63 bit e il primo filtro RGB.
3. Verifica i candidati sui 64 x 64 pixel: RMSE RGB globale, SSIM medio e peggiore SSIM di blocchi locali 8 x 8. Controlla anche il peggior errore RGB locale, per evitare che differenze circoscritte spariscano nella media.
4. Accetta soltanto se tutte le condizioni passano: distanza entro la soglia scelta, RMSE RGB entro la soglia interna 0.08, SSIM medio >= 0.97, ogni blocco SSIM >= 0.80, ogni blocco RMSE RGB <= 0.18. Le soglie percettive sono costanti in `ImageDup.Core.pas`.
5. Nella GUI inserisce il nuovo file nel primo gruppo con cui ha superato **tutti** i confronti. Una catena A~B e B~C non basta ad affermare A~C. I singoli restano interni e diventano visibili solo quando trovano un altro membro.

I gruppi sono disgiunti e conservativi: l'ordine di scansione puo influire sulla partizione. In casi ambigui un file puo restare singolo pur avendo una somiglianza con un membro di un gruppo che contiene anche immagini incompatibili. Non si afferma che tutte le somiglianze costituiscano classi di equivalenza.

Distanza 1 significa al massimo un bit diverso: **non certifica l'uguaglianza**. SSIM e un indice, non una probabilita. Questa implementazione usa finestre uniformi non sovrapposte e non coincide con il riferimento SSIM a finestra gaussiana o con MS-SSIM.

Il motore piu severo e condiviso anche dalla CLI, che mantiene il formato a coppie e l'export CSV per compatibilita.

Riferimenti: [DCT percettiva](https://phash.org/docs/design.html) e [SSIM, lavoro originale degli autori](https://www.cns.nyu.edu/pub/lcv/wang03-reprint.pdf).

### Parallelismo e ottimizzazioni del core

La scansione usa worker dedicati e non il pool globale RTL, per rispettare esattamente il valore scelto. Ogni worker decodifica con WIC e calcola la firma completa; il coordinatore confronta e raggruppa le firme nell'ordine originario. La coda consente al massimo due lavori anticipati per worker, evitando che una prima immagine lenta faccia accumulare firme e bitmap senza limite.

Il percorso VCL con piu decoder concorrenti ha mostrato forte contesa ed e stato sostituito nel motore di scansione dal decoder WIC. Su un corpus sintetico locale di 60 JPEG da 1600 x 1200, una scansione e passata da 2123 ms con 1 worker a 667 ms con 3 worker, circa 3,2 volte piu veloce. Il valore dipende da CPU, disco e immagini.

Nel core la tabella dei coseni DCT viene inizializzata una volta, la luminanza 64 x 64 viene conservata nella firma e riutilizzata dai confronti SSIM, e `HashDistance` usa l'istruzione Win64 `POPCNT` quando `IsProcessorFeaturePresent` la dichiara disponibile. Sul benchmark locale, 20 milioni di distanze hash sono passate da 282 a 25 ms e 10.000 confronti strutturali da 230 a 165 ms. Il fallback Pascal resta attivo per processori senza `POPCNT`.
### Regressioni contro i falsi positivi

`ImageDup.CoreTests.dpr` verifica immagini con differenze ad alta frequenza e modifiche locali che producono **hash identico ed errore RGB 32 x 32 nullo**. Il vecchio criterio le avrebbe accettate; il nuovo le esclude. Verifica anche il caso in cui il SSIM medio passa ma il blocco locale fallisce, le copie esatte e il raggruppamento senza catene spurie. `test-gui.ps1` esegue questi test insieme alle regressioni CLI e GUI.

Sul caso segnalato `1095338337.jpeg` / `1118568184.jpg`, il confronto diretto nuovo misura distanza 34, RMSE circa 0.30, SSIM medio circa 0.04: la coppia e esclusa anche dal worker GUI con distanza 1. L'eseguibile CLI precedente, provato isolatamente sui medesimi due file, gia non li associava: il falso positivo esatto sui due file non e stato riprodotto. Durante le prove GUI e emerso invece il problema intermittente del canvas descritto sopra, ora corretto. La correttezza del collegamento tra gruppi, righe e anteprime e coperta dai test.
## Opzioni

```text
ImageDup <cartella> [--recursive] [--csv <nuovo-file.csv>]
         [--distance 0..63] [--pixel-error 0..1]
```

- `--recursive`: include le sottocartelle. Le directory reparse point (junction e link) vengono saltate per evitare cicli.
- `--distance`: massimo numero di bit differenti, default 8. Piu basso e piu restrittivo.
- `--pixel-error`: massimo RMSE RGB normalizzato, default 0.08. Usare il punto decimale. Piu basso e piu restrittivo.
- `--csv`: report UTF-8 con campi `file_a,file_b,hash_distance,pixel_rmse`. Le due metriche sono distanze, non percentuali di probabilita.
- `--help`: mostra l'uso.

Le coppie vengono scritte anche su stdout, senza intestazione. Stato ed errori vanno su stderr. Codici di uscita: 0 completato (anche senza corrispondenze), 1 errore di avvio/argomenti/output, 2 scansione parziale con errori di lettura.

## Verifica

```powershell
.\test.ps1
```

Il test CLI genera immagini sintetiche e verifica copie esatte, ricampionamento 256/512 pixel, JPEG di qualita 35, esclusione di immagini diverse e campi uniformi rossi/blu, ricorsione, report CSV, protezione da sovrascrittura, argomenti non validi e file corrotti. Gli artefatti restano in una cartella univoca sotto `build`.

La versione corrente e stata compilata con il compilatore Win64 37.0 di Delphi 13 e il test e passato. I warning sulla specificita Windows delle API di enumerazione sono attesi.

## Limiti della prima versione

- Le soglie iniziali sono euristiche: servono prove sul proprio archivio per valutare falsi positivi e negativi. I test sintetici non rappresentano tutte le fotografie reali.
- Nessuna garanzia su ritagli, rotazioni, specchiature, watermark o forti modifiche. I nuovi filtri locali, volutamente severi contro i falsi positivi, possono escludere copie con modifiche o compressione marcata. L'orientamento EXIF non viene normalizzato esplicitamente. Immagini visualizzate con rotazioni EXIF diverse possono non coincidere.
- La verifica RGB e sensibile alle modifiche di luminosita e colore. Un hash identico non certifica che due immagini siano duplicati.
- I dettagli eliminati dal ricampionamento possono produrre falsi positivi. Anche distanza zero e RMSE zero indicano solo uguaglianza delle rappresentazioni ridotte.
- Le immagini vengono portate a un quadrato: le proporzioni originali non sono un filtro, percio anche deformazioni possono corrispondere.
- Nessuna gestione esplicita di profili colore ICC, immagini animate, RAW, TIFF, HEIC o WebP.
- Ogni worker decodifica un'immagine intera in memoria. Le firme occupano circa 19 KB per immagine piu i percorsi; si confrontano tutte le coppie, quindi il costo resta O(n^2). Per archivi grandi i prossimi passi sono un indice per hash e una cache persistente.

Evoluzioni possibili: orientamento EXIF, verifiche su dettagli oltre i 64 x 64 pixel, indice/cache per grandi raccolte e confronto di caratteristiche locali per i ritagli. L'eventuale cancellazione richiedera un flusso separato di revisione dei risultati.
