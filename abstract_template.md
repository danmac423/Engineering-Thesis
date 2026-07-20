Kilka rzeczy o formie, plus wzorce zdań do każdego punktu — bez sklejania ich w gotowy tekst.

## Konwencja językowa

W polskich streszczeniach technicznych obowiązuje forma bezosobowa: *przedstawiono, zaimplementowano, przeprowadzono, wykazano, porównano*. Nie „ja zaimplementowałem", nie „w pracy autor implementuje". Czas przeszły do tego, co zrobiłeś; czas teraźniejszy do faktów ogólnych („modele dyfuzyjne wymagają…").

Unikaj zwrotów typu „celem niniejszej pracy jest przedstawienie…" — to zdanie o pracy, a nie o problemie. Lepiej zacząć od samego problemu i dojść do celu w drugim zdaniu.

## Wzorce na poszczególne punkty

**1–2. Problem i cel** — najczęstszy schemat to „stwierdzenie o stanie dziedziny → ale → luka":

> *Modele dyfuzyjne osiągają [X], jednak ich [Y] uniemożliwia [Z]. W pracy podjęto problem…*

Kluczowe, żeby „jednak" pojawiło się w pierwszych dwóch zdaniach — to ono uzasadnia istnienie pracy.

**3. Model bazowy** — jedno zdanie, z wtrąceniem uzasadniającym:

> *Jako model bazowy wybrano FlashVSR, przedstawiciela [kategoria], ze względu na [jedna cecha].*

**4. Co zrobiono** — wyliczenie w jednym zdaniu, nie osobne zdanie na technikę:

> *Zaimplementowano [A], [B] oraz [C].*

Trzy elementy w jednym zdaniu czytają się dobrze, pięć już nie. Jeśli masz więcej, zgrupuj („warianty mechanizmu uwagi" zamiast wymieniania trzech backendów).

**5. Metodyka** — zwięźle, z konkretami zamiast ogólników:

> *Warianty przebadano na zbiorach [nazwy], mierząc [metryka czasowa], [metryka pamięciowa] oraz jakość rekonstrukcji.*

Nie pisz „przeprowadzono szereg eksperymentów" — to zdanie bez treści.

**6. Wyniki** — to jest miejsce na liczby i najważniejsza część:

> *Wykazano, że [konfiguracja] pozwala na [rezultat], osiągając [liczba]. Stwierdzono jednocześnie, że [obserwacja przeciwna do intuicji].*

Ten drugi człon — o kwantyzacji dynamicznej, która pomaga na pamięci, a szkodzi na czasie — daj koniecznie. Streszczenie z niebanalnym wynikiem czyta się zupełnie inaczej niż takie, które melduje same sukcesy.

**7. Wniosek** — jedno zdanie, bez rozmachu:

> *Uzyskane wyniki wskazują, że [wniosek praktyczny].*

Nie kończ zdaniem o „perspektywach dalszych badań" — to należy do podsumowania, nie do streszczenia.

## Typowe pułapki

Liczby podawaj z jednostką i punktem odniesienia — „0,23 s/klatkę" samo w sobie nic nie mówi, „0,23 s/klatkę przy rozdzielczości wejściowej [X]" już tak. Podobnie ze zużyciem pamięci: zawsze w zestawieniu z limitem karty.

Nie używaj skrótów, których nie rozwiniesz w tym samym zdaniu — VSR, DiT, VRAM w streszczeniu albo rozwiń, albo zastąp opisowo. Wyjątkiem są nazwy własne bibliotek i modeli.

I sprawdź proporcje na końcu: jeśli punkty 1–4 zajmują 80% tekstu, streszczenie jest źle wyważone. Wyniki powinny dostać porównywalną objętość co cała reszta razem.