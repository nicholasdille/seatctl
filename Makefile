SCRIPTS     := $(shell find . -type f -name \*.sh | sort)

.PHONY:
check:
	@shellcheck $(SCRIPTS)
