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

### APPENDIX 1

Dodajemy słownik do PG i wyszukujemy dane po słowach podobnych.

1. Rozpakowujemy plik db/pl_ts gdzieś lokalnie

2. Kopiujemy pliki do tsearch'a
sudo cp * /usr/share/postgresql/9.3/tsearch_data

3. Tworzymy konfigurację
CREATE TEXT SEARCH CONFIGURATION public.polish ( COPY = pg_catalog.english );

4. Tworzymy słownik
CREATE TEXT SEARCH DICTIONARY warsztaty_ispell (TEMPLATE = ispell, DictFile = polish, AffFile = polish, StopWords = polish);

5. Następnie tworzymy słownik synonimów
CREATE TEXT SEARCH DICTIONARY warsztaty_syn (TEMPLATE = synonym, SYNONYMS = polish);

6. Tezaurus
CREATE TEXT SEARCH DICTIONARY warsztty_th (TEMPLATE = thesaurus, DictFile = polish, Dictionary = warsztaty_ispell);

7. Na koniec wykonujemy konfigurację
ALTER TEXT SEARCH CONFIGURATION polish ALTER MAPPING FOR hword_asciipart, asciihword, word, hword, hword_part, asciiword WITH warsztty_th, warsztaty_syn, warsztaty_ispell, simple;

8. Proste testy
SELECT plainto_tsquery('public.polish', 'dziewczynki');
SELECT * FROM ts_debug('polish', 'chłopcami');
SELECT to_tsvector('public.polish', 'wódzia')

9. Tworzymy małą tabelkę z danymi przykładowymi
CREATE TABLE warsztacik (example text NOT NULL,example_tsvector TSVECTOR);
INSERT INTO warsztacik (example) VALUES ('Dawno temu pracowaliśmy razem');
INSERT INTO warsztacik (example) VALUES ('Nigdy nie pracuję po godzinach');
INSERT INTO warsztacik (example) VALUES ('Warto pracować aby mieć środki do życia');

10. Aktualizujemy pole tsvector
UPDATE warsztacik SET example_tsvector = to_tsvector('public.polish', example);

11. Wykonujemy zapytania
SELECT example FROM warsztacik WHERE example_tsvector @@ plainto_tsquery('public.polish', 'pracować');
SELECT example FROM warsztacik WHERE example_tsvector @@ plainto_tsquery('public.polish', 'pracował');

12. Przyspieszamy więc całą zabawę
CREATE INDEX warsztacik_tsv_idx ON warsztacik USING GIN( example_tsvector );

## Elastic Search

### Wstęp do ES

1. Pobieramy ES
cd ~/Pobrane
https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.0.0.tar.gz

2. Wypakowujemy do katalogu
tar zxvf elasticsearch-1.0.0.tar.gz

3. Uruchamiamy serwer
cd elasticsearch-1.0.0
bin/elasticsearch

4. Odpalamy przeglądarkę
http://localhost:9200/
http://localhost:9200/_stats?pretty - podstawowe staty

5. Jakieś przykładowe dane w plikach json-owych - tutaj dane z tutoriala do Railsów
cat db/test1.json
cat db/test2.json

5. Mega proste użycie na początek :) Zapodajemy owe dane do FTS-a
curl -XPOST http://localhost:9200/warsztaty/foo -T test1.json
curl -XPOST http://localhost:9200/warsztaty/foo -T test2.json

6. Jako zwrotkę otrzymujemy coś takiego:
{"_index":"warsztaty","_type":"foo","_id":"JXmfkiBGR8ucZuOW3URXQg","_version":1,"created":true}

7. Zerkamy na staty:
http://localhost:9200/_stats?pretty zwracamy uwagę na "count" : 2 co mówi nam, że mamy dwa nowe dokumenty w bazie

8. No to teraz coś wyszukamy (GET-em poprzez browsera)
http://localhost:9200/_search?q=Ruby&pretty

### Rails + ES

1. Dodajemy gem 'tire' do Gemfile
gem 'tire'

2. Aktualizujemy gemy

bundle install

3. Tworzymy model dla naszych testów

rails g model article title:string content:text
rake db:migrate

4. W modelu dodajemy właściwe includacje

include Tire::Model::Search
include Tire::Model::Callbacks

5. Seedujemy danymi

rake db:seed

6. Sprawdzamy statystyki

http://localhost:9200/articles/_stats?pretty

7. Testujemy wyszukiwanie

http://localhost:9200/_search?q=est&pretty

detal poszczególnego artykułu możemy pobrać poprzez

http://localhost:9200/articles/article/8980

8. Mapowanie

http://localhost:9200/articles/_mapping

Możemy zmienić to zachowanie poprzez:

mapping do
    indexes :id,           :index    => :not_analyzed
    indexes :title,        :analyzer => 'snowball', :boost => 100
    indexes :content,      :analyzer => 'snowball'
    indexes :created_at, :type => 'date', :include_in_all => false
end

9. Prosta aplikacja pokazująca jak pracować z wyszukiwaniem

Tworzymy kontroler: 
rails generate scaffold_controller Article

10. Dodajemy do modelu Article

def self.title_matches(args)
    tire.search do
        query {string "title:#{args}"}
    end
end

11. Dodajemy metodę wyszukującą do kontrolera:

def populate
    articles = Article.title_matches(params[:q])
    render :json => articles, :callback => params[:callback]
end

12. Po wszystkim szukamy

http://localhost:3000/articles/populate.json?q=est 

takiego URL-a możemy użyć w AJAX itd.

13. Teraz skomplikujemy nieco bardziej wyszukiwanie

tire.search do
  query do
    boolean do
      must {string "title:#{args}"}
      must {string "created_at:[2014-01-01 TO 2014-10-10]"}
    end
  end
  highlight :title
end

i na koniec dajemy:

http://localhost:3000/articles/populate.json?q=est

14. Sortowanie

sort do
    by :title
end

15. Paginacja

tire.search :page => page, :per_page => 5 do
  query {string "title:#{args}"}
end

16. Filtry (facets) - mega prosty case

filter :terms, :title => ["est"]
facet "only_est" do
terms :title
end

17. Monitoring

W katalogu z instancją odpalamy

bin/plugin -install lukas-vlcek/bigdesk

a potem oczywiście restart i:

http://localhost:9200/_plugin/bigdesk/#nodes

Dodatkowo możemy użyć:

bin/plugin -install karmi/elasticsearch-paramedic

i potem: 

http://localhost:9200/_plugin/paramedic/

Inny bardzo przyjemny plugin:

bin/plugin -install royrusso/elasticsearch-HQ

i po wszystkim:

http://localhost:9200/_plugin/HQ/ gdzie klikamy "Connect" :)

18. Skalowanie ES

Odpalamy nową instancję w oddzielnej powłoce bash, po czym wchodzimy na http://localhost:9200/_plugin/paramedic/ i możemy stwierdzić, że status klustera jest zielony, a był źółty (brak replikacji nodów).

Dostęp do ustawień mamy np. dzięki wywołaniu http://localhost:9200/_cluster/settings a zmieniać je możemy poprzez zapytanie do klustera np:

curl -XPUT http://localhost:9200/articles/_settings -d '{"number_of_replicas":1}'
