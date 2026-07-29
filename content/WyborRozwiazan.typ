#import "../utils.typ": flex-caption, silentheading, todo

= Wybór rozwiązań do implementacji
<wybór-rozwiązań-do-implementacji>
Analiza z @przeglad-istniejacych-rozwiazan[rozdziału] wykazała, że przeszkodą w uruchomieniu modelu _FlashVSR_ na karcie konsumenckiej nie jest liczba kroków odszumiania, lecz szczytowe zapotrzebowanie na pamięć w obrębie pojedynczej inferencji. Wybór technik mających je obniżyć oparto na pięciu kryteriach: działanie wyłącznie na etapie inferencji, bez treningu, dostrajania i kalibracji na dodatkowym zbiorze; wsparcie w architekturze Ampere, stanowiącej platformę docelową; brak konieczności odzyskiwania utraconej jakości przez ponowne uczenie; możliwość porównania konfiguracji w jednolitym środowisku pomiarowym; oraz dostępność w postaci biblioteki o ustabilizowanym interfejsie. Na tej podstawie wybrano trzy osie optymalizacji: mechanizm uwagi, kwantyzację oraz ograniczenie rozmiaru przetwarzanego fragmentu.


== Mechanizm uwagi
<mechanizm-uwagi>
Blokowo-rzadki mechanizm uwagi stosowany w _FlashVSR_ składa się z dwóch koncepcyjnie niezależnych elementów: jądra realizującego uwagę gęstą w obrębie okien lokalnych oraz metody selekcji istotnych par bloków w uwadze międzyokiennej. Ich rozdzielenie w warstwie Umożliwiło zbadać wpływ każdego z nich.

Jako referencyjne metodę dla gęstej uwagi przyjęto _FlashAttention_ @dao2022flashattentionfastmemoryefficientexact, stosowaną w oryginalnej implementacji, w której redukcja zużycia pamięci wynika wyłącznie z optymalizacji przepływu danych. Wariantem alternatywnym jest _SageAttention_ @zhang2025sageattentionaccurate8bitattention, który nie wymaga ponownego trenowania, działa na poziomie pojedynczego wywołania mechanizmu uwagi, a wykorzystywany przez nią format INT8 jest wspierany przez architekturę Ampere.

Wariantem odniesienia dla selekcji rzadkiej jest uwaga blokowo-rzadka autorów _FlashVSR_ @Zhuang2025FlashVSRTR. Jako alternatywę wybrano _SpargeAttention_ @zhang2025spargeattentionaccuratetrainingfreesparse, która realizuje to samo zadanie w sposób adaptacyjny, również nie wymaga trenowania, a działając w oparciu o szkielet SageAttention daje się z nią łączyć bez konfliktów implementacyjnych.

Parametry sterujące stopniem rzadkości (udział wybieranych par bloków, długość pamięci podręcznej kluczy i wartości oraz zasięg okna lokalnego) pozostawiono na wartościach przyjętych przez autorów modelu.

== Kwantyzacja
<kwantyzacja>
Przyjęto format INT8. Formatu FP8 nie rozważano, ponieważ architektura Ampere go nie wspiera. Odrzucono również formaty czterobitowe, takie jak NF4 czy GGUF, ponieważ są rozwijane przede wszystkim pod kątem modeli językowych. Dla INT8 architektura Ampere udostępnia dedykowane jednostki tensorowe, a literatura raportuje dokładność zbliżoną do modelu bazowego przy odpowiednim doborze mechanizmu mapowania @wu2020integerquantizationdeeplearning.

Do realizacji wybrano bibliotekę _torchao_ @torchao2024, która działa przez podmianę tensorów wag na wyspecjalizowane podtypy, nie wymagając modyfikacji definicji modelu ani eksportu do reprezentacji pośredniej. Kwantyzację można więc włączyć jako opcjonalny krok inicjalizacji potoku.

Kwantyzacji poddano wyłącznie transformer dyfuzyjny, odpowiadający za większość parametrów modelu i wywoływany dla każdego fragmentu. Lekkiego dekodera warunkowego nie objęto zakresem pracy.

== Ograniczenie rozmiaru przetwarzanego fragmentu
<ograniczenie-rozmiaru-przetwarzanego-fragmentu>
Zapotrzebowanie na pamięć w obrębie pojedynczego wywołania modelu zależy
od liczby tokenów czasoprzestrzennych, a więc od rozdzielczości
przetwarzanego fragmentu. Podział klatki na kafle przetwarzane kolejno
sprawia, że szczytowe zużycie pamięci przestaje zależeć od
rozdzielczości nagrania wejściowego, a zaczyna zależeć wyłącznie od
rozmiaru kafla.

Kosztem jest redundancja obliczeń w obszarze zakładki oraz ryzyko
widocznych nieciągłości na granicach kafli, rekonstruowanych niezależnie
i bez dostępu do kontekstu sąsiadów. Przyjęto zatem przetwarzanie z
zakładką i łączenie kafli maską o liniowo narastających wagach we wspólnym obszarze.

Analogiczny mechanizm zastosowano w wymiarze czasowym. _FlashVSR_
przetwarza nagranie strumieniowo, a pamięć podręczna kluczy i wartości z
oknem przesuwnym ogranicza narastanie stanu, jednak bufory wejściowe i
wyjściowe długich nagrań pozostają kosztowne pamięciowo. Sekwencję
dzielono więc na segmenty o ustalonej długości, łączone z zakładką przez
liniowe mieszanie klatek.

== Podsumowanie
<podsumowanie>
Wybrane techniki zestawiono w @tab:zestawienie-technik[tabeli]. Każda jest przełączalna w czasie
działania, co pozwala badać zarówno pojedyncze rozwiązania, jak i ich
kombinacje w jednolitym środowisku pomiarowym.


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
      [FlashAttention @dao2022flashattentionfastmemoryefficientexact],
      [SageAttention @zhang2025sageattentionaccurate8bitattention],
      [skrócenie czasu inferencji],

      [Selekcja rzadka],
      [uwaga blokowo-rzadka @Zhuang2025FlashVSRTR],
      [SpargeAttention @zhang2025spargeattentionaccuratetrainingfreesparse],
      [skrócenie czasu inferencji],

      [Kwantyzacja], [brak (bfloat16)], [INT8 wag; INT8 wag \ i aktywacji], [redukcja zużycia pamięci],

      [Kafelkowanie \ przestrzenne],
      [wyłączone],
      [rozmiar kafla i zakładka jako parametry],
      [uniezależnienie szczytu pamięci od rozdzielczości wejścia],

      [Kafelkowanie czasowe],
      [wyłączone],
      [długość segmentu i zakładka jako parametry],
      [ograniczenie zużycia pamięci dla długich nagrań],
    )],
) <tab:zestawienie-technik>


