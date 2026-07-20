#import "../utils.typ": flex-caption, silentheading, todo

= Wstęp

== Motywacja i sformulowanie problemu

Technologia superrozdzielczości wideo (ang. _Video Super-Resolution_, VSR) służy do rekonstrukcji sekwencji o wysokiej rozdzielczości na podstawie jej zdegradowanego odpowiednika. Wykorzystuje się ją w wielu praktycznych zastosowaniach, począwszy od rekonstrukcji archiwalnych nagrań i skalowania skompresowanych mediów na platformach streamingowych, aż po poprawę jakości nagrań z monitoringu i badań medycznych.

Podejścia wykorzystujące głębokie uczenie do VSR od dawna oparte są na architekturach splotowych i bazujących na Transformerach, trenowanych z wykorzystaniem funkcji straty opartej na rekonstrukcji pikselowej. Taka funkcja sprzyja zachowawczym wartościom pikseli, czego skutkiem jest powstawanie zbyt wygładzonych obrazów, pozbawionych detali. Wykorzystanie modeli dyfuzyjnych próbuje rozwiązać te problemy. Ponieważ są to metody generatywne, zamiast uśredniać możliwe rozwiązania, odtwarzają one prawdopodobne szczegóły. Przekłada się to na ostrzejsze i bardziej naturalne rezultaty. Poprawa ta ma jednak swój koszt, VSR oparte na dyfuzji jest wymagające pod względem obliczeniowym, pamięciowym oraz czasowym. Iteracyjny proces odszumiania i kwadratowa złożoność uwagi w odniesieniu do tokenów czasoprzestrzennych utrudnia praktyczne wykorzystanie.

Jednokrokowe modele uzyskiwane w wyniku destylacji wiedzy są częściową odpowiedzią na ten problem. Reprezentatywnym przykładem jest FlashVSR @Zhuang2025FlashVSRTR. Twórcy modelu połączyli destylację do modelu jednokrokowego z blokowo-rzadką uwagą, aby zbliżyć się do przetwarzania w czasie rzeczywistym. Destylacja eliminuje koszt wielokrotnego odszumiania, ale nie redukuje narzutu pamięciowego w pojedynczej inferencji, który determinuje, czy model może zostać uruchomiony na danym urządzeniu.

Stwarza to istotną barierę, ponieważ dostępne modele, takie jak FlashVSR, zakładają wykorzystanie akceleratorów klasy serwerowej. Autorzy tego modelu wskazują, że szczytowe zużycie pamięci osiąga 11,13 GB przy 101 klatkach o rozdzielczości wyjściowej $768 times 1408$ @Zhuang2025FlashVSRTR. Oznacza to, że sekwencja wejściowa miała wymiary zaledwie $192 times 352$ przy powiększeniu x4, czyli parametry znacząco odbiegające od rozdzielczości typowych nagrań. Konsumenckie karty graficzne oferują zazwyczaj od 8 do 12 GB pamięci VRAM; sprzęt referencyjny przyjęty w pracy, czyli NVIDIA RTX 3080, zapewnia 10 GB. Zapotrzebowanie na pamięć przekracza dostępny budżet nawet w tak korzystnym scenariusze, a deficyt ten rośnie wraz ze wzrostem rozdzielczości wejściowej. Rodzi to pytanie, czy model tej klasy da się uruchomić w budżecie 10 GB VRAM i jakimi kompromisami w zakresie jakości rekonstrukcji oraz czasu inferencji się to wiąże.

== Cel i zakres pracy

Celem pracy jest umożliwienie inferencji jednokrokowego, dyfuzyjnyego modelu superrozdzielczości wideo na karcie graficznej wyposażonej w 10 GB pamięci VRAM, przy zachowaniu akceptowalnych jakości rekonstrukcji i czasu przetwarzania. Jako model bazowy przyjęto FlashVSR @Zhuang2025FlashVSRTR.

Realizacja tego celu wymagała refaktoryzacji kodu referencyjnej implementacji do postaci modularnego pakietu oraz zaimplementowania trzech konfigurowalnych technik redukujących wymagania sprzętowe: wymiennych wariantów mechanizmu uwagi, kwantyzacji, oraz kafelkowania przestrzennego i czasowego. Opracowano również metodykę pomiarową obejmującą czas inferencji, szczytowe zużycie pamięci i jakość rekonstrukcji. Umożliwiło to porównanie uzyskanych konfiguracji między sobą oraz z konfiguracją referencyjną.

Zakres pracy ogranicza się do fazy inferencji. Nie przeprowadzono treningu ani dostrajania, a we wszystkich eksperymentach wykorzystano publicznie udostępnione wagi. Wkład pracy ma charakter inżynieryjno-eksperymentalny i polega na adaptacji istniejącego modelu do środowiska o ograniczonych zasobach i zbadaniu zależności między jakością rekonstrukcji, czasem inferencji a zużyciem pamięci.


== Struktura pracy

#todo[Opisać strukturę pracy.]
