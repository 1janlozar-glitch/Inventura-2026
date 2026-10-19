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

- **Lokacija**: zgoraj izberite ali skenirajte QR kodo police (oblika `LOK:R1-P3`). Velja, dokler je ne zamenjate.
- **Skeniraj** črtno kodo → koda se vpiše v polje → **Potrdi**. Kodo lahko tudi pretipkate.
- **Znan artikel**: vpišete le količino → **Shrani**.
- **Nov artikel**: vpišete proizvajalca, opis, enoto, količino → **Shrani**. Naslednjič ga prepozna vsak telefon.
- **Ni kode / se ne prebere**: usmerite kamero na nalepko → **Preberi z nalepke (AI)** → preverite predlog → količina → **Shrani**.
- Isti artikel na isti polici dvakrat: aplikacija vpraša **Prištej** ali **Zamenjaj**.
- **Moj seznam**: tap na vnos → popravek količine ali brisanje.
- Zgoraj desno: **Naloženo** = vse je v bazi; **Čaka N** = naloži se samo, ko bo internet. Popis teče tudi brez interneta.

## Za vodjo popisa

- **Pregled** → **Uvozi šifrant**: Excel ali CSV iz ERP. Stolpci se prepoznajo po naslovih: *Šifra/Koda*, *EAN*, *Proizvajalec*, *Opis/Naziv*, *Enota*, *Zaloga*. Obvezna je le šifra.
- **Pregled** → **Osveži**: vsi vnosi vseh popisovalcev; filter po osebi in lokaciji; oranžno označeno = možno dvojno štetje.
- **Izvozi vse**: Excel z zavihki *Po artiklih* (z razliko do knjižne zaloge), *Vnosi*, *Nepopisano* (artikli z zalogo, ki jih nihče ni popisal) in *Dvojno štetje*.

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
