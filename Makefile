all: eg

clean:
	$(RM) eg

test: all
	./eg | grep "Howdy" >/dev/null && echo "PASSED" || echo "FAILED"

.PHONE: all clean test
