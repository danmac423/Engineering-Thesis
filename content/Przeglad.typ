#import "../utils.typ": flex-caption, silentheading, todo

= Przegląd istniejących rozwiązań <przeglad-istniejacych-rozwiazan>

== Metody konwolucyjne i rekurencyjne
<metody-konwolucyjne-i-rekurencyjne>

Metody konwolucyjne realizują zadanie VSR poprzez podział wideo na nakładające się na siebie segmenty, co umożliwia równoległe przetwarzanie sąsiednich klatek w celu rekonstrukcji klatki docelowej. Reprezentatywny dla tej klasy model _EDVR_ @wang2019edvrvideorestorationenhanced wykorzystuje konwolucje deformowalne do adaptacyjnego dopasowania cech przy złożonym ruchu, oraz moduł TSA (_Temporal and Spatial Attention_) do fuzji informacji. Architektury konwolucyjne cechują się dużą stabilnością uczenia i odpornością na dynamiczne zmiany w scenie. Cierpią jednak na ograniczony zasięg kontekstu czasowego oraz wysoki narzut pamięciowy wynikający z wielokrotnego przetwarzania tych samych klatek. Ponadto niezależna rekonstrukcja kolejnych okien sprzyja powstawaniu artefaktów @Baniya_2024 @liu2022videosuperresolutionbased.

Metody rekurencyjne (RNN) traktują wideo jako ciągły strumień danych i przekazują ukryty stan pamięci pomiędzy kolejnymi krokami czasowymi, co pozwala na modelowanie długoterminowych zależności.
W modelu _BasicVSR_ @chan2021basicvsrsearchessentialcomponents zastosowano dwukierunkową propagację danych w czasie oraz moduł wyrównywania cech oparty na przepływie optycznym (ang. _optical flow_), który wyrównuje cechy przed przekazaniem ich do bloku rezydualnego. Pozwala to sieci na efektywne uwzględnianie informacji z całej sekwencji. Główną wadą dwukierunkowych metod rekurencyjnych pozostaje jednak wymóg znajomości całego wideo z góry oraz ryzyko stopniowego kumulowania i propagowania błędów rekonstrukcji @Baniya_2024 @liu2022videosuperresolutionbased.

== Metody oparte na transformerach
<metody-oparte-na-transformerach>

Transformery w VSR wykorzystują mechanizmy samouwagi (ang. _self-attention_) do dynamicznego ważenia i modelowania relacji czasowych wzdłuż całej sekwencji @Baniya_2024. Przykładowo, model _VSRT_ @cao2023videosuperresolutiontransformer posiada moduł STCSA (_Spatial-Temporal Convolutional Self-Attention_) do ekstrakcji lokalnych cech przestrzennych oraz dwukierunkową warstwę BOFF (_Bidirectional Optical Flow-Based Feed-Forward_), opartą na przepływie optycznym, do wyrównywania cech między klatkami. Alternatywne podejście reprezentuje _VRT_ @liang2022vrtvideorestorationtransformer, który zamiast przetwarzać klipy sekwencyjnie, rekonstruuje je równoległe. Wykorzystuje on moduł TMSA (_Temporal Mutual Self-Attention_) do jednoczesnej estymacji ruchu, wyrównywania i fuzji cech.

Kluczową zaletą metod opartych na transformerach jest ich zdolność do bezstratnego wychwytywania długoterminowych zależności czasowych oraz możliwość równoległego przetwarzania klatek, co pozwala wyeliminować wąskie gardło rekurencji @liang2022vrtvideorestorationtransformer. Głównym ograniczeniem pozostaje jednak bardzo wysoka złożoność obliczeniowa i ogromne zapotrzebowanie na pamięć w porównaniu z klasycznymi sieciami CNN @Baniya_2024.

== Metody dyfuzyjne
<metody-dyfuzyjne>

Modele dyfuzyjne stanowią klasę rozwiązań generatywnych opartych na procesie iteracyjnego usuwania szumu z reprezentacji w przestrzeni utajonej. Integracja architektury transformerów z modelami dyfuzyjnymi pozwala na precyzyjne odtwarzanie złożonych tekstur oraz utrzymanie spójności czasowej między klatkami. Przykładem wielokrokowego podejścia jest model _Upscale-A-Video_ @zhou2023upscaleavideotemporalconsistentdiffusionmodel, który stosuje lokalną i globalną strategię czasową oraz umożliwia sterowanie procesem rekonstrukcji za pomocą promptów tekstowych. Podstawowym ograniczeniem takich metod jest jednak konieczność wykonania kilkudziesięciu sekwencyjnych kroków inferencji, co generuje ogromny narzut obliczeniowy.

W odpowiedzi na ten problem rozwinięto metody jednokrokowe (ang. _one-step_), które skracają cały proces generatywny do pojedynczego przejścia sieci (ang. _forward pass_). Przykładowo, model _DOVE_ @chen2025doveefficientonestepdiffusion dostraja wcześniej wyszkolony, zaawansowany model dyfuzyjny _CogVideoX_ poprzez dwuetapową strategię uczenia _latent-pixel_, aby minimalizować różnice między ukrytymi reprezentacjami klatek przewidywanych i HR. Z kolei architektura _SeedVR2_ @wang2026seedvr2onestepvideorestoration wykorzystuje doszkalanie adwersarialne (ang. _Diffusion Adversarial Post-Training_) oraz adaptacyjną samouwagę okienkową (ang. _adaptive window attention_), co pozwala na płynne przetwarzanie sekwencji wideo w wysokich rozdzielczościach bez powstawania artefaktów.

Podstawową zaletą metod jednokrokowych jest więc drastyczna redukcja czasu inferencji i zużycia zasobów poprzez zastąpienie wielokrotnych pętli odszumiania pojedynczym przejściem sieci. Odbywa się to jednak kosztem trudniejszego i mniej stabilnego treningu oraz większej podatności na artefakty przy złożonym ruchu.

== Model FlashVSR
<model-flashvsr>

_FlashVSR_ @Zhuang2025FlashVSRTR to architektura przeznaczona do strumieniowego przetwarzania wideo w czasie rzeczywistym, wykorzystująca jednokrokowy model dyfuzyjny oparty na szkielecie _Wan 2.1-1.3B_ dostrojonym za pomocą metody LoRA. Aby wyeliminować opóźnienia i spadek wydajności, autorzy wprowadzili lekki moduł projekcji wejściowej (_Causal LR Projection-In_). Moduł ten grupuje po cztery klatki LR i poddaje je 8-krotnej kompresji przestrzennej za pomocą operacji _pixel shuffle_, a następnie 4-krotnej kompresji czasowej przy użyciu przyczynowych konwolucji 3D (_3D CausalConv_). Dzięki zastosowaniu pamięci podręcznej (ang. _causal cache_), cechy z poprzednich sekwencji są spójnie przenoszone i rzutowane przez perceptron wielowarstwowy bezpośrednio do przestrzeni utajonej transformera dyfuzyjnego.

Głównym rozwiązaniem problemu złożoności obliczeniowej standardowej samouwagi 3D jest zastosowanie blokowo-rzadkiego mechanizmu uwagi z ograniczeniem lokalnym (ang. _Locality-Constrained Sparse Attention_). FlashVSR wyznacza przybliżoną mapę uwagi poprzez uśrednianie reprezentacji kluczy i wartości, a pełne obliczenia wykonuje wyłącznie dla obszarów o najwyższych wynikach (ang. _top-k_). Dodatkowe nałożenie lokalnych okien przestrzennych ujednolica kodowanie pozycji między treningiem a wnioskowaniem, co umożliwia skalowanie modelu do bardzo wysokich rozdzielczości.

Zamiast dzielić długie wideo na nachodzące na siebie fragmenty FlashVSR przetwarza nagranie w sposób strumieniowy. Płynność i spójność klatek zapewnia pamięć _KV-cache_ z mechanizmem okna przesuwnego. Pozwala ona przechowywać najważniejsze cechy obrazu z poprzednich kroków bez konieczności ponownego ich przeliczania.

Ostatnim kluczowym elementem architektury jest zastąpienie ciężkiego, standardowego dekodera 3D VAE autorskim, lekkim dekoderem warunkowym (ang. _Tiny Conditional Decoder_). Zapewnia on około 7-krotne przyspieszenie etapu rekonstrukcji obrazu w przestrzeni pikseli w porównaniu z oryginalnym dekoderem sieci Wan, nie powodując przy tym widocznej utraty jakości wizualnej.

== Podsumowanie i wyznaczenie luki badawczej
<podsumowanie-i-wyznaczenie-luki-badawczej>

=== Porównanie i klasyfikacja metod VSR
<porównanie-i-klasyfikacja-metod-vsr>

Dotychczasowy rozwój metod VSR pokazuje wyraźną ewolucję od szybkich, lecz ograniczonych jakościowo modeli konwolucyjnych i rekurencyjnych, przez dokładniejsze architektury oparte na transformerach, aż po generatywne modele dyfuzyjne. Każda z tych klas rozwiązań charakteryzuje się odmiennym kompromisem pomiędzy jakością generowanego obrazu, wydajnością a zapotrzebowaniem na zasoby sprzętowe.

Metody klasyczne (CNN/RNN) oferują najwyższą szybkość i niskie zużycie pamięci, jednak mają tendencję do generowania rozmytych tekstur. Transformery skutecznie modelują długoterminowe zależności czasowe, ale ich złożoność obliczeniowa rośnie kwadratowo wraz z długością sekwencji. Wielokrokowe modele dyfuzyjne zapewniają najwyższy fotorealizm, lecz konieczność wykonywania kilkudziesięciu iteracji pętli odszumiania uniemożliwia ich zastosowanie w trybie interaktywnym.

Architektura _FlashVSR_ przełamuje to ograniczenie poprzez sprowadzenie procesu dyfuzji do jednego kroku inferencji oraz wprowadzenie mechanizmów strumieniowych i dedykowanego dekodera. Jakościowe zestawienie cech poszczególnych klas metod przedstawiono w @tab:vsr-comparison[tabeli].

#figure(
  kind: table,
  caption: [Porównanie klas metod superrozdzielczości wideo pod względem
    kosztu obliczeniowego, zapotrzebowania na pamięć i jakości rekonstrukcji],
  [
    #set text(size: 8.5pt)
    #show table.cell.where(y: 0): strong

    #table(
      columns: (2.1fr, 1.1fr, 2fr, 2.3fr, 2fr),
      align: left + top,
      stroke: 0.5pt + luma(150),
      fill: (col, row) => if row == 0 { luma(230) } else { none },

      table.header(
        [Klasa metod \ (reprezentant)],
        [Czas \ inferencji],
        [Zużycie pamięci],
        [Jakość rekonstrukcji#super[\*]],
        [Główne \ ograniczenie],
      ),

      [Konwolucyjne - EDVR @wang2019edvrvideorestorationenhanced],
      [bardzo krótki],
      [umiarkowane, rośnie z $H dot W$ i szerokością okna],
      [wysoka wierność, niska jakość percepcyjna - wygładzone tekstury],
      [wąski kontekst czasowy, redundantne przetwarzanie okien],

      [Rekurencyjne - \ BasicVSR @chan2021basicvsrsearchessentialcomponents],
      [bardzo krótki],
      [umiarkowane, stan ukryty utrzymywany przez cały klip],
      [wysoka wierność, percepcyjnie średnia],
      [wymaga całego nagrania z góry, akumulacja błędów],

      [Transformerowe - VRT @liang2022vrtvideorestorationtransformer, VSRT @cao2023videosuperresolutiontransformer],
      [średni],
      [wysokie, kwadratowe z długością sekwencji],
      [najwyższa wierność, percepcyjnie średnia],
      [złożoność $O(N^2)$ samouwagi],

      [Dyfuzyjne wielokrokowe - Upscale-A-Video @zhou2023upscaleavideotemporalconsistentdiffusionmodel],
      [bardzo \ długi],
      [umiarkowane, bufor reużywany między krokami],
      [niższa wierność, wysoka jakość percepcyjna],
      [dziesiątki sekwencyjnych przejść sieci],

      [Dyfuzyjne jednokrokowe - FlashVSR @Zhuang2025FlashVSRTR, DOVE @chen2025doveefficientonestepdiffusion, SeedVR2 @wang2026seedvr2onestepvideorestoration],
      [krótki, jedno przejście],
      [wysokie, wagi + KV-cache + aktywacje jednocześnie],
      [niższa wierność, wysoka jakość percepcyjna],
      [wysoki próg wejścia pamięci, niezależny od długości nagrania],
    )

    #v(-4pt)
    #block(width: 100%, align(left)[
      #set text(size: 7.5pt)
      #super[\*] Wierność mierzona metrykami pełnoreferencyjnymi (PSNR, SSIM),
      jakość percepcyjna - metrykami LPIPS oraz bezreferencyjnymi.
    ])
  ],
) <tab:vsr-comparison>

=== Ograniczenia modelu FlashVSR
<ograniczenia-modelu-flashvsr>

Oryginalne wdrożenie tego modelu wykazuje ogromne zapotrzebowanie na pamięć karty graficznej. Wyniki wydajnościowe zaprezentowane przez autorów architektury uzyskano na akceleratorze NVIDIA A100 z 80 GB VRAM. W domyślnej precyzji FP16/BF16 rozmiar wag modelu w połączeniu z buforem KV-cache oraz alokacją pamięci na aktywacje warstw samouwagi sprawia, że próba uruchomienia bazowej wersji _FlashVSR_ na powszechnie dostępnych, konsumenckich kartach graficznych (np. z 10 GB VRAM) kończy się przepełnieniem pamięci.

=== Sformułowanie problemu i celu pracy
<sformułowanie-problemu-i-celu-pracy>

Głównym problemem jest więc brak możliwości bezpośredniego uruchomienia jednokrokowego modelu _FlashVSR_ na sprzęcie o ograniczonych zasobach.

Celem niniejszej pracy jest zaprojektowanie, zrealizowanie i przeanalizowanie zoptymalizowanego potoku inferencji dla modelu _FlashVSR_. Wykorzystano w nim techniki takie jak kwantyzacja wag i aktywacji, zoptymalizowane mechanizmy uwagi oraz podział przestrzenno-czasowy, aby umożliwić stabilną i wydajną pracę modelu w reżimie 10 GB VRAM przy minimalnej utracie jakości wyjściowego obrazu.
