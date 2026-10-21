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

V Supabase → **SQL Editor** → **New query** in po vrsti zaženite (**Run**):
1. `supabase/posodobitev-4.sql` – povezane kode, brisanje popisnega lista, modul za vpisovalca (če je še niste).
2. `supabase/posodobitev-5.sql` – **PIN vpisovalca** (samo enkrat!). Pred zagonom v vrstici `set vpis_pin = 'ZAMENJAJ_VPIS'` vpišite PIN vpisovalca (vsaj 8 znakov, drugačen od PIN-a ekipe).

PIN vpisovalca kasneje spremenite z: `update public.app_config set vpis_pin = 'NOVPIN' where id = 1;`

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

- **📷 Slikaj nalepko**: usmerite kamero na nalepko, da je oznaka artikla v belem okvirju → **Slikaj**. Aplikacija prebere besedilo (šifro, kataloško številko, opis) – črtnih in QR kod ne bere.
  - En zanesljiv zadetek → takoj se odpre vnos količine.
  - Več možnosti → pokaže najverjetnejše artikle, tapnite pravega.
  - Nič prebranega → vpišite šifro ročno. Pomaga: dobra svetloba, nalepka ravno in čez cel okvir.
  - Prvič se bralnik besedila nalaga nekaj sekund (približno 10 MB), nato je hiter.
- **Išči**: vpišite šifro ali del opisa (npr. `lc1d18`, `kontaktor 9a`, `unica okvir beli`). Spodaj se sproti pokažejo artikli – tapnite pravega.
- Vpišite **količino** → **Shrani**. Polje za iskanje je takoj pripravljeno za naslednji artikel.
- Artikla ni na seznamu: vpišite njegovo kodo → **Potrdi** → izpolnite proizvajalca, opis, enoto, količino → **Shrani**.
- **Popisni list**: vsi artikli v vrstnem redu iz Excela. Tapnite artikel → količina. Filter *Nepopisani* pokaže, kaj še manjka.
- Isti artikel dvakrat: aplikacija vpraša **Prištej** ali **Zamenjaj**.
- **Oranžen trak »Za ponovni pregled«**: vpisovalec prosi, da artikel preštejete znova. Tapnite trak → artikel → nova količina → **Zamenjaj**.
- **Moj seznam**: tap na vnos → popravek količine ali brisanje.
- Zgoraj desno: **Naloženo** = vse je v bazi; **Čaka N** = naloži se samo, ko bo internet. Popis teče tudi brez interneta.

## Vpisovalec (vnos v ERP)

Najprej v Supabase enkrat zaženite `supabase/posodobitev-7.sql` (ne spreminja PIN-ov).

- Na prijavi tapnite **Vpisovalec** in vpišite **PIN vpisovalca**. Odpre se zavihek **Vpis**.
- **Za vpis**: vsi odprti vnosi v vrstnem redu popisnega lista, s količino in imeni popisovalcev. Rdeč števec na zavihku pove, koliko jih čaka.
- Ko želite vnašati v ERP, tapnite **✓ Zaključi odprte → Excel**:
  - vsi odprti artikli gredo v **izvoz** z zaporedno številko (izvoz 1, 2, 3 …), datumom in vašim imenom;
  - prenese se Excel *»Vnos v ERP – … – izvoz N (datum).xlsx«*;
  - artikli se zaključijo, popisovalci vidijo kljukico. Nato v miru vnašate iz Excela.
- **Izvozi**: seznam vseh izvozov. Pri vsakem **⬇ Excel** (enak izvoz lahko prenesete znova) in **Prikaži artikle**. Pri artiklu **↺ Preglej še enkrat**, če se vam količina zdi napačna.
- **Ni podvajanja**: v naslednji izvoz pridejo samo novi vnosi in **popravki**. Popravek je artikel, ki se je po izvozu spremenil (ponovno štetje ali dodatni vnos). Označen je z rdečim **!** in v Excelu s stolpcema *Popravek* (prejšnja količina in izvoz) in *Razlika do prej*. **Pri popravku v ERP vpišite novo količino, ne prištevajte.**
- **Ponovno**: artikli, ki čakajo, da jih popisovalec znova prešteje (*Prekliči zahtevo*, če ste se premislili).
- Zaključevati lahko samo vpisovalec.

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

## Začni inventuro znova (samo vpisovalec)

Najprej v Supabase enkrat zaženite `supabase/posodobitev-6.sql` (ne spreminja PIN-ov).

**Pregled → ⟲ Začni inventuro znova** (gumb vidi samo vpisovalec):
1. Priporočeno: **Najprej izvozi v Excel**, da ostane kopija.
2. **Nadaljuj z brisanjem** → vpišite **PIN vpisovalca** in besedilo **ZAČNI ZNOVA**.

Izbrišejo se vse popisane količine in statusi pregleda tega popisa – v bazi in na vseh telefonih (ob naslednji sinhronizaciji; popisovalci dobijo obvestilo). **Popisni list in povezane kode ostanejo.** Vnosi, narejeni pred ponovnim začetkom, se tudi s telefonov brez interneta ne morejo več naložiti nazaj.

## Brisanje popisnega lista

**Pregled → Izbriši** → izberite *Izbriši uvoženi popisni list* (artikli, vpisani med popisom, ostanejo) ali *Izbriši vse artikle in povezane kode* → vpišite **BRIŠI**.
Seznam se izbriše v bazi in ob naslednji sinhronizaciji na vseh telefonih. **Popisane količine ostanejo.** Nov popisni list nato naložite z *Naloži popisni list (Excel)*.

## Prikaz

- **☀️ / 🌙** zgoraj desno: dnevni ali nočni prikaz (aplikacija si izbiro zapomni; privzeto sledi nastavitvi telefona).
- Med popisom zaslon telefona ne ugasne sam.
- Pri nenavadno veliki količini (npr. 25000 ali več kot 10× knjižne zaloge) aplikacija vpraša, ali je pravilna – zaščita pred tipkarsko napako.
- Ime se poenoti (JAN, jan → Jan), da je ista oseba vedno ena.
