#import "../utils.typ": flex-caption, silentheading, todo

= Implementacja
<implementacja>
Prace implementacyjne objęły przekształcenie referencyjnych skryptów inferencyjnych w pakiet o sterowalnej konfiguracji oraz dodanie mechanizmów redukujących zapotrzebowanie na pamięć i czas: wymiennych wariantów mechanizmu uwagi obejmujących jądra bibliotek _SageAttention_ i _SpargeAttention_, kwantyzacji całkowitoliczbowej transformera dyfuzyjnego oraz kafelkowania przestrzennego i czasowego. Elementy zaczerpnięte z implementacji referencyjnej zaznaczono w tekście.

== Wymienne warianty mechanizmu uwagi
<wymienne-warianty-mechanizmu-uwagi>
W implementacji referencyjnej wybór jądra obliczeniowego nie podlegał konfiguracji. Realizował go łańcuch warunków sterowany obecnością maski blokowej oraz dostępnością pakietów w środowisku, w którym _SageAttention_ zajmowało odległą pozycję, osiąganą wyłącznie przy braku zainstalowanego _FlashAttention_. Pakiet ten nie był przy tym wymieniony wśród zadeklarowanych zależności, więc ścieżka ta pozostawała w praktyce nieosiągalna.

Łańcuch ten zastąpiono jawnym wyborem sterowanym dwoma niezależnymi parametrami, przekazywanymi przy budowie modelu i propagowanymi do wszystkich bloków transformera. Podział ten wynika z trybu pracy mechanizmu uwagi. Może on działać z maską blokową, łączącą najistotniejsze pary bloków z lokalnym oknem przestrzennym, albo w trybie standardowym, bez maskowania. Ścieżkę z maską obsługuje parametr `mask_attn_mode`, wybierający między jądrem `block_sparse_attn` a jądrem `block_sparse_sage2_attn_cuda` z biblioteki _SpargeAttention_. Ścieżkę bez maski blokowej obsługuje parametr `attn_mode`, wybierający między funkcją `sageattn` a wywołaniem `scaled_dot_product_attention` biblioteki PyTorch.

Wybrane jądro wymaga obecności odpowiedniej biblioteki w środowisku. Jeżeli biblioteka nie jest dostępna, potok zgłasza ostrzeżenie i wykonuje uwagę gęstą, co zapobiega przerwaniu przetwarzania, lecz zmienia badaną konfigurację. Zgodność konfiguracji ze stanem środowiska weryfikowana jest zatem podczas budowy potoku, a wszystkie pomiary wykonano po potwierdzeniu, że żadna ze ścieżek zastępczych nie została użyta."

== Integracja kwantyzacji
<integracja-kwantyzacji>
Kwantyzację umieszczono w funkcji inicjalizującej potok, po wczytaniu wag i przeniesieniu modelu na kartę graficzną. Realizuje ją pojedyncze wywołanie funkcji `quantize_` biblioteki torchao, której przekazuje się transformer dyfuzyjny oraz obiekt konfiguracji odpowiadający wybranemu trybowi: `Int8WeightOnlyConfig` dla kwantyzacji wag albo `Int8DynamicActivationInt8WeightConfig` dla kwantyzacji wag i aktywacji.

Biblioteka torchao zastępuje tensory wag warstw liniowych własnymi podtypami, przechowującymi wartości skwantyzowane wraz z parametrami mapowania. Podmiana odbywa się w miejscu, bez modyfikacji definicji modelu, dzięki czemu pozostałe komponenty potoku nie wymagały zmian. Kwantyzacji poddano wyłącznie transformer dyfuzyjny. Dekoder warunkowy, moduł projekcji wejściowej oraz autoenkoder pozostają w precyzji `bfloat16`.

Ponieważ kwantyzacja modyfikuje wagi nieodwracalnie, zmiana jej trybu wymaga ponownej budowy całego potoku. Ta sama uwaga dotyczy zmiany wariantu uwagi.

== Kafelkowanie przestrzenne
<kafelkowanie-przestrzenne>
Kafelkowanie jest wykonalne dzięki własności odziedziczonej po implementacji referencyjnej: bufory pamięci podręcznej kluczy i wartości inicjalizowane są wartością pustą na początku każdego wywołania potoku, a stan strumieniowy narasta wyłącznie wzdłuż osi czasu w obrębie jednego wywołania. Każde wywołanie stanowi więc niezależny przebieg. Fragmenty klatki można zatem przetwarzać bez współdzielenia stanu między nimi.

Podział klatki na kafle realizuje funkcja zwracająca listę współrzędnych obszarów wejściowych, wyznaczanych z zadanego rozmiaru kafla i szerokości zakładki. Gdy obszar wykracza poza wymiary klatki, jego brzeg jest przycinany do krawędzi, a brzeg przeciwny cofany tak, aby zachować zadany rozmiar. Zapobiega to przetwarzaniu kafli mniejszych od zadanego rozmiaru, kosztem zwiększonej zakładki przy krawędziach obrazu. Jeżeli natomiast zadany rozmiar przekracza wymiar klatki, cofnięcie nie jest możliwe i kafel zostaje zredukowany do rozmiaru obrazu.

Wyniki poszczególnych kafli łączone są przez akumulację na dwóch płótnach: na pierwszym sumowane są kafle przemnożone przez maskę mieszania, na drugim same wagi maski. Iloraz obu płócien daje średnią ważoną w obszarach nakładania. Maska nadaje pasom o szerokości zakładki przy każdej krawędzi wagi narastające liniowo ku wnętrzu kafla. Rozwiązanie to nie wymaga rozróżniania kafli brzegowych i wewnętrznych ani znajomości położenia sąsiadów, a przy tym poprawnie obsługuje zwiększoną zakładkę przy krawędziach obrazu.

== Kafelkowanie czasowe
<kafelkowanie-czasowe>
Implementacja referencyjna obsługiwała długie nagrania odrębną klasą potoku i odrębnym skryptem. Rozwiązanie to zastąpiono kafelkowaniem czasowym sterowanym konfiguracją, dzięki czemu ten sam potok obsługuje nagrania dowolnej długości.

Sekwencja wejściowa dzielona jest na segmenty o zadanej długości, wyznaczane analogicznie do kafli przestrzennych. Segmenty przetwarzane są kolejno, a wynik zapisywany przyrostowo, cco pozwala utrzymywać w pamięci operacyjnej wyłącznie bieżący segment; przy długich nagraniach materiał po czterokrotnym powiększeniu przekraczałby jej pojemność. Ponieważ każdy segment stanowi niezależny przebieg strumieniowy i nie dziedziczy kontekstu poprzednika, klatki z obszaru zakładki łączone są przez mieszanie liniowe. Końcówka segmentu poprzedniego i początek segmentu bieżącego sumowane są z wagami zmieniającymi się liniowo wzdłuż osi czasu.

Długość segmentu nie jest dowolna. Czterokrotna przyczynowa kompresja czasowa autoenkodera wymusza wartości spełniające określoną zależność arytmetyczną, wyznaczane przez funkcje pomocnicze pakietu. Zbyt krótki segment jest przed przetworzeniem dopełniany przez powielenie ostatniej klatki, a nadmiarowe klatki są odrzucane po zakończeniu, dzięki czemu dopełnienie pozostaje niewidoczne dla warstw nadrzędnych.

