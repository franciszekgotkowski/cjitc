## Wprowadzenie
W tym folderze można znaleźć kod, który napisałem w trakcie realizacji praktyk. Kolejne foldery zawierają oddzielne projekty, czy też programy.


### ./main
Ten folder zawiera moje pierwsze (zbyt ambitne) podejście do napisania kompilatora. Miałem wtedy zamiar napisać kompilator z możliwością kompilowania do zarówno biblioteki jak i pliku uruchamialnego. Biblioteka miała mieć możliwość zapewniania customowych alokatorów oraz tworzenia od razu pamięci z której możnaby było zdobywać funkcje o zdefiniowanych sygnaturach.

Projekt zacząłem pisać w złej kolejności, zacząłem od napisania interfejsu do przekazywania własnych alokatorów. Napisałem również domyślny alokator - alokator arenowy.

Wtedy jednak stwierdziłem, że tak obszerny projekt będzie za duży na praktyki. Wtedy też stwierdziłem, że postaram się zbudować jedynie program, zamiast biblioteki, co pozwoliło mi na wybór nowego języka.

Kod był pisany w języku C99, kożystałem jedynie z biblioteki do testów 'cmocka'. Skompilowanie kodu nie wymaga żadnych dynamicznych bibliotek. Wymagany jest jedynie cmake, make oraz gcc lub clang. Skompilowanie wymaga wykonania jedynie komend cmake oraz make.
`
mkdir build & cd build && cmake -S ../ && make
`

### ./mathlang
W tym folderze eksperymentowałem z językiem go, zbudowałem bardzo prosty kompilator autorskiego języka wyrażeń matematycznych. Kompilator jest bardzo prosty ponieważ miałem małą wiedzę o architekturze kompilatorów, dodatkowo moim celem nie było zbudowanie dużego, działającego programu, a raczej eksperymentacja z nowymi konceptami.

Program wymaga kompilatora go w wersji 1.24.4 lub wyższej.
Można go uruchomić komendą
`
go run .
`

Niestety język go spełnił moich oczekiwań w stosunku programu typu kompilator. Brak enumeratorów znacznie utrudnia definiowanie struktury języka.

### ./tokeniser_pt1
W tym folderze pisałem prototyp parsera. Pisałem go w języku odin - niszowym języku z manualnym zarządzaniem pamięcią.  Odin pozwala na niskopoziomowe zarządzanie pamięcią, jednocześnie będąc współczesnym językiem pozwalającym na customowe alokatory, testowanie czy program leakuję pamięć, oraz wiele 'wygodnych' dodatków do składni języka c.

Język spodobał mi się i zdecydowałem kożystać z niego do końca projektu. Dodaktowo napisanie prototypu tokenisera pozwoliło mi na napisanie spójniejszego i bardziej eleganckiego kodu w docelowym projekcie.

Kod można uruchomić komendą
`
odin run .
`

### ./lang
Ten folder zawiera kod docelowego projektu. Kod jest pisany z myślą o byciu czytelnym i wysokiej jakości. Ten kod również zawiera testy które można uruchomić komendą:
`
odin test . -define:ODIN_TEST_THREADS=1
`
Program nie zawiera całego kompilatora lecz zawiera:
-	Tokeniser pozwalający na budowanie dowolnych tokenów zdefiniowanych w token_constants.odin
-	Budowę drzewa gramatycznego pozwalającego na budowanie dowolnej gramatki zdefiniowanej w grammar_constants.odin
-	Parser budujący parse tree na podstawie wczęśniej zdefiniowanych tokenów oraz gramatyki

Do ukończenia kompilatora wymagany byłby semantic analizer oraz codegen.

Kod można uruchomić przy pomocy
`
odin run .
`


## Podsumowanie
Mimo, iż kompilator nie został ukończony, napisanie jego połowy pozwoliło mi na:
-	Eksperymentację z wieloma językami programowania oraz wybór najlepszego do wymaganego zadania
-	Naukę o architekturze kompilatorów oraz ich zastosowaniu
-	Doświadczenie w poszukiwaniu przydanych informacji w książkach, filmach oraz na stronach internetowych
-	Dogłębne testowanie pisanego przez mnie programu
-	Doświadczenie pisania dużego programu (łącznie ~6300 lińji kodu)

## Dokumentacja moich czynności:
W pliku czynności.ods są rozpisane czynności które wykonywałem w trakcie realizowania praktyk. Każda z czynności ma swoją godzinę rozpoczęcia, zakończenia oraz umiejętność, którą zdobywałem w trakcie wykonywania praktyk
