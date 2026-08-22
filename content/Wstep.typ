#import "../utils.typ": flex-caption, silentheading, todo

= Wstęp
<wstęp>

== Motywacja i sformułowanie problemu
<motywacja-i-sformułowanie-problemu>

Niniejsza praca podejmuje tematykę poprawy jakości materiałów wideo z wykorzystaniem metod sztucznej inteligencji. Szczególną uwagę poświęcono w niej technologii superrozdzielczości wideo (ang. _Video Super-Resolution_, VSR), która służy do poprawy jakości i szczegółowości nagrań o niższej rozdzielczości. Wykorzystuje się ją w wielu praktycznych zastosowaniach, począwszy od rekonstrukcji archiwalnych nagrań i skalowania skompresowanych mediów na platformach streamingowych, aż po poprawę jakości nagrań z monitoringu i badań medycznych.

Podejścia wykorzystujące głębokie uczenie do VSR od dawna bazują na architekturach splotowych i Transformerach @vaswani2023attentionneed, trenowanych z wykorzystaniem funkcji straty na poziomie pikseli. Taka funkcja sprzyja zachowawczym wartościom pikseli, czego skutkiem jest powstawanie zbyt wygładzonych obrazów, pozbawionych detali. Wykorzystanie modeli dyfuzyjnych próbuje rozwiązać te problemy. Jako metody generatywne, odtwarzają one prawdopodobne szczegóły, zamiast uśredniać możliwe rozwiązania. Przekłada się to na ostrzejsze i bardziej naturalne rezultaty. Poprawa ta ma jednak swój koszt - VSR oparte na dyfuzji jest wymagające pod względem obliczeniowym, pamięciowym oraz czasowym. Iteracyjny proces odszumiania i kwadratowa złożoność uwagi w odniesieniu do tokenów czasoprzestrzennych utrudnia praktyczne wykorzystanie.

Częściową odpowiedzią na ten problem są jednokrokowe modele uzyskiwane w wyniku destylacji wiedzy. Reprezentatywnym przykładem jest _FlashVSR_ @Zhuang2025FlashVSRTR. Twórcy modelu połączyli destylację do modelu jednokrokowego z blokowo-rzadką uwagą, aby zbliżyć się do przetwarzania w czasie rzeczywistym. Destylacja eliminuje koszt wielokrotnego odszumiania, ale nie redukuje narzutu pamięciowego w pojedynczej inferencji, który determinuje, czy model może zostać uruchomiony na danym urządzeniu.

Ten narzut stwarza istotną barierę, ponieważ dostępne modele, takie jak _FlashVSR_, zakładają wykorzystanie akceleratorów klasy serwerowej. Autorzy tego modelu wskazują, że szczytowe zużycie pamięci osiąga 11,13 GB przy 101 klatkach o rozdzielczości wyjściowej $768 times 1408$ @Zhuang2025FlashVSRTR. Oznacza to, że sekwencja wejściowa miała wymiary zaledwie $192 times 352$ przy czterokrotnym powiększeniu, czyli parametry znacząco odbiegające od rozdzielczości typowych nagrań. Konsumenckie karty graficzne oferują zazwyczaj od 8 do 12 GB pamięci VRAM; sprzęt referencyjny przyjęty w pracy, czyli NVIDIA RTX 3080, zapewnia 10 GB. Zapotrzebowanie na pamięć przekracza dostępny budżet nawet w tak korzystnym scenariuszu, a deficyt ten rośnie wraz ze wzrostem rozdzielczości wejściowej. Zasadne staje się zatem pytanie, czy taki model da się zaadaptować do pracy w limicie 10 GB VRAM, oraz ocena, jak wpłynie to na jakość generowanego wideo i czas przetwarzania.

== Cel i zakres pracy
<cel-i-zakres-pracy>

W ramach podjętej tematyki poprawy jakości wideo, głównym celem pracy jest umożliwienie inferencji jednokrokowego, dyfuzyjnego modelu superrozdzielczości wideo na karcie graficznej wyposażonej w 10 GB pamięci VRAM, przy zachowaniu akceptowalnej jakości rekonstrukcji i czasu przetwarzania. Jako model bazowy przyjęto _FlashVSR_ @Zhuang2025FlashVSRTR.

Do realizacji tego celu wymagana była refaktoryzacja kodu referencyjnej implementacji do postaci modularnego pakietu oraz zaimplementowanie trzech konfigurowalnych technik redukujących wymagania sprzętowe: wymiennych wariantów mechanizmu uwagi, kwantyzacji, oraz kafelkowania przestrzennego i czasowego. Opracowano również metodykę pomiarową obejmującą czas inferencji, szczytowe zużycie pamięci i jakość rekonstrukcji. Umożliwiło to porównanie uzyskanych konfiguracji między sobą oraz z konfiguracją referencyjną.

W pracy skupiono się na inferencji modelu, bez wykonywania dodatkowego treningu ani dostrajania parametrów, z wykorzystaniem publicznie udostępnionych wag. Głównym wkładem pracy jest adaptacja istniejącego modelu do środowiska o ograniczonych zasobach oraz zbadanie kompromisów między jakością rekonstrukcji, czasem inferencji a zużyciem pamięci.

== Struktura pracy
<struktura-pracy>

Praca składa się z dziewięciu rozdziałów. Rozdział drugi wprowadza podstawy teoretyczne: sformułowanie zadania superrozdzielczości wideo, zasadę działania modeli dyfuzyjnych, architektury transformera wizyjnego i dyfuzyjnego, optymalizacje mechanizmu uwagi, kwantyzację całkowitoliczbową oraz metryki oceny jakości. W trzecim rozdziale omówiono istniejące metody VSR, ze szczególnym uwzględnieniem modelu _FlashVSR_. Rozdział czwarty przedstawia kryteria doboru oraz uzasadnienie wyboru trzech osi optymalizacji: mechanizmu uwagi, kwantyzacji i ograniczenia rozmiaru przetwarzanego fragmentu.

Kolejne dwa rozdziały dotyczą części praktycznej. Rozdział piąty opisuje środowisko sprzętowe i programistyczne oraz projekt systemu, a szósty implementację poszczególnych mechanizmów i aplikacji pokazowej.

Rozdział siódmy przedstawia metodykę badań: pytania badawcze, zbiory testowe, metryki, procedurę pomiarową i plan eksperymentów. W rozdziale ósmym zebrano i omówiono uzyskane wyniki, a dziewiąty zawiera podsumowanie, wnioski badawcze oraz ograniczenia i kierunki dalszych prac.
