Rozumiem — chodziło o zwięzłe sformułowania, nie o spłaszczenie struktury. Poniżej trzy poziomy, ale z krótkimi tytułami i bez rozdrabniania na jednozdaniowe punkty.

---

## Streszczenie
## Abstract

## 1. Wstęp
1.1. Motywacja i sformułowanie problemu
1.2. Cel i zakres pracy
1.3. Układ pracy

## 2. Podstawy teoretyczne
2.1. Superrozdzielczość wideo
 2.1.1. Sformułowanie zadania i modele degradacji
 2.1.2. Spójność czasowa
2.2. Modele dyfuzyjne
 2.2.1. Proces zaszumiania i odszumiania
 2.2.2. Flow matching
 2.2.3. Dyfuzja w przestrzeni latentnej
2.3. Diffusion Transformer i mechanizm uwagi
 2.3.1. Uwaga skalowana iloczynem skalarnym
 2.3.2. FlashAttention
 2.3.3. SageAttention
 2.3.4. Rzadkość strukturalna i maski blokowe
2.4. Kwantyzacja sieci neuronowych
 2.4.1. Kwantyzacja wag a kwantyzacja aktywacji
 2.4.2. Tryby weight-only i dynamic
 2.4.3. Wsparcie INT8 na architekturze Ampere
2.5. Kafelkowanie przestrzenne i czasowe
2.6. Metryki oceny jakości wideo
 2.6.1. Metryki pełnoreferencyjne
 2.6.2. Metryki bezreferencyjne
 2.6.3. Ograniczenia metryk dla modeli generatywnych

## 3. Przegląd istniejących rozwiązań
3.1. Metody konwolucyjne i rekurencyjne
3.2. Metody transformerowe
3.3. Wielokrokowe metody dyfuzyjne
3.4. FlashVSR jako punkt odniesienia
 3.4.1. Architektura i potok inferencji
 3.4.2. Wymagania sprzętowe a faktyczne zużycie VRAM
 3.4.3. Istniejące integracje i ich ograniczenia
3.5. Zestawienie porównawcze i identyfikacja luki badawczej

## 4. Wybór rozwiązań do implementacji
4.1. Uzasadnienie wyboru modelu bazowego
4.2. Analiza źródeł zużycia pamięci
4.3. Wybór technik optymalizacji
 4.3.1. Warianty mechanizmu uwagi
 4.3.2. Kwantyzacja INT8
 4.3.3. Kafelkowanie
 4.3.4. Rozwiązania rozważane i odrzucone
4.4. Wybór zbiorów testowych i metryk oceny
4.5. Plan eksperymentów

## 5. Narzędzia, środowisko i projekt systemu
5.1. Sprzęt testowy i środowisko obliczeniowe
5.2. Stos technologiczny i narzędzia deweloperskie
5.3. Architektura zrefaktoryzowanego repozytorium
5.4. Model konfiguracji przetwarzania
5.5. Projekt warstwy aplikacyjnej i formatu wyników

## 6. Implementacja
6.1. Struktura pakietu i potok inferencji
 6.1.1. Menedżer modeli i wczytywanie wag
 6.1.2. VAE, DiT i TCDecoder
 6.1.3. Harmonogram flow matching
6.2. Wielobackendowy mechanizm uwagi
 6.2.1. Interfejs wyboru backendu
 6.2.2. Backendy FlashAttention i SageAttention
 6.2.3. Maski blokowo-rzadkie i tryb sparse_sage
6.3. Kwantyzacja INT8 z wykorzystaniem torchao
6.4. Kafelkowanie przestrzenne i czasowe
 6.4.1. Wyznaczanie kafli z zakładką i mieszanie obszarów
 6.4.2. Podział czasowy i korekcja kolorystyczna
6.5. Warstwa aplikacyjna i skrypty eksperymentalne
6.6. Problemy implementacyjne
 6.6.1. Kompilacja jąder CUDA i konflikty wersji środowiska
 6.6.2. Izolacja środowiska dla metryki DOVER
 6.6.3. Artefakty na granicach kafli

## 7. Metodyka badań i testy
7.1. Przygotowanie danych testowych
 7.1.1. Degradacja HQ→LQ dla YouHQ40
 7.1.2. Charakterystyka zbioru VideoLQ
7.2. Testy jednostkowe i weryfikacja poprawności
7.3. Metodyka pomiaru wydajności
7.4. Metodyka oceny jakości
7.5. Zestawienie przeprowadzonych eksperymentów

## 8. Wyniki i ich omówienie
8.1. Zużycie pamięci i warunki uruchomienia na GPU 10 GB
8.2. Porównanie wariantów mechanizmu uwagi
8.3. Wpływ kwantyzacji INT8
 8.3.1. Tryb weight-only
 8.3.2. Tryb dynamic i narzut kwantyzacji aktywacji
8.4. Jakość rekonstrukcji
 8.4.1. Zbiór YouHQ40
 8.4.2. Zbiór VideoLQ
 8.4.3. Wpływ kafelkowania na jakość
8.5. Kompromis jakość–wydajność–pamięć
8.6. Porównanie z wynikami autorów FlashVSR
8.7. Dyskusja i ograniczenia badań

## 9. Podsumowanie i wnioski
9.1. Syntetyczne zestawienie najistotniejszych elementów pracy
9.2. Stopień realizacji celów
9.3. Rekomendowana konfiguracja dla GPU 10 GB
9.4. Ograniczenia i kierunki dalszych prac

## Bibliografia
## Spis rysunków
## Spis tabel

## Dodatek A. Instrukcja instalacji i uruchomienia
## Dodatek B. Specyfikacja API i opis interfejsu użytkownika
## Dodatek C. Pełne tabele wyników
## Dodatek D. Zawartość repozytorium i materiałów dodatkowych

---

Podpodrozdziały pojawiają się tam, gdzie faktycznie jest co rozdzielić — nie ma ich w 3.1–3.3, 5.x czy 9.x, bo tam wyszłyby sztuczne podziały. Ta asymetria jest w porządku i lepiej wygląda niż wymuszona regularność.

Jedno ostrzeżenie: przy trzech poziomach sam spis treści zajmie 2–3 strony. Jeśli wydział ma wytyczne co do jego długości, warto sprawdzić — czasem wymaga się, żeby w spisie pokazywać tylko dwa poziomy, mimo że w tekście istnieje trzeci (w LaTeX-u to `\setcounter{tocdepth}{2}`, numeracja w tekście zostaje bez zmian).