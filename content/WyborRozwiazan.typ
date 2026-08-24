#import "../utils.typ": flex-caption, silentheading, todo

= Wybór rozwiązań do implementacji
<wybór-rozwiązań-do-implementacji>
Analiza przeprowadzona w @przeglad-istniejacych-rozwiazan[rozdziale] wykazała, że główną barierą w uruchomieniu modelu FlashVSR na sprzęcie konsumenckim jest szczytowe zużycie pamięci podczas pojedynczej inferencji, a nie liczba kroków odszumiania. Przy doborze odpowiednich technik optymalizacyjnych kierowano się dwoma kluczowymi warunkami: pełną kompatybilnością z~architekturą Ampere @nvidia2020ampere oraz działaniem wyłącznie na etapie inferencji (bez dodatkowego trenowania, kalibracji czy douczania modelu). Na podstawie tych założeń wyodrębniono trzy główne osie optymalizacji: mechanizm uwagi, kwantyzację oraz ograniczenie rozmiaru przetwarzanego fragmentu.

== Mechanizm uwagi
<mechanizm-uwagi>
Blokowo-rzadki mechanizm uwagi stosowany w _FlashVSR_ składa się z dwóch koncepcyjnie niezależnych elementów: jądra realizującego uwagę gęstą w wywołaniach bez maski blokowej oraz jądra realizującego uwagę rzadką, ograniczoną maską wyznaczoną na podstawie selekcji istotnych par bloków i okien lokalnych. Rozdzielenie ich w warstwie konfiguracji pozwoliło zbadać wpływ każdego z nich. Zasadę działania porównywanych dalej jąder omówiono w~@optymalizacje-mechanizmu-uwagi[podrozdziale].

Jako wariant odniesienia dla uwagi gęstej przyjęto mechanizm SDPA (`scaled_dot_product_attention`) biblioteki PyTorch @pytorch, stosowany w oryginalnej implementacji. Na architekturze Ampere dobiera on jądro realizujące algorytm _FlashAttention_, w~którym redukcja zużycia pamięci wynika wyłącznie z optymalizacji przepływu danych, bez~aproksymacji. Wariantem alternatywnym jest _SageAttention_ @zhang2025sageattentionaccurate8bitattention, który działa na poziomie pojedynczego wywołania mechanizmu uwagi, a wykorzystywany przez niego format INT8 jest wspierany przez architekturę Ampere.

Wariantem odniesienia dla selekcji rzadkiej jest uwaga blokowo-rzadka autorów _FlashVSR_ @Zhuang2025FlashVSRTR. Jako alternatywę wybrano _SpargeAttention_ @zhang2025spargeattentionaccuratetrainingfreesparse, realizujące to samo zadanie w sposób adaptacyjny. Wykorzystanie architektury SageAttention jako wspólnej podstawy sprawia, że~oba rozwiązania można łączyć bez żadnych konfliktów implementacyjnych.

Długość pamięci podręcznej kluczy i wartości oraz zasięg okna lokalnego zachowano w wartościach przyjętych przez autorów modelu. Udział wybieranych par bloków jest natomiast zadawany względem stałej rozdzielczości wskazanej przez autorów i przeliczany na~powierzchnię faktycznie przetwarzanego fragmentu, przez co efektywna liczba wybieranych bloków zależy od rozmiaru kafla.

== Kwantyzacja
<kwantyzacja>
Jako docelowy format kwantyzacji przyjęto INT8. Zastosowanie formatu FP8 wykluczono ze względu na brak wsparcia w docelowej architekturze Ampere, natomiast rozwiązania czterobitowe (takie jak NF4 czy GGUF) odrzucono, gdyż są one optymalizowane głównie pod~kątem dużych modeli językowych. Dla INT8 architektura Ampere udostępnia dedykowane jednostki tensorowe, a literatura raportuje dokładność zbliżoną do modelu bazowego przy~odpowiednim doborze mechanizmu mapowania @wu2020integerquantizationdeeplearning.

Do realizacji wybrano bibliotekę torchao @torchao2024, której działanie polega na konwersji tensorów wag na wyspecjalizowane podtypy, nie wymagając modyfikacji definicji modelu ani eksportu do reprezentacji pośredniej. Kwantyzację można więc włączyć jako opcjonalny krok inicjalizacji potoku. Zbadano dwa jej warianty, odpowiadające podziałowi z podrozdziałów @kwantyzacja-wag[] i @kwantyzacja-aktywacji[]: kwantyzację wyłącznie wag oraz kwantyzację wag i aktywacji.

Kwantyzacji poddano wyłącznie transformer dyfuzyjny, który odpowiada za zdecydowaną większość parametrów modelu i jest wywoływany dla każdego przetwarzanego fragmentu.

== Ograniczenie rozmiaru przetwarzanego fragmentu
<ograniczenie-rozmiaru-przetwarzanego-fragmentu>
Zapotrzebowanie na pamięć w obrębie pojedynczego wywołania modelu zależy od liczby tokenów czasoprzestrzennych, a więc od rozdzielczości przetwarzanego fragmentu. Podział klatki na kafle przetwarzane kolejno sprawia, że szczytowe zużycie pamięci przestaje zależeć od rozdzielczości nagrania wejściowego, a zaczyna zależeć wyłącznie od rozmiaru kafla.

Kosztem takiego podejścia jest redundancja obliczeń w obszarze zakładek, ryzyko wystąpienia widocznych artefaktów na granicach niezależnie rekonstruowanych kafli oraz~zmiana efektywnej rzadkości uwagi w zależności od ich rozmiaru. Sam sposób łączenia fragmentów obrazu opisano w @kafelkowanie-przestrzenne[podrozdziale].

Analogiczny mechanizm zastosowano w wymiarze czasowym. Mimo strumieniowego trybu pracy modelu bufory wejściowe i wyjściowe długich nagrań pozostają kosztowne pamięciowo, sekwencję dzielono zatem na segmenty o ustalonej długości. Realizację tego podziału opisano w @kafelkowanie-czasowe[podrozdziale].

== Zestawienie technik optymalizacji
<zestawienie-technik-optymalizacji>
Wybrane techniki zestawiono w @tab:zestawienie-technik[tabeli]. Ich wykorzystanie można niezależnie konfigurować, co pozwala badać zarówno pojedyncze rozwiązania, jak i ich kombinacje.

#figure(
  kind: table,
  caption: [Zestawienie technik wybranych do implementacji],
  [
    #set text(size: 8.5pt)
    #show table.cell.where(y: 0): strong
    #show table.cell.where(x: 0): strong

    #table(
      columns: (1fr, 1fr, 1fr, 1fr),
      align: left + top,
      stroke: 0.5pt + luma(150),
      fill: (col, row) => if row == 0 { luma(230) } else { none },
      table.header(
        [Oś optymalizacji],
        [Wariant odniesienia],
        [Warianty
          alternatywne],
        [Oczekiwany efekt],
      ),

      [Jądro uwagi gęstej],
      [SDPA (FlashAttention) @dao2022flashattentionfastmemoryefficientexact],
      [SageAttention @zhang2025sageattentionaccurate8bitattention],
      [skrócenie czasu inferencji],

      [Selekcja rzadka],
      [Block Sparse Attention @Zhuang2025FlashVSRTR],
      [SpargeAttention @zhang2025spargeattentionaccuratetrainingfreesparse],
      [skrócenie czasu inferencji],

      [Kwantyzacja], [brak (bfloat16)], [INT8 wag; INT8 wag \ i aktywacji], [redukcja zużycia pamięci],

      [Kafelkowanie \ przestrzenne],
      [wyłączone],
      [rozmiar kafla i zakładka jako parametry],
      [uniezależnienie szczytu \ pamięci od rozdzielczości wejścia],

      [Kafelkowanie czasowe],
      [wyłączone],
      [długość segmentu i zakładka jako parametry],
      [ograniczenie zużycia pamięci dla długich nagrań],
    )],
) <tab:zestawienie-technik>


