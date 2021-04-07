all: install

install:
	cp instantnotes.sh /bin/instantnotes

uninstall:
	rm /bin/instantnotes

clean:
	rm -r /home/${USER}/instantos/notes
