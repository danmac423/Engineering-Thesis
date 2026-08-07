#import "../utils.typ": flex-caption, silentheading, todo

= Wyniki i ich omówienie

== Wpływ mechanizmu uwagi i kwantyzacji

Wyniki eksperymentu E1 zestawiono w @tab:e1[tabeli], a zmiany względem konfiguracji
odniesienia w @tab:e1-delty[tabeli]. Wszystkie konfiguracje zmierzono przy kaflu
192 $times$ 192 i rozdzielczości wejściowej 192 $times$ 352, dla 101 klatek.

#figure(
  kind: table,
  caption: [Czas inferencji i szczytowe zużycie pamięci dla dwunastu kombinacji mechanizmu uwagi i trybu kwantyzacji (wejście 192 $times$ 352, kafel 192, 101 klatek)],
  [
    #set text(size: 8.5pt)
    #show table.cell.where(y: 0): strong

    #table(
      columns: (auto, auto, auto, auto, auto, auto),
      align: (left, left, left, right, right, right),
      stroke: 0.5pt + luma(150),
      fill: (col, row) => if row == 0 { luma(230) } else { none },
      table.header([Jądro gęste], [Selekcja rzadka], [Kwantyzacja], [Czas \[s\]], [s/klatkę], [Szczyt \[MiB\]]),

      [SDPA], [blokowo-rzadka], [brak], [26,9], [0,266], [9 110],
      [SDPA], [blokowo-rzadka], [INT8 wag], [27,9], [0,276], [8 780],
      [SDPA], [blokowo-rzadka], [INT8 wag i akt.], [34,8], [0,345], [8 212],
      [SageAttention], [blokowo-rzadka], [brak], [27,3], [0,271], [9 292],
      [SageAttention], [blokowo-rzadka], [INT8 wag], [28,2], [0,279], [8 764],
      [SageAttention], [blokowo-rzadka], [INT8 wag i akt.], [35,2], [0,348], [8 240],
      [SDPA], [SpargeAttention], [brak], [23,4], [0,232], [9 286],
      [SDPA], [SpargeAttention], [INT8 wag], [24,2], [0,240], [8 766],
      [SDPA], [SpargeAttention], [INT8 wag i akt.], [31,1], [0,308], [8 112],
      [SageAttention], [SpargeAttention], [brak], [23,6], [0,234], [9 294],
      [SageAttention], [SpargeAttention], [INT8 wag], [24,4], [0,241], [8 766],
      [SageAttention], [SpargeAttention], [INT8 wag i akt.], [31,3], [0,310], [8 112],
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
      table.header([Konfiguracja], [Czas], [Pamięć], [Pamięć (wzgl.)]),

      [SDPA / blokowo-rzadka / brak], [+0,0%], [+0 MiB], [+0,0%],
      [SDPA / blokowo-rzadka / INT8 wag], [+3,6%], [−330 MiB], [−3,6%],
      [SDPA / blokowo-rzadka / INT8 wag i akt.], [+29,6%], [−898 MiB], [−9,9%],
      [SageAttention / blokowo-rzadka / brak], [+1,7%], [+182 MiB], [+2,0%],
      [SageAttention / blokowo-rzadka / INT8 wag], [+4,7%], [−346 MiB], [−3,8%],
      [SageAttention / blokowo-rzadka / INT8 wag i akt.], [+30,7%], [−870 MiB], [−9,5%],
      [SDPA / SpargeAttention / brak], [−12,9%], [+176 MiB], [+1,9%],
      [SDPA / SpargeAttention / INT8 wag], [−9,9%], [−344 MiB], [−3,8%],
      [SDPA / SpargeAttention / INT8 wag i akt.], [+15,7%], [−998 MiB], [−11,0%],
      [SageAttention / SpargeAttention / brak], [−12,3%], [+184 MiB], [+2,0%],
      [SageAttention / SpargeAttention / INT8 wag], [−9,4%], [−344 MiB], [−3,8%],
      [SageAttention / SpargeAttention / INT8 wag i akt.], [+16,4%], [−998 MiB], [−11,0%],
    )],
) <tab:e1-delty>


Zestawienie pozwala rozdzielić wpływ trzech osi optymalizacji, ponieważ każda
z nich zmienia inną wielkość.

*Podmiana jądra uwagi gęstej nie przynosi korzyści.* Zastąpienie mechanizmu SDPA
biblioteką SageAttention wydłuża czas o 1,7% przy selekcji blokowo-rzadkiej
i o 0,9% przy SpargeAttention, a szczytowe zużycie pamięci podnosi o około
180 MiB. Wynik ten jest niezgodny z oczekiwaniem sformułowanym w @tab:zestawienie-technik[tabeli].
Możliwym wyjaśnieniem jest niewielki udział wywołań bez maski blokowej
w całkowitym koszcie obliczeń. Jeżeli w badanym modelu przeważają wywołania
z maską, obsługiwane przez ścieżkę rzadką, to przyspieszenie ścieżki gęstej
dotyczy niewielkiej części pracy, a narzut kwantyzacji macierzy $Q$ i $K$,
wykonywanej przy każdym wywołaniu, nie zostaje zamortyzowany.

*Podmiana selekcji rzadkiej skraca czas.* Zastąpienie uwagi blokowo-rzadkiej
autorów modelu biblioteką SpargeAttention skraca czas inferencji o 12,9% przy
niezmienionym trybie kwantyzacji, kosztem wzrostu szczytu pamięci o około
176 MiB. Jest to jedyne z badanych rozwiązań, które faktycznie przyspiesza
przetwarzanie. Skrócenie czasu wynika prawdopodobnie z pomijania
części obliczeń przez filtr opisany w @spargeattention[podrozdziale]. Pomiar nie
pozwala jednak stwierdzić, jaki jest udział samej selekcji, a jaki kwantyzacji
macierzy $Q$ i $K$, którą SpargeAttention dziedziczy po SageAttention. Nie
wiadomo też, czy metoda ta pomija więcej obliczeń niż metoda autorów modelu. Za
tą drugą możliwością przemawia obserwacja z @jakosc-rekonstrukcji[podrozdziału].
Podmiana selekcji rzadkiej jest tam jedyną zmianą o zauważalnym wpływie na
jakość.

*Kwantyzacja obniża zużycie pamięci i wydłuża czas.* Kwantyzacja samych wag
zmniejsza szczyt o 330 MiB i wydłuża czas o 3,6%. Objęcie kwantyzacją również
aktywacji zmniejsza szczyt o 898 MiB, czyli blisko trzykrotnie więcej, ale
wydłuża czas o 29,6%. Wynika to z dodatkowych operacji wykonywanych w tym
wariancie. Parametry mapowania aktywacji wyznaczane są przy każdym wywołaniu,
a wokół każdego mnożenia macierzowego dochodzą kwantyzacja i dekwantyzacja.

Efekty tych osi sumują się. Najniższy szczyt w całym zestawieniu, 8112 MiB,
osiąga konfiguracja łącząca SpargeAttention z kwantyzacją wag i aktywacji. Jest
to o 11,0% mniej niż w konfiguracji odniesienia, przy czasie dłuższym o 15,7%.
Na uwagę zasługuje jednak inna konfiguracja. SpargeAttention z kwantyzacją
samych wag daje szczyt 8766 MiB i czas 24,2 s. Jest więc jednocześnie
oszczędniejsza pamięciowo i o 9,9% szybsza od konfiguracji wyjściowej. To jedyny
badany wariant poprawiający obie mierzone wielkości naraz.

Warto też spojrzeć na obie wielkości łącznie. Dla trzech konfiguracji ze
SpargeAttention nie istnieje żadna inna, która byłaby jednocześnie szybsza
i oszczędniejsza. Pozostałych dziewięć konfiguracji jest przez nie zdominowanych.
Przy wyborze konfiguracji roboczej można się więc ograniczyć do SpargeAttention
bez utraty korzystnych kompromisów.

