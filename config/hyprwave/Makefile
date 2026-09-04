CC = gcc
CFLAGS = `pkg-config --cflags gtk4 gtk4-layer-shell-0`
LIBS = `pkg-config --libs gtk4 gtk4-layer-shell-0 gio-2.0 gdk-pixbuf-2.0 libpulse` -lm
TARGET = hyprwave
SRC = main.c layout.c paths.c notification.c art.c volume.c visualizer.c vertical_display.c morph-animation-system.c

# Installation paths
PREFIX ?= $(HOME)/.local
BINDIR = $(PREFIX)/bin
DATADIR = $(PREFIX)/share/hyprwave

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(SRC) -o $(TARGET) $(CFLAGS) $(LIBS)

clean:
	rm -f $(TARGET)

install: $(TARGET)
	@echo "Installing HyprWave to $(PREFIX)..."
	install -Dm755 $(TARGET) $(BINDIR)/$(TARGET)
	cp hyprwave-toggle.sh $(BINDIR)/hyprwave-toggle
	chmod +x $(BINDIR)/hyprwave-toggle
	install -Dm644 style.css $(DATADIR)/style.css
	install -Dm644 style-layout.css $(DATADIR)/style-layout.css
	@mkdir -p $(DATADIR)/icons
	install -m644 icons/play.svg $(DATADIR)/icons/
	install -m644 icons/pause.svg $(DATADIR)/icons/
	install -m644 icons/next.svg $(DATADIR)/icons/
	install -m644 icons/previous.svg $(DATADIR)/icons/
	install -m644 icons/arrow-up.svg $(DATADIR)/icons/
	install -m644 icons/arrow-down.svg $(DATADIR)/icons/
	install -m644 icons/arrow-left.svg $(DATADIR)/icons/
	install -m644 icons/arrow-right.svg $(DATADIR)/icons/
	install -m644 icons/volume-mute.svg $(DATADIR)/icons/
	install -m644 icons/volume-low.svg $(DATADIR)/icons/
	install -m644 icons/volume-medium.svg $(DATADIR)/icons/
	install -m644 icons/volume-high.svg $(DATADIR)/icons/
	@mkdir -p $(DATADIR)/themes
	install -m644 themes/*.css $(DATADIR)/themes/
	mkdir -p $(HOME)/.local/share/fonts/hyprwave
	cp fonts/VT323-Regular.ttf $(HOME)/.local/share/fonts/hyprwave/
	fc-cache -f $(HOME)/.local/share/fonts/hyprwave
	@echo "Installation complete!"
	@echo "Files installed to: $(DATADIR)"
	@echo "Binary installed to: $(BINDIR)/$(TARGET)"
	@echo ""
	@echo "Run 'hyprwave' to start"

uninstall:
	@echo "Uninstalling HyprWave..."
	rm -f $(BINDIR)/$(TARGET)
	rm -f $(BINDIR)/hyprwave-toggle
	rm -rf $(DATADIR)
	@echo "Uninstall complete!"

run: $(TARGET)
	./$(TARGET)

.PHONY: all clean install uninstall run
