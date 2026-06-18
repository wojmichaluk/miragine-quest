# Miragine Quest - etapy realizacji projektu

Najistotniejsze elementy związane z rozwojem projektu, z podziałem na tygodnie.

### 02 III - 08 III
- znalezienie inspiracji na grę (Miragine War)

### 09 III - 15 III
- pomysł na dodanie elementu fabularnego i odstępstwo od oryginału
- zrealizowanie tutoriali do silnika Godot (pierwsza gra 2D i 3D)

### 16 III - 22 III
- sformalizowanie powyższego pomysłu
- wstępne, szczegółowe opisanie elementów gry w pliku [README.md](./README.md)

### 23 III - 29 III
- stworzenie zalążka projektu w Godocie (mapa, przesuwanie widoku za pomocą klawiatury)

### 30 III - 05 IV
- rozbudowa mapy, dodanie kafelków "łączących" na środku mapy
- dodanie panelu jednostek na dole interfejsu
- przygotowanie prostych grafik dla jednostek (niebieskie i czerwone kwadraty)

### 06 IV - 12 IV
- utworzenie dla jednostek punktów życia, mechaniki ataku (z prostą animacją) oraz podążania za wrogiem
- stworzenie minimapy, która podświetla aktualnie podglądany obszar i umożliwia podgląd dowolnego obszaru (odwzorowanie w dwie strony)

### 13 IV - 19 IV
- dodanie różnych typów jednostek (o różniących się parametrach)
- stworzenie systemu "walutowego" celem balansu - złoto, za które kupuje się jednostki oraz limit wag jednostek kupionych w jednej rundzie
- dodanie baz dla obu stron jako celu gry - ich zniszczenie oznacza koniec gry

### 20 IV - 26 IV
- dodanie efektu wypuszczanej "kulki" przy ataku jednostek magicznych
- zastąpienie grafik dla mapy i jednostek przez znalezione / wygenerowane grafiki LPC (odpowiednia informacja o źródle i autorach została dodana)
- balans szybkości jednostek

### 27 IV - 03 V
- przywrócenie w odświeżonej wizualnie wersji pasków życia dla baz gracza i przeciwnika
- poprawa grafik (spritesheetów LPC) - problemy z przezroczystością tła oraz przesunięciem klatek chodzenia / ataku w niektórych przypadkach
- początkowe próby przygotowania klatek animacji dla chodzenia, ataku i śmierci

### 04 V - 10 V
- poprawienie klatek animacji dla chodzenia i ataku (ponowne ich przesunięcie w spritesheetach LPC)
- aktualizacja wybranych klatek dla postaci, aby ruch wyglądał naturalnie

### 11 V - 17 V
- finalny balans szybkości jednostek (zmniejszenie rozbieżności)
- automatyczne wysyłanie jednostek gracza po zaznaczeniu jednostki
- zablokowanie możliwości wysyłania jednostek przeciwnika przez gracza

### 18 V - 24 V
- dodanie właściwych grafik (zamiast czerwonego / niebieskiego prostokąta) dla "baz"
- dodanie zaznaczenia wybranej jednostki (obwódka, migotanie na zielono przy tworzeniu armii na początku rundy)
- dodanie zachowania i przygotowanie mechaniki baz na wzór regularnych jednostek

### 25 V - 31 V
- dostosowanie statystyk jednostek i baz w celu dążenia do balansu
- dodanie okienka startowego gry (menu główne), wraz z demo bitwy odbywającym się w tle (bez aktywności gracza)
- dodanie muzyki i efektów dźwiękowych do gry (spawnowanie dla jednostek, atak i śmierć dla baz i jednostek); uwzględnienie informacji o źródłach zasobów
- usprawnienie UI (dodanie przycisków do wyciszania i wyjścia z gry do głównego menu)

### 01 VI - 07 VI
- zmiana systemu walut - adaptacyjne przychody i wzrosty wag, ustalanie limitów na podstawie wyników rundy i numeru rundy
- dodanie sceny końca gry
- dostosowanie statystyk jednostek (zwiększona bezwaględna szybkość, skrócenie czasu ataku, inne drobne zmiany)

### 08 VI - 14 VI
- obliczanie skrajnych statystyk jednostek (na potrzeby wizualizacji)
- dodanie panelu informacji o jednostce - po kliknięciu prawym przyciskiem myszy na okienko jednostki, pojawia się (popup) i w przystępny sposób prezentuje statystyki jednostki

### 15 VI - 21 VI
- zmiana wyświetlania walut - ikonki zamiast tekstu
- dodanie inteligentego wybierania jednostek przez komputer zamiast losowości
- dodanie grafik dla wypuszczanych pocisków (_projectile_) przez jednostki z atakiem magicznym / zasięgowym
- dodanie drugiej bazy przeciwnika w połowie jego części mapy; w związku z tym dostosowanie statystyk jednostek gracza (punkty zdrowia i obrażenia ~5-7% niższe)
- dodanie panelu informacji dla baz, analogicznie jak dla jednostek
- dodanie etapu przygotowania przed startem bitwy w ekranie głównym gry
- dodanie zakładek z instrukcjami (_tutorial_) i źródłami (_credits_)
- uzupełnienie dokumentacji i udostępnienie projektu na platformie https://itch.io/.
