#import "../utils.typ": flex-caption, silentheading, todo

= Środowisko i projekt systemu
<srodowisko-i-projekt-systemy>

== Platforma sprzętowa
<platforma-sprzętowa>
Platformą docelową jest karta NVIDIA GeForce RTX 3080 wyposażona w 10 GB pamięci VRAM, oparta na architekturze Ampere (compute capability 8.6). Reprezentuje ona segment kart konsumenckich, dla których zapotrzebowanie modelu FlashVSR przekracza dostępny budżet pamięci. Architektura Ampere udostępnia jednostki tensorowe operujące na formacie INT8, natomiast nie wspiera formatu FP8.

Część obliczeń wykonano na akceleratorze NVIDIA A100, ze względu na czas potrzebny na przetworzenie zbiorów testowych. Uruchomiono na nim również konfigurację referencyjną, bez kafelkowania przestrzennego, której zapotrzebowanie na pamięć przekracza budżet karty docelowej. Pomiary czasu inferencji, zużycia pamięci oraz metryki jakości wyznaczano na RTX 3080, ponieważ wyniki czasowe zależą od architektury karty i nie przenoszą się między platformami.

== Środowisko programistyczne
<środowisko-programistyczne>
System zaimplementowano w języku Python w wersji 3.11, z wykorzystaniem biblioteki PyTorch 2.10 skompilowanej dla CUDA 12.8. Do zarządzanie zależnościami wykozystano narzędzie `uv`, które zapisuje pełny stan środowiska w pliku blokującym wersje. Zapewnia to odtwarzalność instalacji, istotną przy tak dużej liczbie komponentów wymagających kompilacji ze źródeł.

Trzy biblioteki realizujące warianty mechanizmu uwagi - `block_sparse_attn`, `sageattention` oraz `spas_sage_attn` - instalowane są bezpośrednio z repozytoriów źródłowych i wymagają kompilacji jąder CUDA. Ich instalacja wymagała ustawienia zmiennych środowiskowych określających docelowe architektury GPU oraz wskazania kompilatora w wersji zgodnej z wymaganiami narzędzia `nvcc`. Proces ten zautomatyzowano skryptem powłoki. Pozostałe istotne zależności to `torchao` w wersji 0.16 (kwantyzacja), `torchcodec` i `av` (dekodowanie i kodowanie materiału wideo) oraz `pyiqa` (metryki jakości obrazu).

Osobnym problemem okazała się metryka DOVER, której implementacja referencyjna wymaga biblioteki PyTorch w wersji sprzed 2.0. Wersja ta jest niezgodna z pozostałymi komponentami systemu. Metrykę tę uruchamiano zatem w wydzielonym środowisku wirtualnym, na materiale wideo zapisanym wcześniej przez główny potok. Wyniki obu środowisk łączono na etapie agregacji.

== Architektura pakietu
<architektura-pakietu>
Implementacja referencyjna modelu FlashVSR ma postać zbioru skryptów, w których konfiguracja jest zapisana na stałe w kodzie, co uniemożliwia wygodne porównywanie wariantów. Kod zrefaktoryzowano zatem do postaci pakietu o wyraźnie rozdzielonych warstwach odpowiedzialności.

Warstwa `config` zawiera struktury opisujące konfigurację przetwarzania: tryb uwagi, tryb kwantyzacji, parametry kafelkowania przestrzennego i czasowego oraz parametry wejścia i wyjścia. Warstwa `models` obejmuje komponenty modelu: transformer dyfuzyjny, autoenkoder oraz lekki dekoder warunkowy. Warstwa `pipelines` zawiera właściwy potok inferencji, warstwa `processing` odpowiada za jego inicjalizację i orkiestrację przetwarzania nagrania, a warstwa `utils` gromadzi funkcje pomocnicze obliczające podział na kafle, maski mieszania i wymagane wymiary danych.

Poza rdzeniem pakietu wydzielono cztery moduły pomocnicze: `benchmarks` z narzędziami pomiarowymi, `scripts` ze skryptami przetwarzania wsadowego i przygotowania danych, `app` z aplikacją pokazową oraz `tests` z testami jednostkowymi.

Istotnym założeniem projektowym jest oddzielenie budowy potoku od jego wykonania. Inicjalizacja obejmuje wczytanie wag, wybór wariantów uwagi oraz ewentualną kwantyzację, jest więc kosztowna czasowo i pamięciowo. Zbudowany potok może natomiast przetworzyć wiele nagrań bez ponownej inicjalizacji. Rozdzielenie to ma bezpośredni wpływ na metodykę pomiarową, ponieważ pozwala oddzielić jednorazowy koszt przygotowania modelu od kosztu właściwej inferencji.

// #strong[Rysunek 5.1.] Diagram warstw pakietu wraz z zależnościami między
// nimi.

== Przepływ przetwarzania
<przepływ-przetwarzania>
Przetwarzanie nagrania przebiega w kilku etapach. Materiał wejściowy jest dekodowany, a liczba klatek dopełniana do wartości wymaganej przez model. Wymóg ten wynika z czasowej kompresji stosowanej przez autoenkoder. Następnie sekwencja dzielona jest na segmenty czasowe, a każdy segment na kafle przestrzenne. Kafle przetwarzane są kolejno przez potok inferencji, a ich wyniki łączone maską o liniowo narastających wagach w obszarze zakładki. Ostatnim etapem jest złożenie klatek wyjściowych i zapis materiału.

Kluczową decyzją projektową jest utrzymywanie płótna wyjściowego w pamięci operacyjnej, a nie w pamięci karty graficznej. Na karcie jednocześnie znajdują się wyłącznie wagi modelu, pamięć podręczna kluczy i wartości oraz aktywacje jednego kafla. Dzięki temu szczytowe zużycie pamięci karty zależy od rozmiaru kafla, a nie od rozdzielczości nagrania wejściowego.

== Interfejsy systemu
<interfejsy-systemu>
Rdzeń systemu udostępniono przez trzy niezależne punkty wejścia, korzystające z tej samej implementacji potoku.

Pierwszym jest uruchomienie z wiersza poleceń, przeznaczone do przetwarzania pojedynczego nagrania. Drugim jest skrypt przetwarzania wsadowego, stosowany przy generowaniu wyników dla całych zbiorów testowych. Trzecim jest aplikacja pokazowa, złożona z usługi sieciowej zbudowanej w oparciu o bibliotekę FastAPI oraz interfejsu przeglądarkowego wykorzystującego bibliotekę Gradio.

Usługa sieciowa przyjmuje zlecenia przetwarzania wraz z pełną konfiguracją i obsługuje je asynchronicznie. Zlecenia trafiają do kolejki, z której pobiera je pojedynczy proces roboczy. Rozwiązanie takie jest konieczne, ponieważ równoległe przetwarzanie wielu nagrań przekroczyłoby budżet pamięci karty. Proces utrzymuje zbudowany potok między kolejnymi zleceniami i odtwarza go jedynie wtedy, gdy zmieni się konfiguracja uwagi lub kwantyzacji. Klient może sprawdzać stan zlecenia i pobrać wynik po zakończeniu przetwarzania.

== Jakość kodu
<jakość-kodu>
Moduły pomocnicze odpowiedzialne za wyznaczanie podziału na kafle, generowanie masek mieszania oraz obliczanie wymaganych wymiarów danych objęto testami jednostkowymi z wykorzystaniem biblioteki `pytest`. Są to funkcje obliczeniowe, których poprawność decyduje o braku artefaktów w materiale wyjściowym, a jednocześnie dające się testować bez dostępu do karty graficznej. Spójność stylu kodu zapewnia narzędzie `ruff`, uruchamiane w trybie kontroli i formatowania.
