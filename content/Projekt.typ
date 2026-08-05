#import "../utils.typ": flex-caption, silentheading, todo

= Środowisko i projekt systemu
<srodowisko-i-projekt-systemy>

== Platforma sprzętowa
<platforma-sprzętowa>
Badania zrealizowano na dwóch stanowiskach sprzętowych o odmiennych rolach. Główną platformą docelową była karta NVIDIA GeForce RTX 3080 (10 GB VRAM, architektura Ampere, compute capability 8.6) zainstalowana w komputerze z procesorem AMD Ryzen 5 5600X oraz 32 GB pamięci RAM - pojemność RAM ma  kluczowe znaczenie, gdyż trafiają do niej wyniki pośrednie. Wybrane GPU reprezentuje segment kart konsumenckich, dla których domyślne zapotrzebowanie FlashVSR przekracza dostępny budżet pamięci.

Pomocniczo wykorzystano akcelerator NVIDIA A100, wyposażony w 80 GB pamięci. Uruchomiono na nim konfigurację referencyjną, bez kafelkowania przestrzennego, której zapotrzebowanie na pamięć przekracza budżet karty docelowej. Podział zadań między obie platformy oraz wynikające z niego zastrzeżenia opisano w @metodyka-badan-i-testy[rozdziale].

== Środowisko programistyczne
<środowisko-programistyczne>
System zaimplementowano w języku Python w wersji 3.11, z wykorzystaniem biblioteki PyTorch 2.10 skompilowanej dla CUDA 12.8. Do zarządzania zależnościami wykorzystano narzędzie `uv`, które zapisuje pełny stan środowiska w pliku blokującym wersje. Zapewnia to odtwarzalność instalacji, istotną przy tak dużej liczbie komponentów wymagających kompilacji ze źródeł.

Trzy biblioteki realizujące warianty mechanizmu uwagi - `block_sparse_attn`, `sageattention` oraz `spas_sage_attn` - instalowane są bezpośrednio z repozytoriów źródłowych i wymagają kompilacji jąder CUDA. Ich instalacja wymagała ustawienia zmiennych środowiskowych określających docelowe architektury GPU oraz wskazania kompilatora w wersji zgodnej z wymaganiami narzędzia `nvcc`. Proces ten zautomatyzowano skryptem powłoki. Pozostałe istotne zależności to `torchao` w wersji 0.16 (kwantyzacja), `torchcodec` i `av` (dekodowanie i kodowanie materiału wideo) oraz `pyiqa` (metryki jakości obrazu).

Implementacja referencyjna metryki DOVER wymaga biblioteki PyTorch w wersji sprzed 2.0, niezgodnej z pozostałymi komponentami, dlatego uruchamiano ją w wydzielonym środowisku wirtualnym.

== Architektura pakietu
<architektura-pakietu>
Implementacja referencyjna modelu FlashVSR ma postać zbioru skryptów, w których konfiguracja jest zapisana na stałe w kodzie, co uniemożliwia wygodne porównywanie wariantów. Kod zrefaktoryzowano zatem do postaci pakietu o wyraźnie rozdzielonych warstwach odpowiedzialności.

Warstwa `config` zawiera struktury opisujące konfigurację przetwarzania: tryb uwagi, tryb kwantyzacji, parametry kafelkowania przestrzennego i czasowego oraz parametry wejścia i wyjścia. Warstwa `models` obejmuje komponenty modelu: transformer dyfuzyjny, autoenkoder oraz lekki dekoder warunkowy. Warstwa `pipelines` zawiera właściwy potok inferencji, warstwa `processing` odpowiada za jego inicjalizację i orkiestrację przetwarzania nagrania, a warstwa `utils` gromadzi funkcje pomocnicze obliczające podział na kafle, maski mieszania i wymagane wymiary danych.

Poza rdzeniem pakietu wydzielono cztery moduły pomocnicze: `benchmarks` z narzędziami pomiarowymi, `scripts` ze skryptami przetwarzania wsadowego i przygotowania danych, `app` z aplikacją pokazową oraz `tests` z testami jednostkowymi.

Istotnym założeniem projektowym jest oddzielenie budowy potoku od jego wykonania. Inicjalizacja obejmuje wczytanie wag, wybór wariantów uwagi oraz ewentualną kwantyzację, jest więc kosztowna czasowo i pamięciowo. Zbudowany potok może natomiast przetworzyć wiele nagrań bez ponownej inicjalizacji.

== Przepływ przetwarzania
<przepływ-przetwarzania>
Przetwarzanie nagrania przebiega w kilku etapach: dekodowanie materiału wejściowego, dopełnienie liczby klatek, podział na segmenty czasowe, podział każdego segmentu na kafle przestrzenne, inferencja, złożenie wyników i zapis. Mechanizmy realizujące poszczególne etapy opisano w @implementacja[rozdziale].

Kluczową decyzją projektową jest przenoszenie wyniku każdego kafla poza pamięć karty graficznej bezpośrednio po jego przetworzeniu. Na karcie znajdują się jednocześnie wyłącznie wagi modelu, pamięć podręczna kluczy i wartości oraz aktywacje jednego kafla, natomiast płótna akumulacyjne obejmujące jeden segment czasowy utrzymywane są w pamięci operacyjnej.


== Interfejsy systemu
<interfejsy-systemu>
Rdzeń systemu udostępniono przez trzy niezależne punkty wejścia, korzystające z tej samej implementacji potoku.

Pierwszym jest uruchomienie z wiersza poleceń, przeznaczone do przetwarzania pojedynczego nagrania. Drugim jest skrypt przetwarzania wsadowego, stosowany przy generowaniu wyników dla całych zbiorów testowych. Trzecim jest aplikacja pokazowa, złożona z usługi sieciowej zbudowanej w oparciu o bibliotekę FastAPI oraz interfejsu przeglądarkowego wykorzystującego bibliotekę Gradio.

Usługa sieciowa przyjmuje zlecenia przetwarzania wraz z pełną konfiguracją i obsługuje je asynchronicznie. Zlecenia trafiają do kolejki, z której pobiera je pojedynczy proces roboczy. Rozwiązanie takie jest konieczne, ponieważ równoległe przetwarzanie wielu nagrań przekroczyłoby budżet pamięci karty. Proces utrzymuje zbudowany potok między kolejnymi zleceniami i odtwarza go jedynie wtedy, gdy zmieni się konfiguracja uwagi lub kwantyzacji. Klient może sprawdzać stan zlecenia i pobrać wynik po zakończeniu przetwarzania.

== Jakość kodu
<jakość-kodu>
Moduły pomocnicze odpowiedzialne za wyznaczanie podziału na kafle, generowanie masek mieszania oraz obliczanie wymaganych wymiarów danych objęto testami jednostkowymi z wykorzystaniem biblioteki `pytest`. Są to funkcje obliczeniowe, których poprawność decyduje o braku artefaktów w materiale wyjściowym, a jednocześnie dające się testować bez dostępu do karty graficznej. Statyczną analizę kodu i jego formatowanie realizuje narzędzie `ruff`.
