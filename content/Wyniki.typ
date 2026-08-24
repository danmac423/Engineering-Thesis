#import "../utils.typ": flex-caption, silentheading, todo

#let placeholder(h, opis) = rect(
  width: 100%,
  height: h,
  fill: luma(245),
  stroke: (paint: luma(160), thickness: 0.5pt, dash: "dashed"),
  align(center + horizon, text(size: 9pt, fill: luma(110), opis)),
)

= Wyniki i ich omówienie
<wyniki-i-ich-omowienie>

== Wpływ mechanizmu uwagi i kwantyzacji
<wplyw-mechanizmu-uwagi-i-kwantyzacji>

Wyniki eksperymentu E1 zestawiono w @tab:e1[tabeli], a zmiany względem konfiguracji odniesienia w @tab:e1-delty[tabeli]. Wszystkie konfiguracje zmierzono przy kaflu 192 $times$ 192 i rozdzielczości wejściowej 192 $times$ 352, dla 101 klatek.

#figure(
  kind: table,
  caption: flex-caption(
    [Czas inferencji i szczytowe zużycie pamięci dla dwunastu kombinacji mechanizmu uwagi i trybu kwantyzacji (wejście 192 $times$ 352, kafel 192, 101 klatek)],
    [Czas inferencji i szczytowe zużycie pamięci dla dwunastu kombinacji mechanizmu uwagi i trybu kwantyzacji],
  ),
  [
    #set text(size: 8.5pt)
    #show table.cell.where(y: 0): strong

    #table(
      columns: (auto, auto, auto, auto, auto, auto),
      align: (left, left, left, right, right, right),
      stroke: 0.5pt + luma(150),
      fill: (col, row) => if row == 0 { luma(230) } else { none },
      table.header([Jądro gęste], [Selekcja rzadka], [Kwantyzacja], [Czas \[s\]], [s/klatkę], [Szczyt \[MiB\]]),

      [SDPA], [Block Sparse Attention], [brak], [26,89], [0,266], [9 110],
      [SDPA], [Block Sparse Attention], [INT8 wag], [27,87], [0,276], [8 780],
      [SDPA], [Block Sparse Attention], [INT8 wag i akt.], [34,84], [0,345], [8 212],
      [SageAttention], [Block Sparse Attention], [brak], [27,34], [0,271], [9 292],
      [SageAttention], [Block Sparse Attention], [INT8 wag], [28,15], [0,279], [8 764],
      [SageAttention], [Block Sparse Attention], [INT8 wag i akt.], [35,15], [0,348], [8 240],
      [SDPA], [SpargeAttention], [brak], [23,43], [0,232], [9 286],
      [SDPA], [SpargeAttention], [INT8 wag], [24,22], [0,240], [8 766],
      [SDPA], [SpargeAttention], [INT8 wag i akt.], [31,12], [0,308], [8 112],
      [SageAttention], [SpargeAttention], [brak], [23,59], [0,234], [9 294],
      [SageAttention], [SpargeAttention], [INT8 wag], [24,35], [0,241], [8 766],
      [SageAttention], [SpargeAttention], [INT8 wag i akt.], [31,29], [0,310], [8 112],
    )],
) <tab:e1>


#figure(
  kind: table,
  caption: [Zmiany względem konfiguracji odniesienia],
  [
    #set text(size: 8.5pt)
    #show table.cell.where(y: 0): strong

    #table(
      columns: (auto, auto, auto, auto),
      align: (left, right, right, right),
      stroke: 0.5pt + luma(150),
      fill: (col, row) => if row == 0 { luma(230) } else { none },
      table.header([Konfiguracja], [Czas (wzgl.)], [Pamięć], [Pamięć (wzgl.)]),

      [SDPA / Block Sparse Attention / brak], [0,0%], [0 MiB], [0,0%],
      [SDPA / Block Sparse Attention / INT8 wag], [+3,6%], [-330 MiB], [-3,6%],
      [SDPA / Block Sparse Attention / INT8 wag i akt.], [+29,6%], [-898 MiB], [-9,9%],
      [SageAttention / Block Sparse Attention / brak], [+1,7%], [+182 MiB], [+2,0%],
      [SageAttention / Block Sparse Attention / INT8 wag], [+4,7%], [-346 MiB], [-3,8%],
      [SageAttention / Block Sparse Attention / INT8 wag i akt.], [+30,7%], [-870 MiB], [-9,5%],
      [SDPA / SpargeAttention / brak], [-12,9%], [+176 MiB], [+1,9%],
      [SDPA / SpargeAttention / INT8 wag], [*-9,9%*], [*-344 MiB*], [-3,8%],
      [SDPA / SpargeAttention / INT8 wag i akt.], [+15,7%], [-998 MiB], [-11,0%],
      [SageAttention / SpargeAttention / brak], [-12,3%], [+184 MiB], [+2,0%],
      [SageAttention / SpargeAttention / INT8 wag], [*-9,4%*], [*-344 MiB*], [-3,8%],
      [SageAttention / SpargeAttention / INT8 wag i akt.], [+16,4%], [-998 MiB], [-11,0%],
    )],
) <tab:e1-delty>


Zestawienie pozwala rozdzielić wpływ trzech osi optymalizacji, ponieważ każda z nich zmienia inną wielkość.

Podmiana jądra uwagi gęstej nie przynosi korzyści. Zastąpienie mechanizmu SDPA biblioteką _SageAttention_ wydłuża czas o 1,7% przy _Block Sparse Attention_ i o 0,7% przy _SpargeAttention_, a szczytowe zużycie pamięci podnosi o około 180 MiB. Wynik ten jest niezgodny z oczekiwaniem sformułowanym w @tab:zestawienie-technik[tabeli]. Możliwym wyjaśnieniem jest niewielki udział wywołań bez maski blokowej w całkowitym koszcie obliczeń. Jeżeli w badanym modelu przeważają wywołania z maską, obsługiwane przez ścieżkę rzadką, to przyspieszenie ścieżki gęstej dotyczy niewielkiej części pracy, a narzut kwantyzacji macierzy $Q$ i $K$, wykonywanej przy każdym wywołaniu, nie zostaje zamortyzowany.

Podmiana selekcji rzadkiej skraca czas. Zastąpienie uwagi blokowo-rzadkiej autorów modelu biblioteką _SpargeAttention_ skraca czas inferencji o 12,9% przy niezmienionym trybie kwantyzacji, kosztem wzrostu szczytu pamięci o około 176 MiB. Jest to jedyne z badanych rozwiązań, które faktycznie przyspiesza przetwarzanie. Skrócenie czasu wynika prawdopodobnie z pomijania części obliczeń przez filtr opisany w @spargeattention[podrozdziale]. Pomiar nie pozwala jednak stwierdzić, jaki jest udział samej selekcji, a jaki kwantyzacji macierzy $Q$ i $K$, którą _SpargeAttention_ dziedziczy po _SageAttention_. Nie wiadomo też, czy metoda ta pomija więcej obliczeń niż metoda autorów modelu. Za tą drugą możliwością przemawia obserwacja z @jakosc-rekonstrukcji-wyniki[podrozdziału]. Podmiana selekcji rzadkiej jest tam jedyną zmianą o zauważalnym wpływie na jakość.

Kwantyzacja obniża zużycie pamięci i wydłuża czas. Kwantyzacja samych wag zmniejsza szczyt o 330 MiB i wydłuża czas o 3,6%. Objęcie kwantyzacją również aktywacji zmniejsza szczyt o 898 MiB, czyli blisko trzykrotnie więcej, ale wydłuża czas o 29,6%. Wynika to z dodatkowych operacji wykonywanych w tym wariancie. Parametry mapowania aktywacji wyznaczane są przy każdym wywołaniu, a wokół każdego mnożenia macierzowego dochodzą kwantyzacja i dekwantyzacja.

Efekty tych osi łączą się. Najniższy szczyt w całym zestawieniu, 8112 MiB, osiąga konfiguracja łącząca _SpargeAttention_ z kwantyzacją wag i aktywacji. Jest to o 11,0% mniej niż w konfiguracji odniesienia, przy czasie dłuższym o 15,7%. Na uwagę zasługuje jednak inna konfiguracja. _SpargeAttention_ z kwantyzacją samych wag daje szczyt 8766 MiB i czas 24,22 s. Jest więc jednocześnie oszczędniejsza pamięciowo i o 9,9% szybsza od konfiguracji wyjściowej. To jedyny badany wariant poprawiający obie mierzone wielkości naraz.

== Wpływ rozmiaru kafla
<wplyw-rozmiaru-kafla>

Wyniki eksperymentu E2 zestawiono w @tab:e2[tabeli]. Pomiary wykonano przy rozdzielczości wejściowej 256 $times$ 448 i zakładce 24 pikseli. Kolumna redundancji podaje stosunek łącznej powierzchni przetworzonych kafli do powierzchni klatki.

#figure(
  kind: table,
  caption: flex-caption(
    [Czas inferencji i szczytowe zużycie pamięci w funkcji rozmiaru kafla (wejście 256 $times$ 448, zakładka 24)],
    [Czas inferencji i szczytowe zużycie pamięci w funkcji rozmiaru kafla],
  ),
  [
    #set text(size: 8.5pt)
    #show table.cell.where(y: 0): strong

    #table(
      columns: (auto, auto, auto, auto, auto, auto, auto),
      align: (right, right, right, right, right, right, right),
      stroke: 0.5pt + luma(150),
      fill: (col, row) => if row == 0 { luma(230) } else { none },
      table.header(
        [Rozmiar kafla], [Liczba kafli], [Redundancja], [Czas \[s\]], [s/klatkę], [Czas/kafel \[s\]], [Szczyt \[MiB\]]
      ),

      [128], [15], [2,14], [81,32], [0,805], [5,42], [6 472],
      [160], [8], [1,79], [72,78], [0,721], [9,10], [7 386],
      [192], [6], [1,93], [81,62], [0,808], [13,60], [9 292],
      [224], [6], [2,62], [przepełnienie], [—], [—], [—],
      [256], [2], [1,14], [przepełnienie], [—], [—], [—],
    )],
) <tab:e2>


Szczytowe zużycie pamięci rośnie monotonicznie wraz z rozmiarem kafla, zgodnie z założeniem przyjętym w @ograniczenie-rozmiaru-przetwarzanego-fragmentu[podrozdziale]. Czas inferencji zachowuje się natomiast niemonotonicznie. Kafel 160 daje wynik 72,8 s, natomiast kafle 128 i 192 dają odpowiednio 81,3 s i 81,6 s.

Na czas wpływają dwa czynniki o zbliżonej wadze. Pierwszym jest redundancja obliczeń w obszarach zakładek, wynosząca 2,14 dla kafla 128, 1,79 dla kafla 160 i 1,93 dla kafla 192. Drugim jest koszt jednostkowy, rosnący wraz z powierzchnią kafla od $3","31 dot 10^(-4)$ s na piksel dla kafla 128 do $3","69 dot 10^(-4)$ s dla kafla 192. Czynniki te przy kaflach 128 i 192 niemal dokładnie się znoszą: pierwszy przetwarza 1,11 raza większą powierzchnię, lecz kosztuje o 10% mniej na piksel.

Redundancja nie zmienia się monotonicznie wraz z rozmiarem kafla, lecz zależy od tego, jak siatka kafli dzieli klatkę. Gdy kafel nie mieści się w klatce, jego początek przesuwany jest wstecz, zgodnie z mechanizmem opisanym w @kafelkowanie-przestrzenne[podrozdziale], co przy rozmiarach źle dopasowanych do jej wymiarów prowadzi do bardzo szerokich zakładek. Widać to na przykładzie kafla 224, który daje tę samą liczbę kafli co kafel 192, przy większej powierzchni każdego z nich, przez co jego redundancja sięga 2,62.

Dobór rozmiaru kafla wymaga zatem uwzględnienia obu czynników, przy czym redundancję można wyznaczyć z samej geometrii podziału, bez uruchamiania modelu. Uzyskane wartości odnoszą się przy tym wyłącznie do rozdzielczości 256 $times$ 448 i przy innej rozdzielczości korzystniejszy może być inny rozmiar.

== Granica wykonalności
<granica-wykonalnosci>

Konfiguracja bazowa kończy się na karcie docelowej przepełnieniem pamięci przy rozdzielczości 192 $times$ 352 oraz 256 $times$ 448. W obu przypadkach awaria następuje w pierwszym kroku odszumiania, w funkcji aktywacji wewnątrz bloku transformera. Modelu w postaci udostępnionej przez autorów nie da się zatem uruchomić na karcie konsumenckiej nawet w scenariuszu, dla którego autorzy podają wyniki wydajnościowe.

Skalę zapotrzebowania określono na akceleratorze A100, gdzie obie konfiguracje wykonują się poprawnie. Wyniki zestawiono w @tab:referencja[tabeli].

#figure(
  kind: table,
  caption: flex-caption(
    [Zapotrzebowanie konfiguracji bazowej, zmierzone na akceleratorze A100],
    [Zapotrzebowanie konfiguracji bazowej],
  ),
  [
    #set text(size: 8.5pt)
    #show table.cell.where(y: 0): strong

    #table(
      columns: (auto, auto, auto, auto),
      align: (right, right, right, right),
      stroke: 0.5pt + luma(150),
      fill: (col, row) => if row == 0 { luma(230) } else { none },
      table.header([Wejście], [Szczyt \[MiB\]], [Czas \[s\]], [Krotność pojemności RTX 3080]),

      [192 $times$ 352], [14 844], [9,21], [1,50$times$],
      [256 $times$ 448], [23 512], [13,92], [2,38$times$],
    )],
) <tab:referencja>


Pomiary na akceleratorze A100 pozwalają określić skalę deficytu. Przy rozdzielczości wskazanej przez autorów zapotrzebowanie wynosi 14 844 MiB, przy rozdzielczości bliższej typowym nagraniom rośnie do 23 512 MiB. Wartości te przekraczają pojemność karty docelowej odpowiednio około półtorakrotnie i blisko dwuipółkrotnie. Deficyt jest zatem na tyle duży, że nie dałoby się go pokryć samą kwantyzacją ani optymalizacją mechanizmu uwagi, których łączny efekt zmierzony w eksperymencie E1 nie przekracza 11%.

Zmierzona wartość 14 844 MiB jest wyższa od 11,13 GB raportowanych przez autorów dla tej samej rozdzielczości. Rozbieżność wynika najpewniej z przyjętej miary zużycia pamięci, omówionej w @wydajnosc[podrozdziale]. Przyjęta tu miara jest ostrożniejsza, ponieważ o wystąpieniu przepełnienia decyduje rozmiar puli zarezerwowanej.

Kafelkowanie przestrzenne uniezależnia szczytowe zużycie pamięci od rozdzielczości nagrania. Potwierdzają to wyniki eksperymentów E1 i E2. Przy kaflu 192 $times$ 192 szczyt wynosi 9110 MiB dla wejścia 192 $times$ 352 i 9292 MiB dla wejścia 256 $times$ 448, mimo że powierzchnia klatki rośnie o 70%. Różnica mieści się w rozrzucie obserwowanym między powtórzeniami tej samej konfiguracji. Dla porównania, ta sama zmiana rozdzielczości podnosi szczyt konfiguracji bazowej o 8668 MiB (@tab:referencja[tabela]).

Same techniki obliczeniowe przesuwają natomiast granicę wykonalności o jeden krok siatki rozmiarów kafla, co przedstawiono w @tab:granica[tabeli].

#figure(
  kind: table,
  caption: flex-caption(
    [Przesunięcie granicy wykonalności: rozmiar kafla niewykonalny w konfiguracji odniesienia staje się wykonalny po zastosowaniu badanych technik (wejście 256 $times$ 448, 101 klatek)],
    [Przesunięcie granicy wykonalności],
  ),
  [
    #set text(size: 8.5pt)
    #show table.cell.where(y: 0): strong

    #table(
      columns: (auto, auto, auto, auto, auto),
      align: (left, right, left, right, right),
      stroke: 0.5pt + luma(150),
      fill: (col, row) => if row == 0 { luma(230) } else { none },
      table.header([Konfiguracja], [Kafel], [Wynik], [Czas \[s\]], [Szczyt \[MiB\]]),

      [odniesienia], [192], [wykonalna], [81,62], [9 292],
      [odniesienia], [224], [przepełnienie], [—], [—],
      [SageAttention / SpargeAttention / INT8 wag i akt.], [224], [wykonalna], [132,80], [8 920],
    )],
) <tab:granica>

W konfiguracji odniesienia kafel 224 kończy się przepełnieniem pamięci. Ten sam kafel po zastosowaniu _SpargeAttention_ oraz kwantyzacji wag i aktywacji przetwarzany jest ze szczytem 8920 MiB, a więc z wyraźnym zapasem względem konfiguracji, przy której nastąpiło przepełnienie.

== Jakość rekonstrukcji
<jakosc-rekonstrukcji-wyniki>

Wyniki eksperymentu E3 dla zbioru YouHQ40 zestawiono w @tab:jakosc-youhq40[tabeli]. Kolejne wiersze odpowiadają konfiguracjom łańcucha przyrostowego opisanego w @plan-eksperymentow[podrozdziale], w którym każda różni się od poprzedniej jedną zmianą. Zmiany metryk między kolejnymi konfiguracjami przedstawiono w @tab:jakosc-youhq40-delty[tabeli].

#figure(
  kind: table,
  caption: flex-caption(
    [Metryki jakości dla zbioru YouHQ40, wartości uśrednione po klipach],
    [Metryki jakości dla zbioru YouHQ40],
  ),
  [
    #set text(size: 8.5pt)
    #show table.cell.where(y: 0): strong

    #table(
      columns: (auto, auto, auto, auto, auto, auto, auto, auto),
      align: (left, right, right, right, right, right, right, right),
      stroke: 0.5pt + luma(150),
      fill: (col, row) => if row == 0 { luma(230) } else { none },
      table.header(
        [Konfiguracja],
        [PSNR#sym.arrow.t],
        [SSIM#sym.arrow.t],
        [LPIPS#sym.arrow.b],
        [NIQE#sym.arrow.b],
        [MUSIQ#sym.arrow.t],
        [CLIPIQA#sym.arrow.t],
        [DOVER#sym.arrow.t],
      ),

      [bazowa], [21,79], [0,591], [0,393], [4,245], [60,78], [0,486], [12,52],
      [\+ kafelkowanie 192], [21,54], [0,599], [0,410], [4,149], [59,42], [0,443], [11,78],
      [\+ SageAttention], [21,54], [0,599], [0,410], [4,149], [59,41], [0,444], [11,66],
      [\+ SpargeAttention], [21,55], [0,599], [0,411], [4,167], [58,94], [0,442], [11,63],
      [\+ INT8 wag i aktywacji], [21,54], [0,599], [0,410], [4,157], [58,97], [0,440], [11,60],
    )],
) <tab:jakosc-youhq40>


#figure(
  kind: table,
  caption: [Zmiana metryk względem konfiguracji poprzedniej, zbiór YouHQ40],
  [
    #set text(size: 8.5pt)
    #show table.cell.where(y: 0): strong

    #table(
      columns: (auto, auto, auto, auto, auto, auto, auto, auto),
      align: (left, right, right, right, right, right, right, right),
      stroke: 0.5pt + luma(150),
      fill: (col, row) => if row == 0 { luma(230) } else { none },
      table.header(
        [Konfiguracja],
        [PSNR#sym.arrow.t],
        [SSIM#sym.arrow.t],
        [LPIPS#sym.arrow.b],
        [NIQE#sym.arrow.b],
        [MUSIQ#sym.arrow.t],
        [CLIPIQA#sym.arrow.t],
        [DOVER#sym.arrow.t],
      ),

      [\+ kafelkowanie 192], [-0,25], [+0,008], [+0,016], [-0,096], [-1,36], [-0,043], [-0,73],
      [\+ SageAttention], [0,00], [0,000], [0,000], [0,000], [-0,01], [0,000], [-0,12],
      [\+ SpargeAttention], [+0,01], [0,000], [+0,001], [+0,018], [-0,47], [-0,001], [-0,03],
      [\+ INT8 wag i aktywacji], [-0,01], [0,000], [0,000], [-0,009], [+0,03], [-0,002], [-0,03],
    )],
) <tab:jakosc-youhq40-delty>

Utrata jakości przypada niemal wyłącznie na wprowadzenie kafelkowania przestrzennego. Trzy kolejne podmiany, obejmujące jądro uwagi gęstej, selekcję rzadką oraz kwantyzację wag i aktywacji, zmieniają metryki nieznacznie. Wyjątkiem jest spadek MUSIQ o 0,47 przy _SpargeAttention_, wyraźny na tle pozostałych podmian, choć blisko trzykrotnie mniejszy od spadku spowodowanego kafelkowaniem.

Badane optymalizacje obliczeniowe są zatem w przybliżeniu neutralne jakościowo, a kompromis między jakością a zużyciem pamięci sprowadza się do decyzji o podziale klatki na kafle. W szczególności kwantyzacja wag i aktywacji, redukująca szczyt zużycia pamięci o blisko 1 GiB, nie pogarsza rekonstrukcji w stopniu mierzalnym przyjętym zestawem metryk.

Wpływ rozmiaru kafla przedstawiono w @tab:jakosc-youhq40-kafle[tabeli]. Pozostałe parametry odpowiadają w tych konfiguracjach drugiemu wierszowi @tab:jakosc-youhq40[tabeli], zmieniany jest wyłącznie rozmiar kafla.

#figure(
  kind: table,
  caption: [Metryki jakości dla różnych rozmiarów kafla, zbiór YouHQ40.],
  [
    #set text(size: 8.5pt)
    #show table.cell.where(y: 0): strong

    #table(
      columns: (auto, auto, auto, auto, auto, auto, auto, auto),
      align: (left, right, right, right, right, right, right, right),
      stroke: 0.5pt + luma(150),
      fill: (col, row) => if row == 0 { luma(230) } else { none },
      table.header(
        [Konfiguracja],
        [PSNR#sym.arrow.t],
        [SSIM#sym.arrow.t],
        [LPIPS#sym.arrow.b],
        [NIQE#sym.arrow.b],
        [MUSIQ#sym.arrow.t],
        [CLIPIQA#sym.arrow.t],
        [DOVER#sym.arrow.t],
      ),

      [kafelkowanie 192], [21,54], [0,599], [0,410], [4,149], [59,42], [0,443], [11,78],
      [kafelkowanie 160], [21,47], [0,594], [0,415], [4,092], [60,46], [0,468], [12,18],
      [kafelkowanie 128], [21,49], [0,592], [0,427], [4,122], [59,78], [0,474], [11,17],
    )],
) <tab:jakosc-youhq40-kafle>

Porównanie nie daje jednoznacznego uporządkowania. Kafel 192 wypada najlepiej we wszystkich trzech metrykach pełnoreferencyjnych, natomiast kafle mniejsze osiągają lepsze wyniki metryk bezreferencyjnych: NIQE i MUSIQ są najkorzystniejsze dla kafla 160, a CLIPIQA dla kafla 128.

Wyniki dla zbioru VideoLQ, zawierającego nagrania o degradacjach rzeczywistych, zestawiono w @tab:jakosc-videolq[tabeli], a zmiany między kolejnymi konfiguracjami w @tab:jakosc-videolq-delty[tabeli].

#figure(
  kind: table,
  caption: flex-caption(
    [Metryki bezreferencyjne dla zbioru VideoLQ, wartości uśrednione po klipach],
    [Metryki bezreferencyjne dla zbioru VideoLQ],
  ),
  [
    #set text(size: 8.5pt)
    #show table.cell.where(y: 0): strong

    #table(
      columns: (auto, auto, auto, auto, auto),
      align: (left, right, right, right, right),
      stroke: 0.5pt + luma(150),
      fill: (col, row) => if row == 0 { luma(230) } else { none },
      table.header([Konfiguracja], [NIQE#sym.arrow.b], [MUSIQ#sym.arrow.t], [CLIPIQA#sym.arrow.t], [DOVER#sym.arrow.t]),

      [bazowa], [3,937], [52,02], [0,402], [8,02],
      [\+ kafelkowanie 192], [3,870], [50,93], [0,391], [7,86],
      [\+ SageAttention], [3,869], [50,94], [0,391], [7,91],
      [\+ SpargeAttention], [3,865], [50,91], [0,393], [7,87],
      [\+ INT8 wag i aktywacji], [3,881], [50,90], [0,392], [7,84],
    )],
) <tab:jakosc-videolq>

#figure(
  kind: table,
  caption: [Zmiana metryk względem konfiguracji poprzedniej, zbiór VideoLQ],
  [
    #set text(size: 8.5pt)
    #show table.cell.where(y: 0): strong

    #table(
      columns: (auto, auto, auto, auto, auto),
      align: (left, right, right, right, right),
      stroke: 0.5pt + luma(150),
      fill: (col, row) => if row == 0 { luma(230) } else { none },
      table.header([Konfiguracja], [NIQE#sym.arrow.b], [MUSIQ#sym.arrow.t], [CLIPIQA#sym.arrow.t], [DOVER#sym.arrow.t]),

      [\+ kafelkowanie 192], [-0,067], [-1,09], [-0,011], [-0,16],
      [\+ SageAttention], [0,000], [+0,01], [0,000], [+0,05],
      [\+ SpargeAttention], [-0,004], [-0,04], [+0,002], [-0,04],
      [\+ INT8 wag i aktywacji], [+0,015], [-0,01], [-0,001], [-0,02],
    )],
) <tab:jakosc-videolq-delty>

Wyniki eksperymentu przeprowadzonego na zbiorze VideoLQ potwierdzają zaobserwowaną zależność. Na wprowadzenie kafelkowania przypada zdecydowana większość zmiany każdej z metryk. Wniosek o neutralności jakościowej optymalizacji obliczeniowych przenosi się zatem na nagrania rzeczywiste.

// Porównanie wizualne dla dwóch klipów o odmiennym charakterze treści przedstawiono na rysunkach @rys:jakosc-porownanie-ptak[] i @rys:jakosc-porownanie-targ[]. Kolumny przedstawiają materiał wejściowy oraz trzy wybrane konfiguracje z @tab:jakosc-videolq[tabeli]: bazową, bazową z kafelkowaniem oraz konfigurację ze wszystkimi optymalizacjami. W obu przykładach wyniki pozostają nierozróżnialne, co potwierdza wniosek o neutralności jakościowej optymalizacji obliczeniowych.

// #figure(
//   image("../images/porownanie_006.svg", width: 100%),
//   caption: [Porównanie jakościowe dla zbioru VideoLQ, klip 6, klatka 13.],
// ) <rys:jakosc-porownanie-ptak>
// #figure(
//   image("../images/porownanie_008.svg", width: 100%),
//   caption: [Porównanie jakościowe dla zbioru VideoLQ, klip 8, klatka 0.],
// ) <rys:jakosc-porownanie-targ>

== Porównanie wizualne
<porownanie-wizualne>

Zestawienia liczbowe uzupełniono o porównania wizualne, osobno dla obu zbiorów testowych. Dla każdego z nich przedstawiono zbliżenia wybranych fragmentów klatki dla kolejnych konfiguracji łańcucha przyrostowego, co pozwala ocenić, czy różnice raportowane przez metryki są dostrzegalne.

Zbiór YouHQ40 zawiera materiał referencyjny, więc porównania obejmują również klatkę wzorcową. Zbliżenia dla dwóch klipów przedstawiono na rysunkach @rys:jakosc-porownanie-youhq-a[] i @rys:jakosc-porownanie-youhq-b[]. Kolumny przedstawiają materiał wejściowy, materiał referencyjny oraz dwie wybrane konfiguracje z @tab:jakosc-youhq40[tabeli]: bazową oraz konfigurację ze wszystkimi optymalizacjami.

#figure(
  image("../images/porownanie_009_youhq.svg"),
  caption: flex-caption(
    [Porównanie jakościowe dla zbioru YouHQ40, klip A, klatka N. Kolumny: materiał wejściowy, konfiguracja bazowa, konfiguracja ze wszystkimi optymalizacjami oraz materiał referencyjny],
    [Porównanie jakościowe dla zbioru YouHQ40, klip A],
  ),
) <rys:jakosc-porownanie-youhq-a>

#figure(
  image("../images/porownanie_019_youhq.svg"),
  caption: flex-caption(
    [Porównanie jakościowe dla zbioru YouHQ40, klip B, klatka N. Układ kolumn jak na @rys:jakosc-porownanie-youhq-a[rysunku]],
    [Porównanie jakościowe dla zbioru YouHQ40, klip B],
  ),
) <rys:jakosc-porownanie-youhq-b>

#pagebreak()
Pełne klatki dla dwóch klipów, wraz z odpowiadającym im materiałem referencyjnym, przedstawiono na @rys:klatki-youhq[rysunku]. Wynik wygenerowano w konfiguracji odpowiadającej ostatniej w łańcuchu przyrostowym.

#figure(
  image("../images/pelne_klatki_youhq.svg", width: 100%),
  caption: flex-caption(
    [Pełne klatki dla zbioru YouHQ40. Kolumny odpowiadają dwóm klipom (klip 0, klatka 5; klip 1, klatka 0), wiersze kolejno materiałowi wejściowemu, wynikowi modelu oraz materiałowi referencyjnemu],
    [Pełne klatki dla zbioru YouHQ40],
  ),
) <rys:klatki-youhq>

Zbiór VideoLQ nie zawiera materiału referencyjnego, więc porównania ograniczają się do zestawienia konfiguracji. Zbliżenia dla dwóch klipów o odmiennym charakterze treści przedstawiono na rysunkach @rys:jakosc-porownanie-ptak[] i @rys:jakosc-porownanie-targ[]. Kolumny przedstawiają materiał wejściowy oraz trzy wybrane konfiguracje z @tab:jakosc-videolq[tabeli]: bazową, bazową z kafelkowaniem oraz konfigurację ze wszystkimi optymalizacjami.

#figure(
  image("../images/porownanie_006_videolq.svg", width: 100%),
  caption: flex-caption(
    [Porównanie jakościowe dla zbioru VideoLQ, klip 6, klatka 13. Kolumny: materiał wejściowy, konfiguracja bazowa, konfiguracja bazowa z kafelkowaniem, konfiguracja ze wszystkimi optymalizacjami],
    [Porównanie jakościowe dla zbioru VideoLQ, klip 6, klatka 13.],
  ),
) <rys:jakosc-porownanie-ptak>

#figure(
  image("../images/porownanie_008_videolq.svg", width: 100%),
  caption: flex-caption(
    [Porównanie jakościowe dla zbioru VideoLQ, klip 8, klatka 0. Układ kolumn jak na @rys:jakosc-porownanie-ptak[rysunku]],
    [Porównanie jakościowe dla zbioru VideoLQ, klip 8, klatka 0.],
  ),
) <rys:jakosc-porownanie-targ>

#pagebreak()
Pełne klatki dla trzech klipów przedstawiono na @rys:klatki-videolq[rysunku]. Wynik wygenerowano w tej samej konfiguracji co dla zbioru YouHQ40.

#figure(
  image("../images/pelne_klatki_videolq.svg", width: 100%),
  caption: flex-caption(
    [Pełne klatki dla zbioru VideoLQ. Kolejne wiersze przedstawiają trzy klipy (klip 11, klatka 0; klip 12, klatka 0; klip 5, klatka 0), kolumny odpowiadają materiałowi wejściowemu oraz wynikowi modelu],
    [Pełne klatki dla zbioru VideoLQ],
  ),
) <rys:klatki-videolq>

Porównania potwierdzają wnioski wyciągnięte z metryk: badane konfiguracje dają niemal nierozróżnialne wyniki, w obu zbiorach i niezależnie od charakteru treści. Zestawienie z materiałem referencyjnym wypada natomiast inaczej. Model nie odtwarza wiernie klatki wzorcowej, lecz uzupełnia utracone detale wiarygodnymi, choć odmiennymi strukturami, co jest najlepiej widoczne w drobnych teksturach. Wynika to z niejednoznaczności zadania superrozdzielczości omówionej w @sformułowanie-problemu[podrozdziale] i jest właściwością samego modelu bazowego, a nie skutkiem wprowadzonych optymalizacji.

== Podsumowanie wyników
<podsumowanie-wynikow>

Trzy badane osie optymalizacji okazały się pełnić odmienne role. Kafelkowanie przestrzenne jako jedyne uniezależnia szczytowe zużycie pamięci od rozdzielczości nagrania oraz ponosi cały mierzalny koszt jakościowy. Selekcja rzadka oddziałuje przede wszystkim na czas inferencji, skracając go o blisko 13% przy niemal niezmienionych metrykach. Kwantyzacja oddziałuje na pamięć, obniżając szczyt o 898 MiB w wariancie obejmującym aktywacje. Kafelkowanie decyduje więc o wykonalności, a pozostałe dwie osie o kompromisie między czasem a zapasem pamięci w konfiguracji już wykonalnej.
