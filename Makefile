all: install

install:
	cp instantnotes.sh /usr/bin/instantnotes

uninstall:
	rm /usr/bin/instantnotes

clean:
	rm -r /home/${USER}/instantos/notes
