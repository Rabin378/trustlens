# TrustLens Makefile
#   make          build everything
#   make data     create practice CSV files
#   make run      run the full pipeline (trains models, builds the database)
#   make test     quick check of the website backend
#   make serve    start the WEBSITE at http://127.0.0.1:8080
#   make demo     try the saved models on a few examples
#   make db       (optional) reload the .sql script with the sqlite3 command-line tool
#   make clean    remove build outputs
#
# SQLite is detected automatically. No SQLite? No problem - the program then
# just writes db/trustlens_full.sql instead of a live database.
#   make NO_SQLITE=1    force script-only mode

CXX      ?= g++
CXXFLAGS ?= -std=c++17 -O2 -Wall -Wextra
INCLUDES  = -Iinclude

ifndef NO_SQLITE
  HAS_SQLITE := $(shell echo '\#include <sqlite3.h>' | $(CXX) -E -x c++ - >/dev/null 2>&1 && echo yes)
  ifeq ($(HAS_SQLITE),yes)
    CXXFLAGS += -DUSE_SQLITE
    LDLIBS   += -lsqlite3
  endif
endif

HEADERS := $(wildcard include/*.hpp)

# The web server needs SQLite (to read the database). Without it we skip the server.
ifeq ($(HAS_SQLITE),yes)
  SERVER_TARGET := trustlens_server
endif

all: trustlens generate_data $(SERVER_TARGET)

trustlens: src/main.cpp $(HEADERS)
	$(CXX) $(CXXFLAGS) $(INCLUDES) src/main.cpp -o $@ $(LDLIBS)

generate_data: src/generate_data.cpp $(HEADERS)
	$(CXX) $(CXXFLAGS) $(INCLUDES) src/generate_data.cpp -o $@

trustlens_server: src/server.cpp $(HEADERS)
	$(CXX) $(CXXFLAGS) $(INCLUDES) src/server.cpp -o $@ -pthread $(LDLIBS)

serve: trustlens_server
	./trustlens_server

test: trustlens_server
	./scripts/smoke_test.sh

data: generate_data
	./generate_data

run: trustlens
	./trustlens run

demo: trustlens
	./trustlens demo

db:
	rm -f db/trustlens.db
	sqlite3 db/trustlens.db < db/trustlens_full.sql
	@echo "database rebuilt: db/trustlens.db"

clean:
	rm -f trustlens generate_data trustlens_server

.PHONY: all data run demo serve test db clean
