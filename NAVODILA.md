# Popis inventure – navodila za namestitev

Aplikacija je ena spletna stran (GitHub Pages), podatki so v Supabase, AI branje nalepk teče prek Supabase funkcije z vašim Anthropic ključem.

## 1. Baza (Supabase) – enkrat, 2 minuti

1. V Supabase odprite projekt → levo **SQL Editor** → **New query**.
2. Odprite datoteko `supabase/setup.sql`, kopirajte vso vsebino in jo prilepite.
3. V vrstici `insert into public.app_config (id, pin) values (1, 'ZAMENJAJ_ME')` zamenjajte **ZAMENJAJ_ME** s PIN-om ekipe.
   PIN naj ima **vsaj 8 znakov** (črke in številke), ker je spletni naslov aplikacije javen. Po 20 napačnih poskusih se prijava za 10 minut zaklene.
4. Kliknite **Run**. Spodaj mora pisati *Success*.

PIN kasneje spremenite z ukazom v SQL Editorju:
`update public.app_config set pin = 'NOVPIN' where id = 1;`

## 1b. Posodobitev baze (če ste bazo nastavili pred 20. 10. 2026)

V Supabase → **SQL Editor** → **New query** → prilepite vsebino `supabase/posodobitev-4.sql` → **Run**. PIN-a ne spreminjate.
Datoteka vsebuje vse posodobitve (povezane kode, brisanje popisnega lista, modul za vpisovalca) in jo je varno zagnati večkrat.

## 2. AI branje nalepk – enkrat, 5 minut

1. Na **console.anthropic.com** ustvarite API ključ (Settings → API Keys) in naložite dobroimetje (Billing).
2. V Supabase: levo **Edge Functions** → **Secrets** → *Add new secret*
   - Name: `ANTHROPIC_API_KEY`
   - Value: vaš ključ (začne se s `sk-ant-`)
3. **Edge Functions** → **Deploy a new function** → **Via Editor**.
   - Ime funkcije: `read-label` (točno tako)
   - Izbrišite primer kode, prilepite vsebino `supabase/functions/read-label/index.ts` → **Deploy**.
4. Odprite funkcijo `read-label` → **Details / Settings** → izklopite **Verify JWT** (»Enforce JWT verification«) → Save.
   Brez tega korak AI branje vrne napako 401. Zaščito zagotavlja PIN ekipe.

## 3. Objava na GitHub Pages – enkrat

1. V repozitoriju naložite datoteke: `index.html`, `sw.js`, `manifest.webmanifest`, `icon-192.png`, `icon-512.png` (mapa `supabase` je samo za arhiv, ni potrebna za delovanje).
   Na GitHubu: **Add file → Upload files** → povlecite datoteke → **Commit changes**.
2. **Settings → Pages** → *Source*: **Deploy from a branch** → Branch: **main**, mapa **/ (root)** → **Save**.
3. Po 1–2 minutah je aplikacija na naslovu `https://VAŠE-UPORABNIŠKO-IME.github.io/IME-REPOZITORIJA/`.

## 4. Na telefonu (vsak popisovalec)

1. Odprite zgornji naslov v **Chrome** (Android) ali **Safari** (iPhone).
2. Meni → **Dodaj na začetni zaslon**. Aplikacija se odpira kot običajna aplikacija.
3. Ob prvem odprtju: vpišite ime, PIN ekipe in ime popisa (vsi isti popis, npr. »Inventura 2026«). Dovolite dostop do kamere.

## Navodila za ekipo (1 minuta)

- **Skeniraj**: usmerite kamero na črtno kodo. Ko jo prebere, se kamera umakne, koda je v polju → **Potrdi**.
- **Ni kode ali se ne prebere**: tapnite polje in vpišite del šifre ali opisa (npr. `f741` ali `odklop c16`). Spodaj se prikažejo predlogi – tapnite pravega.
- **Znan artikel** (šifra, EAN ali povezana koda): takoj se odpre vnos količine → vpišete število → **Shrani**.
- **Koda je del ERP šifre ali opisa** (npr. skenirate `A9F74116`, ERP šifra je `SE-A9F74116` ali je koda v opisu): če tak artikel obstaja le eden, se takoj odpre vnos količine; če jih je več, tapnete pravega.
- **Koda ni na popisnem listu** (npr. EAN ali kataloška številka proizvajalca): vpišite del šifre ali opisa, tapnite pravi ERP artikel in vpišite količino. Koda se trajno poveže s tem artiklom – naslednjič jo prepozna vsak telefon. Gumb **Ni na seznamu – nov artikel** doda artikel, ki ga v ERP ni.
- **Nov artikel**: vpišete proizvajalca, opis, enoto, količino → **Shrani**. Naslednjič ga prepozna vsak telefon.
- **📷 Skeniraj s kamero**: vrne kamero za naslednji artikel.
- **Popisni list**: seznam vseh artiklov iz naloženega Excela. Tapnite artikel → vpišite količino. Filter *Nepopisani* pokaže, kaj še manjka.
- Isti artikel dvakrat: aplikacija vpraša **Prištej** ali **Zamenjaj**.
- **Moj seznam**: tap na vnos → popravek količine ali brisanje.
- Zgoraj desno: **Naloženo** = vse je v bazi; **Čaka N** = naloži se samo, ko bo internet. Popis teče tudi brez interneta.
- **AI nalepka** (gumb v kotu kamere): deluje le, če je nastavljen AI ključ.

## Vpisovalec (vnos v ERP)

- Ob prijavi izberite vlogo **Vpisovalec (vnašam v ERP)**. Odpre se zavihek **Vpis**.
- Artikli so v **vrstnem redu popisnega lista** (zaporedna številka pred šifro). Pri vsakem artiklu so skupna količina in **imena popisovalcev s količinami**, ob knjižni zalogi tudi razlika.
- **✓ Zaključi**: količina je v redu in vnesena v ERP. Artikel izgine s seznama *Za vpis*, popisovalci pa ga na popisnem listu vidijo s kljukico **✓ Pregledano**.
- **Preglej še enkrat**: izberete popisovalca in napišete opombo. Popisovalec dobi obvestilo (oranžen trak na zaslonu Skeniraj in zavihek *Ponovno* na popisnem listu). Ko artikel znova prešteje in shrani, se vrne na seznam *Za vpis* z oznako **Ponovno prešteto**.
- Zavihki: *Za vpis*, *Ponovno* (čaka popisovalca), *Zaključeni* (gumb *Vrni v vpis*, če ste se zmotili), *Nepopisani* (gumb *Prosi za popis*).
- Seznam se osveži sam vsakih 20 sekund ali z gumbom **Osveži**.

## Za vodjo popisa

- **Pregled** → **Naloži popisni list (Excel)**: popisni list iz ERP, Excel ali CSV. Vrstni red vrstic v Excelu je vrstni red v aplikaciji. Po nalaganju je viden vsem na zavihku **Popisni list**.
  Stolpci: *Šifra* (ERP, obvezno), *Art.nr*, *Kataloška številka* ali *Šifra proizvajalca* (priporočeno – potem skeniranje kode proizvajalca takoj najde ERP artikel), *EAN*, *Proizvajalec*, *Opis/Naziv*, *Enota*, *Zaloga*. Stolpci se prepoznajo po naslovih: *Šifra/Koda*, *EAN*, *Proizvajalec*, *Opis/Naziv*, *Enota*, *Zaloga*. Obvezna je le šifra.
- **Pregled** → **Osveži**: vsi vnosi vseh popisovalcev; filter po popisovalcu.
- **Izvozi vse**: Excel z zavihki *Po artiklih* (z razliko do knjižne zaloge), *Vnosi*, *Nepopisano* (artikli z zalogo, ki jih nihče ni popisal). Zavihek *Po artiklih* ima zaporedno številko in status (Zaključeno / Preglej še enkrat / Ponovno prešteto). Datoteka se shrani v mapo *Prenosi* ali pa jo pošljete naprej (e-pošta, WhatsApp, OneDrive).

## Težave

| Znak | Rešitev |
| --- | --- |
| »Kamera ni dostopna« | V nastavitvah brskalnika dovolite kamero za to stran; stran mora biti odprta prek `https://`. |
| »Napačen PIN« | PIN v aplikaciji se ne ujema s tistim v tabeli `app_config` (ali je tam še `ZAMENJAJ_ME`). |
| »Preveč napačnih poskusov« | Počakajte 10 minut ali v SQL Editorju zaženite `delete from public.pin_fails;`. |
| AI branje: napaka 401 | Pri funkciji `read-label` izklopite *Verify JWT*. |
| AI branje: »ANTHROPIC_API_KEY ni nastavljen« | Dodajte skrivnost v Edge Functions → Secrets. |
| AI branje: napaka 400/402 | Na console.anthropic.com preverite dobroimetje. |
| Oznaka »Napaka« zgoraj desno | Tapnite jo za opis napake; vnosi ostanejo na telefonu. |

## Brisanje popisnega lista

**Pregled → Izbriši** → izberite *Izbriši uvoženi popisni list* (artikli, vpisani med popisom, ostanejo) ali *Izbriši vse artikle in povezane kode* → vpišite **BRIŠI**.
Seznam se izbriše v bazi in ob naslednji sinhronizaciji na vseh telefonih. **Popisane količine ostanejo.** Nov popisni list nato naložite z *Naloži popisni list (Excel)*.
