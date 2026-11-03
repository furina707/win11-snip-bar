CC ?= gcc
CFLAGS ?= -O2 -Wall
PKG_CONFIG ?= pkg-config

GTK_CFLAGS := $(shell $(PKG_CONFIG) --cflags gtk4 gtk4-layer-shell-0)
GTK_LIBS := $(shell $(PKG_CONFIG) --libs gtk4 gtk4-layer-shell-0)

PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
LIBDIR ?= $(PREFIX)/lib/win11-snip-bar

TARGET = win11-snip-bar
SRC = src/main.c

.PHONY: all clean install uninstall

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $< $(GTK_CFLAGS) $(GTK_LIBS)

install: all
	install -d $(DESTDIR)$(BINDIR)
	install -d $(DESTDIR)$(LIBDIR)
	install -m 755 $(TARGET) $(DESTDIR)$(BINDIR)/$(TARGET)
	install -m 755 src/win11-snip-helper.sh $(DESTDIR)$(LIBDIR)/win11-snip-helper
	install -m 755 src/niri-get-window-boxes.py $(DESTDIR)$(LIBDIR)/niri-get-window-boxes.py

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/$(TARGET)
	rm -rf $(DESTDIR)$(LIBDIR)

clean:
	rm -f $(TARGET)
