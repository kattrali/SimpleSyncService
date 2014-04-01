DOCTOOL=appledoc --project-name SimpleSyncService --project-company Delisa Mason --company-id me.delisa --index-desc ../README.md

default: clean spec

clean:
		$(MAKE) -C Example clean

spec:
		$(MAKE) -C Example spec

install:
		$(MAKE) -C Example install

rebuild_docs:
		$(DOCTOOL) -h --output Documentation/  --keep-intermediate-files Classes/ || true
		rm -r Documentation/docset/

install_docs:
		$(DOCTOOL) Classes/