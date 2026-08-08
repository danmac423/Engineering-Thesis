#import "../utils.typ": flex-caption, silentheading, todo

= Metodyka badań i testy
<metodyka-badan-i-testy>

== Cel badań i pytania badawcze
<cel-badan>

Celem przeprowadzonych eksperymentów jest odpowiedź na trzy pytania badawcze, wynikające z założeń przedstawionych w @cel-i-zakres-pracy[podrozdziale].

Pierwsze dotyczy wykonalności: przy jakiej konfiguracji potok mieści się w budżecie 10 GB pamięci karty graficznej i jaki jest koszt czasowy tego ograniczenia. Drugie dotyczy udziału poszczególnych osi optymalizacji: jak podmiana jądra uwagi gęstej, podmiana selekcji rzadkiej oraz kwantyzacja wpływają na czas inferencji i szczytowe zużycie pamięci, osobno i w kombinacji. Trzecie dotyczy kosztu jakościowego: o ile pogarsza się rekonstrukcja po włączeniu kolejnych technik i jak koszt ten rozkłada się między nie.

Punktem odniesienia dla wszystkich pomiarów jest konfiguracja bazowa. Odpowiada modelowi w postaci udostępnionej przez autorów: przetwarzanie klatki bez podziału na kafle, uwaga gęsta realizowana mechanizmem SDPA, selekcja rzadka zgodna z implementacją autorów, wagi i aktywacje w formacie bfloat16.

== Zbiory testowe i przygotowanie danych
<zbiory-testowe-i-przygotowanie-danych>

Ewaluację jakości przeprowadzono na dwóch zbiorach o rozłącznych rolach.

Zbiór YouHQ40 obejmuje 40 klipów o łącznej długości 1318 klatek, wraz z materiałem referencyjnym. Jest to jedyny zbiór, na którym możliwe było wyznaczenie metryk pełnoreferencyjnych. Odpowiadający mu materiał o niskiej rozdzielczości wygenerowano skryptem `generate_lq.py`, odtwarzającym potok degradacji przyjęty w pracy RealBasicVSR. Potok ten łączy w dwóch etapach: rozmycia izotropowe i anizotropowe, jądra typu plateau oraz sinc, szum gaussowski i poissonowski, kompresja JPEG oraz kompresja wideo, a na końcu przeskalowanie czterokrotne. Losowe parametry degradacji ustalono jednym ziarnem generatora liczb pseudolosowych, dzięki czemu zbiór wejściowy jest odtwarzalny.

Zbiór VideoLQ obejmuje 50 klipów po 100 klatek zawierających degradacje rzeczywiste, bez materiału referencyjnego. Wyznaczano na nim wyłącznie metryki bezreferencyjne. Jego rolą jest sprawdzenie, czy wnioski wyciągnięte z materiału degradowanego syntetycznie przenoszą się na nagrania rzeczywiste.

== Metryki
<metryki>

=== Jakość rekonstrukcji
<jakosc-rekonstrukcji>

Zastosowano zestaw siedmiu metryk opisanych w @metryki-oceny-jakości-obrazu-i-wideo[podrozdziale]. Metryki PSNR, SSIM, LPIPS, NIQE, MUSIQ oraz CLIPIQA wyznaczano biblioteką pyiqa, osobno dla każdej klatki wyjściowej. Wartości uśredniano najpierw w obrębie klipu, a następnie po klipach zbioru. Przy klipach o różnej długości procedura ta daje inny wynik niż uśrednienie po wszystkich klatkach i nadaje każdemu klipowi jednakową wagę niezależnie od jego długości.

Metrykę DOVER wyznaczano dla całych klipów, a nie dla pojedynczych klatek, ponieważ ocenia ona również spójność czasową. Jej implementacja referencyjna wymaga biblioteki PyTorch w wersji sprzed 2.0, niezgodnej z pozostałymi komponentami systemu. Uruchamiano ją zatem w wydzielonym środowisku wirtualnym, na materiale zapisanym wcześniej przez główny potok, a wyniki obu środowisk łączono skryptem agregującym.

Metryki pełnoreferencyjne wyznaczono wyłącznie dla zbioru YouHQ40. W zestawieniach dotyczących zbioru VideoLQ odpowiadające im pola pozostają puste.

=== Wydajność
<wydajnosc>

Rejestrowano pięć wielkości: czas budowy potoku, czas inferencji całej sekwencji, czas przypadający na klatkę, ilość pamięci zajętej po zakończeniu inicjalizacji oraz szczytowe zużycie pamięci karty graficznej.

Jako miarę zużycia pamięci przyjęto wartość `max_memory_reserved`, czyli szczytowy rozmiar puli zarezerwowanej przez alokator, a nie sumę rozmiarów żywych tensorów raportowaną przez `max_memory_allocated`. O wystąpieniu przepełnienia decyduje rozmiar puli, ponieważ to on odzwierciedla pamięć faktycznie odebraną sterownikowi, wraz z fragmentacją. Wartości zużycia pamięci podawane są w mebibajtach (MiB), zgodnie z jednostką raportowaną przez bibliotekę PyTorch.

== Procedura pomiaru wydajności
<procedura-pomiaru-wydajnosci>

Pomiary wykonywano na materiale o długości 101 klatek. Liczba ta odpowiada scenariuszowi raportowanemu przez autorów modelu FlashVSR. Klatki wycinano centralnie z klipu testowego do zadanej rozdzielczości.

Materiał wczytywano do pamięci operacyjnej przed rozpoczęciem pomiaru, a wynik odrzucano bez zapisu. Mierzony czas nie obejmuje zatem dekodowania wejścia ani kodowania wyjścia, co ogranicza wpływ operacji wejścia-wyjścia na porównanie konfiguracji.

Potok budowano jednorazowo dla każdej konfiguracji, a czas budowy mierzono osobno i nie wliczano go do czasu inferencji. Jest to uzasadnione trybem pracy systemu opisanym w @architektura-pakietu[podrozdziale] - zbudowany potok przetwarza wiele nagrań bez ponownej inicjalizacji, więc jej koszt rozkłada się na całą sesję.

Przed pomiarem wykonywano przebieg rozgrzewkowy, pochłaniający kompilację jąder obliczeniowych i pierwszą alokację buforów pamięci podręcznej. Licznik szczytowego zużycia pamięci zerowano przed każdym przebiegiem mierzonym, a pulę alokatora zwalniano między konfiguracjami. Raportowaną wartością czasu jest mediana przebiegów mierzonych, a wartością zużycia pamięci ich maksimum. Wybór maksimum wynika z faktu, że o mieszczeniu się w budżecie decyduje przypadek najgorszy, a nie przeciętny.

Czas inferencji mierzono wyłącznie na karcie RTX 3080, ponieważ zależy on od architektury karty i nie przenosi się między platformami. Na tej samej karcie mierzono szczytowe zużycie pamięci we wszystkich konfiguracjach, które się na niej uruchamiają. Wyjątkiem jest konfiguracja bazwia. Ponieważ kończy się ona na karcie docelowej przepełnieniem pamięci, jej zapotrzebowanie zmierzono dodatkowo na akceleratorze A100. Na tym samym akceleratorze generowano materiał wyjściowy dla zbiorów testowych, na którym wyznaczano metryki jakości, ze względu na czas potrzebny na przetworzenie obu zbiorów.

== Plan eksperymentów
<plan-eksperymentow>

Przeprowadzono trzy eksperymenty. W każdym z nich jawnie ustalono wielkość
zmienianą oraz parametry utrzymywane na stałym poziomie.

#figure(
  kind: table,
  caption: [Zestawienie przeprowadzonych eksperymentów],
  [
    #set text(size: 8.5pt)
    #show table.cell.where(y: 0): strong
    // #show table.cell.where(x: 0): strong

    #table(
      columns: (auto, 2fr, 2fr, auto),
      align: left + top,
      stroke: 0.5pt + luma(150),
      fill: (col, row) => if row == 0 { luma(230) } else { none },
      table.header([Eksperyment], [Zmieniane], [Stałe], [Mierzone]),

      [E1],
      [dwanaście kombinacji: jądro uwagi gęstej (2) $times$ selekcja rzadka (2)
        $times$ tryb kwantyzacji (3)],
      [kafel 192 $times$ 192, zakładka 24, wejście 192 $times$ 352, 101 klatek],
      [czas, pamięć],

      [E2],
      [rozmiar kafla: 128, 160, 192, 224, 256],
      [zakładka 24, konfiguracja referencyjna, wejście 256 $times$ 448, 101 klatek],
      [czas, pamięć, \ granica wykonalności],

      [E3],
      [pięć konfiguracji przyrostowych oraz dwa rozmiary kafla],
      [oba zbiory testowe, kafel 192 poza wariantami rozmiaru],
      [siedem metryk jakości],
    )],
)

W eksperymencie E1 przyjęto rozdzielczość wejściową $192 times 352$, odpowiadającą scenariuszowi, dla którego autorzy modelu FlashVSR raportują szczytowe zużycie pamięci. Pozwala to zestawić uzyskane wartości bezpośrednio z liczbą przytoczoną w rozdziale 1, bez przeliczania między rozdzielczościami. Porównywalność samych konfiguracji zapewnia stały rozmiar kafla, od którego zależy szczytowe zużycie pamięci.

Eksperyment E2 rozszerzono o pięć przebiegów uzupełniających. Konfigurację bazową uruchomiono przy dwóch rozdzielczościach wejściowych: $192 times 352$, odpowiadającej scenariuszowi autorów modelu, oraz $256 times 448$, przyjętej w pozostałych pomiarach tego eksperymentu. Każdą z nich uruchomiono na obu platformach - na karcie docelowej w celu sprawdzenia, czy mieści się w jej budżecie pamięci, oraz na akceleratorze A100, gdzie się mieści, w celu określenia skali zapotrzebowania. Piąty przebieg wykonano dla kafla $224 times 224$, przy którym konfiguracja referencyjna kończy się przepełnieniem pamięci, lecz z włączoną kwantyzacją i podmienionymi jądrami uwagi, aby ustalić, czy badane techniki przesuwają granicę wykonalności, a nie jedynie obniżają zużycie pamięci w konfiguracjach już wykonalnych.

Konfiguracje eksperymentu E3 dobrano tak, by tworzyły łańcuch przyrostowy, w którym każda kolejna konfiguracja różni się od poprzedniej jedną zmianą. Punktem wyjścia jest konfiguracja bazowa, do której dodawane jest kolejno kafelkowanie przestrzenne, podmiana jądra uwagi gęstej, podmiana selekcji rzadkiej oraz kwantyzacja wag i aktywacji. Konstrukcja ta pozwala przypisać zmianę jakości konkretnej technice, zamiast porównywać konfiguracje różniące się kilkoma parametrami naraz.
