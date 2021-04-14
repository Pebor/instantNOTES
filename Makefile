all: install

install:
	cp instantnotes.sh /usr/bin/instantnotes
	install -m 644 instantnotes.desktop /usr/share/applications/

uninstall:
	rm /usr/bin/instantnotes
	rm /usr/share/applications/instantnotes.desktop

clean:
	rm -r /home/${USER}/instantos/notes
