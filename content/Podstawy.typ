#import "../utils.typ": flex-caption, silentheading, todo

= Podstawy teoretyczne

== Superrozdzielczość wideo

Superrozdzielczość wideo to zadanie z zakresu widzenia komputerowego, którego celem jest generowanie materiałów wideo o wysokiej rozdzielczości (ang. _high-resolution_, HR) i ulepszonej jakości wizualnej na podstawie wejściowych sekwencji o niskiej rozdzielczości (ang. _low-resolution_, LR). Podstawową różnicą między VSR a superrozdzielczością obrazów (ang. _Single Image Super-Resolution_, SISR) jest obecność w wideo dodatkowego wymiaru czasowego. SISR bazuje wyłącznie na informacji przestrzennej z pojedynczego obrazu, natomiast VSR wykorzystuje dodatkowo silne korelacje między kolejnymi klatkami. Bezpośrednie zastosowanie metod SISR do poszczególnych klatek wideo nie pozwala na uchwycenie tych zależności czasowych @Baniya_2024.

=== Sformułowanie problemu

Problem superrozdzielczości wideo jest zdefiniowany jako zadanie odwrotne, w którym dążymy do odzyskania sekwencji HR na podstawie obserwowanej sekwencji LR. Proces powstawania materiału LR jest zazwyczaj modelowany jako złożenie degradacji fizycznych i cyfrowych.

Ogólny model degradacji dla $i$-tej klatki wideo można zapisać jako funkcję zależną od klatki docelowej $I_i^("HR")$ oraz jej sąsiedztwa czasowego @liu2022videosuperresolutionbased:

$
  I_i^("LR") = phi.alt(I_i^("HR"), {I_j^("HR")}^(i+N)_(j=i-N)\;theta_(alpha))
$<degradation_eq>

gdzie $I_i^("LR")$ oznacza obserwowaną klatkę o niskiej rozdzielczości, $N$ oznacza promień czasowy (zakres sąsiednich klatek), a $theta_(alpha)$ reprezentuje parametry procesu degradacji (np. szum, rozmycie).

Celem modelu VSR jest znalezienie funkcji odwzorowującej $f_("VSR")$, sparametryzowanej przez wagi $theta_(f_("VSR"))$, która estymuje klatkę wysokiej rozdzielczości $hat(I)_(i)^("SR")$ na podstawie sekwencji klatek wejściowych LR @liu2022videosuperresolutionbased:

$
  hat(I)_(i)^("SR") = f_("VSR")(I_i^("LR"), {I_j^("LR")}^(i+N)_(j=i-N)\;theta_(f_("VSR")))
$<vsr_eq>

Powyższe klasyczne sformułowania zakładają uproszczone, deterministyczne zniekształcenia, które nie odzwierciedlają warunków rzeczywistych. W praktyce proces utraty jakości wymaga zaawansowanych modeli degradacji, które łączą losowe rozmycia, szum oraz zmianę rozmiaru i artefakty kompresji @chan2021investigatingtradeoffsrealworldvideo.

=== Spójność czasowa

Spójność czasowa w kontekście superrozdzielczości wideo polega na utrzymaniu ciągłości, płynności oraz braku zauważalnych zniekształceń i migotania między kolejnymi klatkami wygenerowanej sekwencji HR @Baniya_2024 @liu2022videosuperresolutionbased. Bezpośrednie zastosowanie metod SISR do poszczególnych klatek pomija zależności czasowe, co prowadzi do niestabilności detali i artefaktów wizualnych. W modelach głębokiego uczenia spójność tę realizuje się poprzez techniki wyrównywania klatek i kompensacji ruchu (ang. _motion estimation and motion compensation_, MEMC), konwolucje 3D, moduły rekurencyjne (RNN) propagujące kontekst czasowy oraz mechanizmy uwagi @Baniya_2024. Choć metody te poprawiają jakość generowanych sekwencji, analiza wielu klatek znacznie zwiększa złożoność obliczeniową i pamięciową, a w warunkach rzeczywistych stwarza ryzyko akumulacji i przenoszenia błędów między klatkami @chan2021investigatingtradeoffsrealworldvideo.

== Modele dyfuzyjne

Modele dyfuzyjne (ang. _Denoising Diffusion Probabilistic Models_, DDPMs) to klasa modeli generatywnych wykorzystująca dwa podstawowe łańcuchy Markova: w przód (ang. _forward chain_), który stopniowo zniekształca dane poprzez dodawanie szumu, oraz w tył (ang. _reverse chain_), przekształcający szum z powrotem w ustrukturyzowane dane @yang2025diffusionmodelscomprehensivesurvey.

Proces w przód, nazywany również procesem dyfuzji, stopniowo degraduje oryginalne dane $x_0$ poprzez dodawanie szumu gaussowskiego w ciągu $T$ kroków czasowych. W każdym kroku przejście nakłada szum zgodnie z określonym harmonogramem wariancji $beta_t$, co matematycznie opisuje rozkład warunkowy @ho2020denoisingdiffusionprobabilisticmodels:
$
  q(x_t|x_(t-1))=cal(N)(x_t;sqrt(1-beta_t)x_(t-1),beta_t upright(bold(I)))
$
Intuicyjnie proces ten, stopniowo wprowadzając szum, doprowadza do całkowitej utraty pierwotnej struktury danych, przekształcając ich rozkład w standardowy rozkład Gaussa. Istotną zaletą tego procesu jest możliwość wyrażenia go w postaci zamkniętej. Oznacza to, że można bezpośrednio wygenerować próbkę $x_t$ w dowolnym kroku czasowym $t$, bez konieczności obliczania kroków pośrednich @ho2020denoisingdiffusionprobabilisticmodels @yang2025diffusionmodelscomprehensivesurvey.

Proces w tył (odszumianie) jest procesem odwrotnym, odpowiedzialnym za generowanie nowych danych. Rozpoczyna się od próbkowania losowego wektora szumu ze standardowego rozkładu Gaussa, a następnie stopniowego usuwania szumu poprzez realizację wyuczonego łańcucha Markowa wstecz od kroku $T$ do $1$. Ponieważ proces w przód w każdym kroku wprowadza niewielkie ilości szumu, przejścia odwrotne również można modelować jako warunkowe rozkłady Gaussa. Te wyuczalne przejścia są parametryzowane przez głębokie sieci neuronowe i opisywane równaniem @ho2020denoisingdiffusionprobabilisticmodels @yang2025diffusionmodelscomprehensivesurvey:
$
  p_theta(x_(t-1)|x_t) = cal(N)(x_(t-1);mu_theta(x_t, t), Sigma_theta(x_t, t))
$
gdzie sieć estymuje wartość średnią oraz wariancję w celu odtworzenia obrazu o mniejszym poziomie szumu. W praktyce, zamiast bezpośredniej estymacji parametrów rozkładu $mu_theta$ oraz $Sigma_theta$, sieć jest najczęściej trenowana do przewidywania szumu gaussowskiego, który został dodany do czystych danych w kroku $t$.

W klasycznych modelach dyfuzyjnych zmienne pośrednie mają ten sam wymiar co dane wejściowe. Aby zniwelować wynikające z tego ograniczenia obliczeniowe, stosuje się dyfuzję w przestrzeni ukrytej (ang. _Latent Diffusion Models_, LDMs) @yang2025diffusionmodelscomprehensivesurvey. Podejście to opiera się na hipotezie rozmaitości (ang. _manifold hypothesis_), zakładającej, że naturalne sygnały leżą na podprzestrzeniach o znacznie niższym wymiarze. Modele LDM wykorzystują autoenkoder do skompresowania wysokowymiarowych danych w ciągłą reprezentację ukrytą (ang. _latent space_). Właściwy proces dyfuzji odbywa się wyłącznie w tej skompresowanej przestrzeni, a dekoder mapuje odszumiony wektor ukryty z powrotem do przestrzeni pikseli, co znacząco redukuje zapotrzebowanie na pamięć i moc obliczeniową @yang2025diffusionmodelscomprehensivesurvey.

== Transformer wizyjny

Architektura Transformer znalazła skuteczne zastosowanie również w wizji komputerowej jako Transformer wizyjny (ang. _Vision Transformer_, ViT) @dosovitskiy2021imageworth16x16words. Zamiast wykorzystywać filtry splotowe, ViT dzieli obraz na łatki (*patches*) i traktuje je analogicznie do tokenów słów w modelach NLP.

Dane wejściowe $x in RR^(H times W times C)$ są dzielone na sekwencję łat $x in RR^(N times (P^2 dot C))$, gdzie $(H, W)$ to rozdzielczość obrazu, $C$ to liczba kanałów, $P$ to rozmiar łaty, a $N = (H W) / P^2$ to wyjściowa liczba łat stanowiąca długość sekwencji wejściowej dla Transformera. Następnie każda łata jest rzutowana liniowo do wymiaru ukrytego $D$, a do uzyskanych wektorów dodawane są wyuczalne osadzenia pozycyjne w celu zachowania informacji o strukturze przestrzennej. Tak przygotowane osadzenia trafiają do enkodera Transformera. Po przetworzeniu sekwencji konieczne jest jej ponowne odwzorowanie do przestrzeni pikseli. Zazwyczaj wykorzystuje się do tego konwolucję podpikselową (ang. _pixel shuffle_). Metoda ta reorganizuje elementy wyjściowych map cech poprzez przekształcenie głębokości w wymiary przestrzenne (ang. _depth-to-space_), pozwalając na odtworzenie wysokiej rozdzielczości bez wprowadzania dodatkowych trenowalnych parametrów @Baniya_2024.

Adaptacja ViT do superrozdzielczości wideo polega na rozszerzeniu podziału na płaty do przestrzeni trójwymiarowej, co umożliwia jednoczesne modelowanie relacji przestrzennych i czasowych. Poprzez zastosowanie mechanizmu samouwagi (ang. _Self-Attention_), modele VSR dynamicznie szacują istotność różnych klatek wewnątrz analizowanego okna czasowego, co pozwala wyselekcjonować najbardziej informatywne fragmenty z sąsiednich klatek i wykorzystać je do precyzyjnej rekonstrukcji detali @Baniya_2024.

== Transformer dyfuzyjny

Połączenie zalet modeli dyfuzyjnych w przestrzeni ukrytej (LDM) oraz skalowalności architektury ViT doprowadziło do powstania transformerów dyfuzyjnych (ang. _Diffusion Transformer_, DiT) @peebles2023scalablediffusionmodelstransformers. W przeciwieństwie do klasycznych modeli LDM, które wykorzystują splotowe sieci typu U-Net jako kręgosłup (ang. _backbone_) procesu odszumiania, architektura DiT zastępuje je enkoderem opartym na Transformerze.

Przetwarzanie w DiT rozpoczyna się od skompresowania obrazu do przestrzeni ukrytej za pomocą zamrożonego, wstępnie wytrenowanego autoenkodera (np. VAE). Na tak uzyskanej reprezentacji $z_0$ aplikowany jest proces dyfuzji, a zaszumiony wektor ukryty $z_t$ dzielony jest na siatkę płatów. Następnie są one rzutowane liniowo na sekwencję tokenów i wzbogacane o sinusoidalne osadzenia pozycyjne. Kluczową innowacją architektury DiT jest sposób wstrzykiwania informacji warunkujących, takich jak krok czasowy $t$ czy etykieta klasy $c$. Do tego celu wykorzystuje się zmodyfikowane bloki z adaptacyjną normalizacją warstwową (ang. _adaptive layer normalization_, adaLN-Zero). Zamiast standardowej normalizacji, sieć regresuje parametry skali i przesunięcia $(gamma, beta)$ oraz skalar przeskalowujący $alpha$ bezpośrednio z sumy wektorów osadzeń warunków. Po przejściu przez bloki DiT, wyjściowa sekwencja tokenów jest dekodowana liniowo i reorganizowana do pierwotnego kształtu reprezentacji ukrytej, skąd dekoder przekształca ją z powrotem do przestrzeni pikseli @peebles2023scalablediffusionmodelstransformers.

Głównym wyzwaniem w adaptacji architektur DiT do zadań superrozdzielczości wideo jest potrzeba uwarunkowania procesu generatywnego nagraniem LR. W modelach VSR opartych na DiT (takich jak _FlashVSR_) sekwencja HR nie jest generowana z czystego szumu; zamiast tego do sterowania odtwarzaniem detali wykorzystuje się wideo LR. Wbudowywanie warunku realizuje się m.in. poprzez rzutowanie klatek LR za pomocą lekkiej warstwy konwolucyjnej (_Proj-In_) i dodanie tak uzyskanych cech do tokenów jako osadzenia warunkujące @Zhuang2025FlashVSRTR.

== Optymalizacje mechanizmu uwagi

Standardowy mechanizm uwagi oparty na iloczynie skalarnym ze skalowaniem (_Scaled Dot-Product Attention_) stanowi fundament architektury Transformer. Odwzorowuje on zapytania ($Q$), klucze ($K$) oraz wartości ($V$) na wektor wyjściowy zgodnie z zależnością @vaswani2023attentionneed:

$ "Attention"(Q, K, V) = "softmax"((Q K^T) / sqrt(d_k)) V $

gdzie $d_k$ oznacza wymiarowość kluczy, a dzielenie przez $sqrt(d_k)$ zapobiega zanikaniu gradientów dla dużych wartości iloczynu skalarnego. Mimo że operacja ta opiera się na wydajnych mnożeniach macierzowych, charakteryzuje się kwadratową złożonością obliczeniową i pamięciową $O(N^2)$ względem długości sekwencji $N$. Wynika to z konieczności bezpośredniego zapisywania pełnej, pośredniej macierzy macierzy uwagi w pamięci karty graficznej @dao2022flashattentionfastmemoryefficientexact.

=== FlashAttention

_FlashAttention_ @dao2022flashattentionfastmemoryefficientexact niweluje ograniczenia pamięciowe poprzez algorytm optymalizujący przepływ danych, nie wprowadzając przy tym żadnych aproksymacji. Zamiast zapisywać pośrednią macierz uwagi w wolniejszej pamięci HBM (ang. _High Bandwidth Memory_), algorytm stosuje technikę kafelkowania (ang. _tiling_). Bloki macierzy $Q$, $K$ i $V$ są ładowane do znacznie szybszej pamięci podręcznej SRAM na chipie GPU, gdzie stopniowo obliczana jest redukcja _softmax_, a do pamięci HBM zapisywany jest jedynie ostateczny wynik.

=== SageAttention

_SageAttention_ @zhang2025sageattentionaccurate8bitattention przyspiesza inferencję, wykorzystując kwantyzację. Ponieważ operacje mnożenia macierzy w formacie INT8 na nowoczesnych jednostkach GPU są znacznie szybsze niż w formatach FP16 czy FP8, metoda kwantyzuje macierze $Q$ i $K$ do formatu INT8, pozostawiając macierze $P$ (macierz wag uwagi po operacji _softmax_) oraz $V$ w formacie FP16. Aby zapobiec utracie dokładności wynikającej z ograniczonego zakresu liczbowego, wprowadzono technikę wygładzania usuwającą wartości odstające z macierzy $K$.

Wersja _SageAttention2_ @zhang2025sageattention2efficientattentionthorough wprowadza jeszcze szybszą kwantyzację INT4 dla $Q$ i $K$ oraz kwantyzację FP8 dla $P$ i $V$, łącząc to z kompleksowym wygładzaniem wartości odstających dla obu macierzy $Q$ i $K$.

=== Block Sparse Attention: Odrzucanie redundantnych interakcji

_Block Sparse Attention_ to metoda aproksymacyjna redukująca złożoność poprzez odrzucanie nadmiarowych obliczeń. Zamiast pełnych interakcji uwaga ograniczana jest wyłącznie do wybranych, niezerowych bloków.

Przykładowo, w modelach takich jak _FlashVSR_, algorytm najpierw wyznacza przybliżoną mapę uwagi poprzez uśrednianie (ang. _average pooling_) cech kluczy i wartości w celu uzyskania reprezentacji blokowych. Następnie wybierana jest grupa $k$ najbardziej istotnych par bloków (ang. _top-k_), a pełny mechanizm uwagi aplikowany jest wyłącznie do tych obszarów. Integracja tej metody z _FlashAttention_ pozwala obniżyć złożoność operacji wejścia/wyjścia proporcjonalnie do współczynnika rzadkości @dao2022flashattentionfastmemoryefficientexact.

=== SpargeAttention

_SpargeAttention_ @zhang2025spargeattentionaccuratetrainingfreesparse to uniwersalna metoda niewymagająca ponownego trenowania, która łączy cechy uwagi rzadkiej oraz kwantyzacji w celu przyspieszenia predykcji bez utraty jakości modelu. Działając w oparciu o szkielet _SageAttention_, wykorzystuje dwuetapowy filtr do pomijania zbędnych mnożeń macierzowych. W pierwszym etapie bloki $Q$ oraz $K$ wykazujące wysokie podobieństwo są kompresowane do pojedynczych tokenów, co pozwala na szybsze i bardziej precyzyjne przewidywanie oraz maskowanie rzadkich obszarów na mapie uwagi. W drugim etapie algorytm _sparse warp online softmax_ pomija obliczanie iloczynu $P V$, jeśli lokalna wartość maksymalna w danym bloku jest znacząco mniejsza od wartości maksymalnej w skali globalnej, skutecznie ignorując mało znaczące wartości.


== Kwantyzacja całkowitoliczbowa

Kwantyzacja całkowitoliczbowa (ang. _Integer Quantization_) polega na konwersji wartości o wysokiej precyzji (np. FP32) na nisko-precyzyjne formaty całkowitoliczbowe (np. INT8), co przyspiesza inferencję poprzez wykorzystanie dedykowanych jednostek obliczeniowych i redukcję zapotrzebowania na pamięć. Proces ten opiera się na operacji kwantyzacji, czyli mapowaniu wartości rzeczywistych na całkowite, oraz dekwantyzacji, odpowiedzialnej za odtworzenie wartości przybliżonych @wu2020integerquantizationdeeplearning.

=== Mechanizmy mapowania

Jednostajna kwantyzacja przekształca rzeczywiste wartości $x in [beta, alpha]$ na $b$-bitowe reprezentacje całkowitoliczbowe $x_q$. Przekształcenie to opiera się na transformacji afinicznej (ang. _affine quantization_) $f(x) = s dot x + z$ lub jej szczególnym przypadku - transformacji skalowanej (ang. _scale quantization_) $f(x) = s dot x$ @wu2020integerquantizationdeeplearning.

Kwantyzacja afiniczna mapuje zakres rzeczywisty na przedział ze znakiem $[-2^(b-1), 2^(b-1)-1]$ przy użyciu skali $s = (2^b - 1) / (alpha - beta)$ oraz całkowitoliczbowego punktu zerowego $z = -text("round")(beta dot s) - 2^(b-1)$, odpowiedzialnego za dokładne odwzorowanie wartości zero. Samą kwantyzację oraz dekwantyzację definiuje się wzorami:
$ x_q = text("clip")(text("round")(s dot x + z), -2^(b-1), 2^(b-1)-1), quad hat(x) = 1/s (x_q - z) $

Kwantyzacja skalowana (w wariancie symetrycznym) zakłada symetrię przedziału wejściowego $[-alpha, alpha]$ oraz zakresu bitowego wokół zera (dla INT8 jest to $[-127, 127]$, bez wartości $-128$). Przy skali $s = (2^(b-1) - 1) / alpha$, operacje przyjmują postać:
$ x_q = text("clip")(text("round")(s dot x), -2^(b-1)+1, 2^(b-1)-1), quad hat(x) = 1/s x_q $

=== Kwantyzacja wag (Weights)

Ponieważ wagi podczas inferencji są statyczne, wyznaczanie ich parametrów kwantyzacji odbywa się w trybie offline. W tym celu stosuje się kwantyzację kanałową (ang. _per-channel_), która zachowuje dokładność modelu przy zróżnicowanych rozkładach cech pomiędzy kanałami. Zakres wartości $alpha$ i $beta$ określa się zazwyczaj za pomocą kalibracji bazującej na maksymalnej wartości (_max calibration_), przy czym zdecydowanie preferuje się wariant symetryczny, ponieważ brak współczynnika $z$ eliminuje dodatkowy narzut obliczeniowy podczas mnożenia macierzy @wu2020integerquantizationdeeplearning.

=== Kwantyzacja aktywacji

Dynamiczna natura aktywacji wymusza odmienne podejście do wyznaczania zakresów mapowania. Aby umożliwić wydajne mnożenie macierzy, aktywacje kwantyzuje się na poziomie całego tensora (_per-tensor_). Ze względu na częstą obecność wartości odstających, zamiast kalibracji maksymalnej stosuje się kalibrację entropijną lub percentylową, co zapobiega spychaniu większości poprawnych wartości do zbyt wąskiego przedziału bitowego.

Połączenie symetrycznej kwantyzacji _per-channel_ dla wag oraz kwantyzacji _per-tensor_ z kalibracją entropijną lub percentylową dla aktywacji pozwala na prowadzenie obliczeń w pełni na arytmetyce INT8 przy dokładności zbliżonej do modelu bazowego FP32 @wu2020integerquantizationdeeplearning.


=== Metryki oceny jakości obrazu i wideo

W celu przeprowadzenia kompleksowej ewaluacji jakości wygenerowanych sekwencji wideo zastosowano zestaw siedmiu metryk badawczych, obejmujący zarówno tradycyjne wskaźniki pełnoreferencyjne (ang. _Full-Reference_), jak i zaawansowane metryki percepcyjne oraz bezreferencyjne (ang. _No-Reference_).

==== Metryki pełnoreferencyjne

Metryki pełnoreferencyjne wymagają bezpośredniego porównania wygenerowanej klatki lub sekwencji ze źródłowym materiałem referencyjnym (ang. _Ground Truth_, GT).

Stosunek sygnału szczytowego do szumu (PSNR, ang. _Peak Signal-to-Noise Ratio_) @psnr jest obiektywną metryką wyznaczającą stosunek maksymalnej możliwej wartości sygnału do błędu średniokwadratowego na poziomie poszczególnych pikseli. Mimo powszechnego stosowania w literaturze, metryka ta zakłada niezależność pikseli i wykazuje niską korelację z ludzką percepcją jakości wizualnej @Baniya_2024.

Wskaźnik podobieństwa strukturalnego (SSIM, ang. _Structural Similarity Index Measure_) @ssim ocenia podobieństwo strukturalne między obrazami na podstawie analizy trzech komponentów: jasności (luminancji), kontrastu oraz informacji strukturalnej. Wartości metryki zawierają się w przedziale $[-1, 1]$, gdzie wartość $1$ oznacza idealną zgodność. Choć SSIM lepiej odzwierciedla percepcję wzrokową niż PSNR, może dawać sprzeczne z intuicją wyniki w sytuacjach znacznych różnic kolorystycznych lub w bardzo ciemnych scenach @Baniya_2024.

Głęboka percepcyjna miara podobieństwa fragmentów obrazu (LPIPS, ang. _Learned Perceptual Image Patch Similarity_) @lpips mierzy percepcyjną odmienność wizualną z wykorzystaniem cech wysokiego poziomu, wyekstrahowanych z głębokiej sieci neuronowej (np. VGG-16). Dzięki wykorzystaniu reprezentacji wyuczonych na dużych zbiorach danych, LPIPS odzwierciedla subiektywne oceny ludzkie w stopniu znacznie wyższym niż klasyczne miary pikselowe @Baniya_2024.

==== Metryki bezreferencyjne

Metryki bezreferencyjne dokonują oceny jakości lub estetyki obrazu oraz wideo bez konieczności dostępu do materiału wzorcowego.

Naturalny ewaluator jakości obrazu (NIQE, ang. _Natural Image Quality Evaluator_) @niqe ocenia stopień naturalności i zniekształceń obrazu poprzez ekstrakcję cech statystycznych (takich jak dane o jasności, kontraście czy krawędziach) i ich dopasowanie do wielowymiarowego rozkładu Gaussa. Metryka ta może jednak wykazywać niestabilność lub generować błędne wyniki w przypadku treści nietypowych, takich jak całkowicie czarne klatki, grafika komputerowa czy specyficzne tekstury o wysokiej częstotliwości.

Wieloskalowy transformer jakości obrazu (MUSIQ, ang. _Multi-scale Image Quality Transformer_) @musiq jest bezreferencyjną metryką opartą na architekturze Transformer, dedykowaną do przetwarzania obrazów w ich natywnej rozdzielczości. Dzięki wieloskalowej analizie obrazu podzielonego na fragmenty, MUSIQ eliminuje potrzebę przeskalowywania lub przycinania wejścia, precyzyjnie wychwytując zarówno globalną strukturę, jak i lokalne detale.

CLIPIQA @clipiqa wykorzystuje przestrzeń wizyjno-językową modeli wstępnie wytrenowanych CLIP do oceny zarówno aspektów technicznych, jak i właściwości estetycznych obrazu. Metryka ta nie wymaga ręcznie projektowanych cech ani dedykowanego uczenia pod konkretne zadanie, lecz wyznacza jakość poprzez pomiar dopasowania obrazu do przeciwstawnych promptów tekstowych (np. _"Good photo"_ vs. _"Bad photo"_).

DOVER (ang. _Disentangled Objective Video Quality Evaluator_) @dover stanowi wyspecjalizowaną metrykę oceny jakości sekwencji wideo. Konstrukcja DOVER pozwala na predykcję subiektywnego doświadczenia jakości użytkownika w zróżnicowanych nagraniach wideo poprzez niezależne rozdzielenie analizy na aspekt estetyczny (jakość przestrzenna) oraz techniczny (spójność czasowa i płynność ruchu).
