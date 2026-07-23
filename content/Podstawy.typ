#import "../utils.typ": flex-caption, silentheading, todo

= Podstawy teoretyczne

== Superrozdzielczość wideo

Superrozdzielczość wideo to zadanie z zakresu widzenia komputerowego, ktorego celem jest generowanie materiałów wideo o wysokiej rozdzielczości (ang. _high-resolution_, HR) i ulepszonej jakości wizualnej na podstawie wejściowych sekwencji o niskiej rozdzielczości (ang. _low-resolution_, LR). Podstawową różnicą między VSR, a superrozdzielczością obrazów (ang. _Single Image Super-Resolution_, SISR) jest obecność w wideo dodatkowego wymiaru czasowego. SISR bazuje wyłącznie na informacji przestrzennej z pojedynczego obrazu, natomiast VSR wykorzystuje dodatkowo silne korelacje między kolejnymi klatkami. Bezpośrednie zastosowanie metod SISR do pojedynczych klatek wideo nie pozwala na uchwycenie tych zależności czasowych @Baniya_2024.

=== Sformułowanie problemu

Problem superrozdzielczości wideo jest zdefiniowany jako zadanie odwrotne, w którym dążymy do odzyskania sekwencji HR na podstawie obserwowanej sekwencji LR. Proces powstawania materiału LR jest zazwyczaj modelowany jako złożenie degradacji fizycznych i cyfrowych.

Ogólny model degradacji dla i-tej klatki wideo można zapisać jako funkcję zależną od klatki docelowej $hat(I)_i$ oraz jej sąsiedztwa czasowego @liu2022videosuperresolutionbased:

$
  I_i = phi.alt(hat(I)_i, {hat(I)_j}^(i+N)_(j=i-N)\;theta_(alpha))
$<degradation_eq>

gdzie $I_i$ oznacza obserwowaną klatkę o niskiej rozdzielczości, N oznacza promień czasowy (zakres sąsiednich klatek), a $theta_(alpha)$ reprezentuje parametry procesu degradacji (np. szum, rozmycie).

Celem modelu VSR jest znalezienie funkcji odwzorowującej $f_("VSR")$, sparametryzowanej przez wagi $theta_(f_("VSR"))$, która estymuje klatkę wysokiej rozdzielczości $hat(I)_("SR"_i)$ na podstawie sekwencji klatek wejściowych LR @liu2022videosuperresolutionbased:

$
  hat(I)_("SR"_i) = f_("VSR")(I_i, {I_j}^(i+N)_(j=i-N)\;theta_(f_("VSR")))
$<vsr_eq>

Powyższe klasyczne sformułowania zakładają uproszczone, deterministyczne zniekształcenia, które nie odzwierciedlają warunków rzeczywistych. W praktyce proces utraty jakości wymaga zaawansowanych modeli degradacji, które łączą losowe rozmycia, szum oraz zmianę rozmiaru i artefakty kompresji @chan2021investigatingtradeoffsrealworldvideo.

=== Spójność czasowa

Spójność czasowa w kontekście superrozdzielczości wideo polega na utrzymaniu ciągłości, płynności oraz braku zauważalnych zniekształceń i migotania między kolejnymi klatkami wygenerowanej sekwencji HR @Baniya_2024 @liu2022videosuperresolutionbased. Bezpośrednie zastosowanie metod SISR do poszczególnych klatek pomija zależności czasowe, co prowadzi do niestabilności detali i artefaktów wizualnych. W modelach głębokiego uczenia spójność tę realizuje się poprzez techniki wyrównywania klatek i kompensacji ruchu (ang. _motion estimation and motion compensation_, MEMC), konwolucje 3D, moduły rekurencyjne (RNN) propagujące kontekst czasowy oraz mechanizmy uwagi @Baniya_2024. Choć metody te poprawiają jakość generowanych sekwencji, analiza wielu klatek znacznie zwiększa złożoność obliczeniową i pamięciową, a w warunkach rzeczywisych stwarza to ryzyko akumulacji i przenoszenia błędów między klatkami @chan2021investigatingtradeoffsrealworldvideo.



== Modele dyfuzyjne

Modele dyfuzyjne (ang. _Denoising Diffusion Probabilistic Models_, DDPMs) to klasa modeli generatywnych, która wykorzystuje dwa podstawowe łańcuchy Markova: w przód (ang. _forward chain_), który stopniowo zniekształca dane poprzez dodawanie szumu, oraz w tył (ang. _reverse chain_), przekształcający szum spowrotem w ustrukturyzowane dane @yang2025diffusionmodelscomprehensivesurvey.

Proces w przód, nazywany również procesem dyfuzji, stopniowo degraduje oryginalne dane $x_0$ poprzez dodawanie szumu gaussowskiego w ciągu $T$ kroków czasowych. W każdym kroku czasowym kolejne przejście nakłada szum zgodnie z określonym harmonogramem wariancji $beta_t$, co matematycznie opisuje rozkład warunkowy @ho2020denoisingdiffusionprobabilisticmodels:
$
  q(x_t|x_(t-1))=cal(N)(x_t;sqrt(1-beta_t)x_(t-1),beta_t upright(bold(I)))
$
Intuicyjnie proces ten, stopniowo wprowadzając szum do danych, doprowadza do całkowitej utraty ich pierwotnej struktury. Ostatecznie rozkład danych przekształcany jest w standardowy rozkład Gaussa. Istotną i bardzo wydajną cechą tego procesu jest możliwość wyrażenia go w postaci zamkniętej. Oznacz to, że można bezpośrednio wygenerować próbkę $x_t$, w dowolnym kroku czasowym $t$, bez konieczności obliczania kroków pośrednich @ho2020denoisingdiffusionprobabilisticmodels @yang2025diffusionmodelscomprehensivesurvey.

Proces w tył (odszumianie) jest natomiast procesem przeciwnym, odpowiedzialnym za generowanie nowych danych poprzez odwracanie efektu dyfuzji. Rozpoczyna się on od próbkowania (ang. _sampling_) losowego wektora szumu ze standardowego rozkładu Gaussa. Następnie model stopniowo usuwa szum, ralizując wyuczony łańcuch Markowa wstecz w czasie od - od kroku $T$ do 1. Ponieważ proces w przód w każdym kroku wykorzystuje niewielkie ilości szumu gaussowskiego, przejścia w procesie odwrotnym można również modelować jako warunkowe rozkłady Gaussa. Te wyczualne przejścia są parametryzowane przez głębokie sieci neuronowe i można je opisać równianiem @ho2020denoisingdiffusionprobabilisticmodels @yang2025diffusionmodelscomprehensivesurvey:
$
  p_theta(X_(t-1)|x_t) = cal(N)(x_(t-1);mu_theta(x_t), Sigma_theta(x_t, t))
$
gdzie sieć przewiduje wartość średnią oraz wariancję w celu oszacowania obrazu o nieco mniejszym poziomie szumu w poprzednim kroku czasowym.

W klasyczny modelach dyfuzyjnych zmienne pośrednie mają ten sam wymiar co dane wejściowe. Żeby zniwelować ograniczenia obliczeniowe, które z tego wynikają, stosuje się dyfuzję w przestrzeni ukrytej (ang. _Latent Diffusion Models_, LDMs) @yang2025diffusionmodelscomprehensivesurvey. Podejście to opiera się na hipotezie rozmaitości (ang. _manifold hypothesis_), zakładającej, że naturalne sygnały (np. obrazy czy klatki wideo) leżą na podprzestrzeniach o znacznie niższym wymiarze. Modele LDM wykorzystują autoenkoder do skompresowania wysokowymiarowych danych w ciągłą reprezentację ukrytą (ang. _latent space_). Właściwy proces dyfuzji odbywa się wyłącznie w tej skompresowanej przestrzeni, a dekoder mapuje odszumiony wektor ukryty z powrotem do przestrzeni pikseli. Pozwala to na znaczącą redukcję zapotrzebowania na pamięć i czas obliczeń przy jednoczesnym zachowaniu wysokiej jakości i spójności generowanych danych.

== Transformery wizyjne

== Transformery dyfuzyjne

== Optymalizacje mechanizmu uwagi
=== Uwaga skalowana iloczynem skalarnym (Scaled Dot-Product Attention)
=== Algorytmy sprzętowo zoptymalizowane (FlashAttention, SageAttention)
=== Rzadkość strukturalna i maski blokowe




== Kwantyzacja sieci neuronowych
2.4.1. Kwantyzacja wag a kwantyzacja aktywacji
2.4.2. Tryby weight-only i dynamic
2.4.3. Wsparcie INT8 na architekturze Ampere
== Kafelkowanie przestrzenne i czasowe
== Metryki oceny jakości wideo
2.6.1. Metryki pełnoreferencyjne
2.6.2. Metryki bezreferencyjne
2.6.3. Ograniczenia metryk dla modeli generatywnych
