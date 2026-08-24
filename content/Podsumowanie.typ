#import "../utils.typ": flex-caption, silentheading, todo

= Podsumowanie i wnioski
<podsumowanie-i-wnioski>

== Podsumowanie prac
<podsumowanie-prac>


W ramach pracy wykonano następujące elementy:

- Analiza istniejących metod VSR i identyfikacja luki badawczej - @przeglad-istniejacych-rozwiazan[rozdział],
- Dobór trzech osi optymalizacji wraz z uzasadnieniem - @wybór-rozwiązań-do-implementacji[rozdział],
- Modularny pakiet z konfigurowalnym potokiem inferencji, powstały z refaktoryzacji implementacji referencyjnej - podrozdziały @architektura-pakietu[]-@interfejsy-systemu[],
- Implementacja wymiennych wariantów mechanizmu uwagi, kwantyzacji INT8 oraz kafelkowania przestrzennego i czasowego - podrozdziały @wymienne-warianty-mechanizmu-uwagi[]-@kafelkowanie-czasowe[],
- Aplikacja pokazowa - @aplikacja-pokazowa[podrozdział],
- Metodyka pomiarowa i plan eksperymentów - @metodyka-badan-i-testy[rozdział],
- Wyniki pomiarów wydajności, granicy wykonalności i jakości rekonstrukcji - @wyniki-i-ich-omowienie[rozdział].

Cel pracy, którym było umożliwienie inferencji jednokrokowego modelu superrozdzielczości wideo opartego na dyfuzji na karcie graficznej wyposażonej w 10 GB pamięci VRAM, został zrealizowany. Modelu w postaci udostępnionej przez autorów nie da się uruchomić na karcie docelowej przy żadnej z badanych rozdzielczości wejściowych. W konfiguracji zalecanej w~@wnioski-badawcze[podrozdziale] model przetwarza ten sam materiał w dostępnym budżecie pamięci, kosztem wydłużenia czasu inferencji i akceptowalnej utraty jakości rekonstrukcji.

Kod, skrypty pomiarowe i wyniki eksperymentów udostępniono w repozytorium wskazanym w @implementacja[rozdziale]. Pełnych danych wejściowych i wyjściowych dla obu zbiorów testowych, zajmujących kilkadziesiąt gigabajtów, nie umieszczono w repozytorium. Zarchiwizowano je na nośniku zewnętrznym i są dostępne na żądanie, a w repozytorium znalazł się ich reprezentatywny podzbiór.

== Wnioski badawcze
<wnioski-badawcze>

Warunkiem koniecznym wykonalności jest kafelkowanie przestrzenne. Pomiary na akceleratorze A100 pokazały, że zapotrzebowanie na pamięć konfiguracji bazowej przekraczało pojemność karty docelowej od 1,5 do blisko 2,4 raza. Zastosowanie samych technik obliczeniowych zmniejszyło zużycie pamięci o nie więcej niż 11%. Wartość tę zmierzono w konfiguracji kafelkowanej, więc nie przenosi się ona wprost na przetwarzanie pełnej klatki, gdzie udział aktywacji w szczycie jest wyższy. Nawet przy założeniu dwukrotnie większej redukcji deficyt pozostałby niepokryty. Kafelkowanie przestrzenne jest jedyną techniką, która uniezależnia szczytowe zużycie pamięci od rozdzielczości wejściowej, dlatego jest wymagane do uruchomienia modelu. Techniki obliczeniowe pozwalają jednak zyskać zapas pamięci i przesunąć granicę wykonalności o jeden krok siatki w rozmiarach kafli.

Wpływ poszczególnych osi optymalizacji różni się od pierwotnych założeń. Zastąpienie gęstego jądra uwagi nie przynosi żadnych korzyści, wbrew oczekiwaniom przedstawionym w~@tab:zestawienie-technik[tabeli]. Z kolei podmiana mechanizmu selekcji rzadkiej skraca czas inferencji o 12,9% i jest jedyną badaną techniką, która faktycznie przyspiesza przetwarzanie. Kwantyzacja oddziałuje na zużycie pamięci, przy czym oba jej warianty zachowują się odmiennie: kwantyzacja samych wag obniża szczyt o 330 MiB przy wydłużeniu czasu o 3,6%, natomiast objęcie nią również aktywacji obniża szczyt o 898 MiB, lecz wydłuża czas o 29,6%.

Spadek jakości rekonstrukcji wynika niemal wyłącznie z zastosowania kafelkowania. Analizując łańcuch przyrostowych konfiguracji, to właśnie wprowadzenie kafelkowania odpowiada za całą zmianę metryki PSNR oraz za większość spadków w pozostałych wskaźnikach. Trzy kolejne modyfikacje obliczeniowe zmieniają wyniki w sposób marginalny. Oznacza to, że kompromis między jakością obrazu a zużyciem pamięci sprowadza się w~praktyce do decyzji o kafelkowaniu, a nie do wyboru poszczególnych technik obliczeniowych.

Ustalenia te wyznaczają kolejność decyzji konfiguracyjnych. Jako pierwszy należy ustalić rozmiar kafla, ponieważ to on definiuje budżet pamięci, w ramach którego działają pozostałe techniki. Dobiera się go indywidualnie dla każdej rozdzielczości wejściowej tak, aby mieścił się w budżecie pamięci przy możliwie najmniejszej redundancji obliczeń. W kolejnym kroku mechanizm selekcji rzadkiej jest zastępowany przez _SpargeAttention_ i włączana jest kwantyzacja wag. Zabieg ten jednocześnie skraca czas inferencji i zmniejsza szczytowe zużycie pamięci przy minimalnym wpływie na jakość rekonstrukcji. Kwantyzację aktywacji należy natomiast traktować jako rezerwę, którą warto włączyć dopiero wtedy, gdy uzyskany wcześniej zapas pamięci okaże się niewystarczający.

== Ograniczenia i kierunki rozwoju
<ograniczenia-i-kierunki-rozwoju>

Wyniki uzyskano wyłącznie na jednej architekturze GPU, dlatego wniosków nie można bezpośrednio przenieść na inne generacje sprzętu. W szczególności układy obsługujące format FP8 otwierają ścieżkę optymalizacji, która w ramach tej pracy była niedostępna. Ze względu na czas potrzebny do przetworzenia obu zbiorów testowych jakość rekonstrukcji oceniano na materiale wygenerowanym na akceleratorze A100, a nie na karcie docelowej. Ponadto pomiary objęły dwie rozdzielczości wejściowe, obie niższe od rozdzielczości typowych nagrań, przez co uzyskane wartości liczbowe należy odnosić wyłącznie do badanego zakresu.

Warto rozważyć trzy główne kierunki dalszych prac. Pierwszym z nich jest szczegółowa ocena artefaktów powstających na granicach kafli, zarówno przestrzennych, jak i czasowych. Wykorzystane w badaniach metryki obliczane są dla całych klatek, przez co mogą nie wychwytywać lokalnych nieciągłości obrazu. Drugi kierunek to opracowanie metody automatycznego doboru rozmiaru kafla przestrzennego dla zadanego wejścia. Taki mechanizm minimalizowałby redundancję obliczeń i jest możliwy do zrealizowania na podstawie samej geometrii podziału, jeszcze przed właściwym przetwarzaniem. Trzeci obszar badawczy wynika z wniosku, że to kafelkowanie przestrzenne odpowiada za niemal cały spadek jakości. Ponieważ model bazowy był trenowany na pełnych klatkach, jego dostrojenie na danych kafelkowanych prawdopodobnie pozwoliłoby zniwelować te straty. Działanie to wykracza jednak poza zakres zdefiniowany w @cel-i-zakres-pracy[podrozdziale], a dodatkową barierą jest fakt, że autorzy modelu FlashVSR opisali jedynie swoją wieloetapową procedurę trenowania, nie publikując niezbędnego do niej kodu.
