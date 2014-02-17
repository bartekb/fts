# FTS dla Rails

## Full Text Search - kilka rozwiązań

### Czym jest FTS?

W największym uproszczeniu, jest to usługa umożliwiająca przeszukiwanie dużych fragmentów tekstów pod kątem znaczeń poszczególnych słów i całych fraz. Posługujemy się najczęściej słowami kluczowymi i metadanymi.


### Kiedy używamy FTS?	

Najczęstszym kryterium jest sytuacja kiedy klient wymaga przeszukiwania dużej ilości danych tekstowych (ale nie tylko) w czasie rzeczywistym.

### Czy tylko wyszukiwanie?

Nie. Dwie przykładowe sytuacje, w których używałem FTS to, poza wyszukiwaniem: 
dostęp do filtrowanych list (np. wg. kategorii), gdzie szybkość miała kluczowe znaczenie a danych było niezwykle dużo
identyfikowanie wielu, różnych elementów bazodanowych po tagach tekstowych 

### Używam Rails 3 lub 4, co dalej?

W przypadku FTS operujemy z poziomu AR. Praktycznie dla każdej możliwej metody dostępne są gemy - jedne nieco lepsze, inne mniej. Generalną zasadą, jest taki dobór gema aby pozwalał nam na jak największą kontrolę nad zapytaniami - prędzej czy później będziemy jej potrzebowali.

### Jakie opcje FTS mamy dla Rails?

Jest wiele, przedstawię kilka:
FTS wbudowany w PostgreSQL
w oparciu o widok i ts_vector
w oparciu o dokumenty i ts_vector
ElasticSearch (Apache Lucene)
inne wkrótce … :)

### Na czym pracujemy?

Raczej standard:
Rails 4.x
Ruby 2.0 (RVM)
PostgreSQL 9.3

### Podstawowa aplikacja

Wszystko co robimy jest na GitHub, więc jak ktoś się zgubi albo będzie chciał mieć na “potem”, tutaj jest link:

Zaczynamy standardowo:

    rails new fts -d postgresql

pamiętamy o odpowiedniej modyfikacji database.yml po czym rake db:setup

### Przechowywanie schematu

Ponieważ będziemy operowali na niestandardowych elementach PLSQL-a, charakterystycznych tylko dla PG, musimy zmienić sposób w jaki Railsy przechowują informacje o schemacie. W tym celu do application.rb dodajemy:

    config.active_record.schema_format = :sql

### Przykładowe modele

Prosty przykład: kategorie i dokumenty.

    rails g scaffold categories title:string

oraz

    rails g scaffold documents title:string body:text category:references

    rake db:migrate

Pozostaje nam poddać wygląd tuningowi :)

### Dane testowe

Używamy jak zwykle db/seeds.rb. Potrzebujemy tekstu więc użyjemy gema “faker” więc dodajemy go do Gemfile i potem posiłkując się plikiem seeds.rb z mojego repo odpalamy:

    rake db:seed

Mamy 10 kategorii po 10 dokumentów.

tylko widok + ts_vector
FTS wbudowany w PostgreSQL

### Widok i odpowiedni gem
widok znajduje się w przykładowej migracji jaka jest w repo - proponuję zwrócić uwagę na to jak tworzone są indeksy. Dodawane są one tak by nie blokować silnika DB i umożliwić zapis do storage.
gem to Textcular - https://github.com/textacular/textacular

### Model wyszukiwania
Tworzymy model wyszukiwania opierający się o polimorfizm zawarty w widoku zaś naszą “tabelą” dla tego modelu jest widok.
Aby przeprowadzić test czy wszystko działa ok, możemy odpalić konsolę i w niej wykonać:

    Search.new('Necessitatibus')

zachęcam do eksperymentów :)

### Kiedy można stosować takie podejście?
zapytania nie są skomplikowane
szukamy najczęściej wystąpienia jakiegoś słowa bez filtrowania
chcemy zachować prostotę i czystość w naszych przeszukiwanych modelach
chcemy to zrobić szybko :)

### brak widoku, kolumna ts_vector
FTS wbudowany w PostgreSQL

Przygotowanie

używamy gema PgSearch - https://github.com/Casecommons/pg_search
do modeli, które chcemy przeszukiwać includujemy PgSearch 
zastanawiamy się jakiego rodzaju wyszukiwanie chcemy zaimplementować, mamy do wyboru dwa rodzaje

### Czego chcemy od PgSearch?

Są dwa tryby wyszukiwania w PgSearch:
multi - zbliżone do poprzedniej metody, używamy jak chcemy prostego wyszukiwania po wielu instancjach modeli (tabel)
scoped - używamy jeśli chcemy uzyskać filtrowanie wyników, implementujemy autouzupełnianie lub potrzebujemy większej kontroli

### Tryb multi w PgSearch
opiera się na oddzielnej tabeli (pg_search_documents), którą tworzymy za pomocą migracji

    rails g pg_search:migration:multisearch

za pomocą procedury multisearchable ustawiamy warunki wyszukiwania

### Co jeśli już mam dane?
Taka sytuacja ma najczęściej miejsce, kiedy dodajemy FTS do już istniejących danych. Tabelę z danymi wyszukiwania budujemy raz za pomocą rake, np.:

    rake pg_search:multisearch:rebuild[Document]

### Podstawy zabawy z wynikami
Podobnie jak w poprzednim przykładzie korzystamy z polimorfizmu:

    res = PgSearch.multisearch("Ipsum")
    res.first.searchable
    PgSearch.multisearch("Ipsum").limit(3)
    PgSearch.multisearch("Ipsum").where( :searchable_type => "Document")

### Tryb scoped w PgSearch

Tryb ten umożliwia nam szukanie w jednym modelu. Dodatkowo możemy ustawić wagę wyszukiwania na więcej niż jednej kolumnie.

Aby zaobserwować jak to działa proponuję dodać nową kolumnę o typie string, która będzie przechowywała drugi tytuł (np. w innym języku lub tutuł z innego źródła).

    rails g migration add_title2_to_documents title2:string

Dodajemy kolumnę oraz odpowiedni zestaw wyzwalaczy dla bazy danych. Taki krok jest konieczny, gdyż nie mamy mechanizmu, który dokonałby aktualizacji kolumn FTS-owych. Poniżej sugeruję zapoznać się z poniższą migracją:

    subl db/migrate/20140217084919_add_tsearch_to_documents.rb

Oczywiście wszystko kończymy:

    rake db:migrate

Po wszystkim, aby posiadać jakieś wartości w nowej kolumnie, w konsoli wykonujemy:

    Document.all.each{ |d| d.update_attribute(:title2, rand(36**8).to_s(8)) }

Wyszukiwanie odbywa się dość prosto: 

    Document.search2("foo")

Tutaj również zachęcam do eksperymentowania :)
