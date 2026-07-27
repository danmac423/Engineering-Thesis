#import "../utils.typ": flex-caption, silentheading, todo

// // Document setup
// #let horizontalrule = [
//   #line(start: (25%,0%), end: (75%,0%))
// ]

// #let endnote(num, contents) = [
//   #stack(dir: ltr, spacing: 3pt, super[#num], contents)
// ]
// #show terms: it => {
//   it.children
//     .map(child => [
//       #strong[#child.term]
//       #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
//       ])
//     .join()
// }

// #set table(
//   inset: 6pt,
//   stroke: none
// )

// #show figure.where(
//   kind: table
// ): set figure.caption(position: top)

// #show figure.where(
//   kind: image
// ): set figure.caption(position: bottom)

// #let content-to-string(content) = {
//   if content.has("text") {
//     content.text
//   } else if content.has("children") {
//     content.children.map(content-to-string).join("")
//   } else if content.has("body") {
//     content-to-string(content.body)
//   } else if content == [ ] {
//     " "
//   }
// }
// #let conf(
//   title: none,
//   subtitle: none,
//   authors: (),
//   keywords: (),
//   date: none,
//   abstract: none,
//   cols: 1,
//   margin: (x: 1.25in, y: 1.25in),
//   paper: "us-letter",
//   lang: "en",
//   region: "US",
//   font: ("New Computer Modern",),
//   fontsize: 11pt,
//   sectionnumbering: none,
//   doc,
// ) = {
//   set document(
//     title: title,
//     author: authors.map(author => content-to-string(author.name)),
//     keywords: keywords,
//   )
//   set page(
//     paper: paper,
//     margin: margin,
//     numbering: "1",
//   )
//   set par(justify: true)
//   set text(lang: lang,
//            region: region,
//            font: font,
//            size: fontsize)
//   set heading(numbering: sectionnumbering)

//   if title != none {
//     align(center)[#block(inset: 2em)[
//       #text(weight: "bold", size: 1.5em)[#title]
//       #(if subtitle != none {
//         parbreak()
//         text(weight: "bold", size: 1.25em)[#subtitle]
//       })
//     ]]
//   }

//   if authors != none and authors != [] {
//     let count = authors.len()
//     let ncols = calc.min(count, 3)
//     grid(
//       columns: (1fr,) * ncols,
//       row-gutter: 1.5em,
//       ..authors.map(author =>
//           align(center)[
//             #author.name \
//             #author.affiliation \
//             #author.email
//           ]
//       )
//     )
//   }

//   if date != none {
//     align(center)[#block(inset: 1em)[
//       #date
//     ]]
//   }

//   if abstract != none {
//     block(inset: 2em)[
//     #text(weight: "semibold")[Abstract] #h(1em) #abstract
//     ]
//   }

//   if cols == 1 {
//     doc
//   } else {
//     columns(cols, doc)
//   }
// }
// #show: doc => conf(
//   cols: 1,
//   doc,
// )


= Wybór rozwiązań do implementacji
<wybór-rozwiązań-do-implementacji>
Analiza z @przeglad-istniejacych-rozwiazan[rozdziału] wykazała, że przeszkodą w uruchomieniu modelu _FlashVSR_ na karcie konsumenckiej nie jest liczba kroków odszumiania, lecz szczytowe zapotrzebowanie na pamięć w obrębie pojedynczej inferencji. Niniejszy rozdział przedstawia wybór technik mających je obniżyć wraz z uzasadnieniem podjętych decyzji.

== Kryteria wyboru
<kryteria-wyboru>
Przyjęto pięć: działanie wyłącznie na etapie inferencji, bez treningu, dostrajania i kalibracji na dodatkowym zbiorze; wsparcie w architekturze Ampere, stanowiącej platformę docelową; brak konieczności odzyskiwania utraconej jakości przez ponowne uczenie; możliwość porównania konfiguracji w jednolitym środowisku pomiarowym; oraz dostępność w postaci biblioteki o ustabilizowanym interfejsie.

Na tej podstawie wybrano trzy osie optymalizacji: mechanizm uwagi, kwantyzację oraz ograniczenie rozmiaru przetwarzanego fragmentu.

== Mechanizm uwagi
<mechanizm-uwagi>
Blokowo-rzadki mechanizm uwagi stosowany w _FlashVSR_ (@model-flashvsr[podrozdział]) składa się z dwóch koncepcyjnie niezależnych elementów: jądra realizującego uwagę gęstą w obrębie okien lokalnych oraz metody selekcji istotnych par bloków w uwadze międzyokiennej. Ich rozdzielenie w warstwie Umożliwiło zbadać wpływ każdego z nich.

Jako referencyjne jądro gęstej uwagi przyjęto _FlashAttention_ @dao2022flashattentionfastmemoryefficientexact, stosowaną w oryginalnej implementacji - metodę dokładną, w której redukcja zużycia pamięci wynika wyłącznie z optymalizacji przepływu danych. Wariantem alternatywnym jest SageAttention @zhang2025sageattentionaccurate8bitattention: nie wymaga ponownego trenowania, działa na poziomie pojedynczego wywołania mechanizmu uwagi, a wykorzystywany przez nią format INT8 jest wspierany przez architekturę Ampere.

Wariantem odniesienia dla selekcji rzadkiej jest uwaga blokowo-rzadka autorów _FlashVSR_ @Zhuang2025FlashVSRTR. Jako alternatywę wybrano _SpargeAttention_ @zhang2025spargeattentionaccuratetrainingfreesparse, która realizuje to samo zadanie w sposób adaptacyjny, również nie wymaga trenowania, a działając w oparciu o szkielet SageAttention daje się z nią łączyć bez konfliktów implementacyjnych.

Parametry sterujące stopniem rzadkości (udział wybieranych par bloków, długość pamięci podręcznej kluczy i wartości oraz zasięg okna lokalnego) pozostawiono na wartościach przyjętych przez autorów modelu.

== Kwantyzacja
<kwantyzacja>
Przyjęto format INT8. Formatu FP8 nie rozważano, ponieważ architektura Ampere go nie wspiera. Odrzucono również formaty czterobitowe, takie jak NF4 czy GGUF. Rozwijane są one przede wszystkim pod kątem modeli językowych. Zachowanie jakości wymaga przy nich zwykle kalibracji lub dostrajania, co wykracza poza zakres pracy. Dla INT8 architektura Ampere udostępnia dedykowane jednostki tensorowe, a literatura raportuje dokładność zbliżoną do modelu bazowego przy odpowiednim doborze mechanizmu mapowania @wu2020integerquantizationdeeplearning.

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

Analogiczny mechanizm zastosowano w wymiarze czasowym. FlashVSR
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


