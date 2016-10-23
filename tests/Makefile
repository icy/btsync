TESTS = *.txt

.PHONY: default
default:
	@grep -E "^# [a-z].+:" Makefile

# all:
# all: Execute all test scripts
# all: To execute a subset of tests, list them with TESTS=...
# all: for example, `make all TESTS="foo.txt bar.txt"
.PHONY: all
all:
	@mkdir -pv tmp/
	@./test.sh $(TESTS)

# clean:
# clean: Clean all temporary files
.PHONY: clean
clean:
	@rm -rfv tmp/
