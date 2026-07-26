#import "../utils.typ": flex-caption, silentheading, todo

= Przegląd istniejących rozwiązań

== Metody konwolucyjne i rekurencyjne

Metody konwolucyjne realizują zadanie VSR poprzez podział wideo na nakładające się na siebie segmenty, co umożliwia równoległe przetwarzanie sąsiednich klatek w celu rekonstrukcji klatki docelowej. Reprezentatywny dla tej klasy model _EDVR_ @wang2019edvrvideorestorationenhanced wykorzystuje konwolucje deformowalne do adaptacyjnego dopasowania cech przy złożonym ruchu, oraz moduł TSA (_Temporal and Spatial Attention_) do fuzji informacji. Architektury konwolucyjne cechują się dużą stabilnością uczenia i odpornością na dynamiczne zmiany w scenie. Cierpią jendak na ograniczony zasięg kontekstu czasowego oraz wysoki narzut pamięciowy wynikający z wielokrotnego przetwarzania tych samych klatek. Ponadto niezależna rekonstrukcja kolejnych okien sprzyja powstawaniu artefaktów @Baniya_2024 @liu2022videosuperresolutionbased.

Metody rekurencyjne (RNN) traktują wideo jako ciągły strumień danych i przekazują ukryty stan pamięci pomiędzy kolejnymi krokami czasowymi, co pozwala na modelowanie długoterminowych zależności.
W modelu _BasicVSR_ @chan2021basicvsrsearchessentialcomponents zastosowano dwukierunkową propagację danych w czasie oraz moduł wyrównywania cech oparty na przepływie optycznym (ang. _optical flow_), który wyrównuje cechy przed przekazaniem ich do bloku rezydualnego. Pozwala to sieci na efektywne uwzględnianie informacji z całej sekwencji. Główną wadą dwukierunkowych metod rekurencyjnych pozostaje jednak wymóg znajomości całego wideo z góry oraz ryzyko stopniowego kumulowania i propagowania błędów rekonstrukcji @Baniya_2024 @liu2022videosuperresolutionbased.

== Metody transformerowe

Transformery w VSR wykorzystują mechanizmy samouwagi (ang. _self-attention_) do dynamicznego ważenia i modelowania relacji czasowych wzdłuż całej sekwencji @Baniya_2024. Przykładowo, model _VSRT_ @cao2023videosuperresolutiontransformer posiada moduł STCSA (_Spatial-Temporal Convolutional Self-Attention_) do ekstrakcji lokalnych cech przestrzennych oraz dwukierunkową warstwę BOFF (_Bidirectional Optical Flow-Based Feed-Forward_), opartą na przepływie optycznym, do wyrównywania cech między klatkami. Alternatywne podejście reprezentuje _VRT_ @liang2022vrtvideorestorationtransformer, który zamiast przetwarzać klipy sekwencyjnie, rekonstruuje je równoległe. Wykorzystuje on moduł TMSA (_Temporal Mutual Self-Attention_) do jednoczesnej estymacji ruchu, wyrównywania i fuzji cech.

Kluczową zaletą metod opartych na transformerach jest ich zdolność do bezstratnego wychwytywania długoterminowych zależności czasowych oraz możliwość równoległego przetwarzania klatek, co pozwala wyeliminować wąskie gardło rekurencji @liang2022vrtvideorestorationtransformer. Głównym ograniczeniem pozostaje jednak bardzo wysoka złożoność obliczeniowa i ogromne zapotrzebowanie na pamięć w porównaniu z klasycznymi sieciami CNN @Baniya_2024.


