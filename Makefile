# Redis-tools Makefile
# Copyright (C) 2009-2010 Salvatore Sanfilippo <antirez at gmail dot com>
# This file is released under the BSD license, see the COPYING file

uname_S := $(shell sh -c 'uname -s 2>/dev/null || echo not')
OPTIMIZATION?=-O2
ifeq ($(uname_S),SunOS)
  CFLAGS?= -std=c99 -pedantic $(OPTIMIZATION) -Wall -W -D__EXTENSIONS__ -D_XPG6
  CCLINK?= -ldl -lnsl -lsocket -lm -lpthread
else
  CFLAGS?= -std=c99 -pedantic $(OPTIMIZATION) -Wall -W $(ARCH) $(PROF)
  CCLINK?= -lm -pthread
endif
CCOPT= $(CFLAGS) $(CCLINK) $(ARCH) $(PROF)
DEBUG?= -g -rdynamic -ggdb 

LOADOBJ = ae.o adlist.o redis-load.o zmalloc.o rc4rand.o utils.o
STATOBJ = redis-stat.o zmalloc.o utils.o

LOADPRGNAME = redis-load
STATPRGNAME = redis-stat

all: redis-load redis-stat

# Deps (use make dep to generate this)
adlist.o: adlist.c adlist.h zmalloc.h
ae.o: ae.c ae.h zmalloc.h config.h ae_epoll.c ae_kqueue.c ae_select.c
rc4rand.o: rc4rand.c
redis-load.o: redis-load.c fmacros.h ae.h adlist.h zmalloc.h rc4rand.h
redis-stat.o: redis-stat.c fmacros.h zmalloc.h
zmalloc.o: zmalloc.c config.h
utils.o: utils.c utils.h

redis-load.o:
	$(CC) -c $(CFLAGS) -I. -Ideps/hiredis $(DEBUG) $(COMPILE_TIME) $<

redis-load: $(LOADOBJ)
	cd deps/hiredis && $(MAKE) static
	$(CC) -o $(LOADPRGNAME) $(CCOPT) $(DEBUG) $(LOADOBJ) deps/hiredis/libhiredis.a

redis-stat.o:
	$(CC) -c $(CFLAGS) -Ideps/hiredis $(DEBUG) $(COMPILE_TIME) $<

redis-stat: $(STATOBJ)
	cd deps/hiredis && $(MAKE) static
	$(CC) -o $(STATPRGNAME) $(CCOPT) $(DEBUG) $(STATOBJ) deps/hiredis/libhiredis.a

.c.o:
	$(CC) -c $(CFLAGS) $(DEBUG) $(COMPILE_TIME) $<

clean:
	rm -rf $(LOADPRGNAME) $(STATPRGNAME) *.o *.gcda *.gcno *.gcov

dep:
	$(CC) -MM *.c

log:
	git log '--pretty=format:%ad %s' --date=short > Changelog

32bit:
	make ARCH="-arch i386"

gprof:
	make PROF="-pg"

gcov:
	make PROF="-fprofile-arcs -ftest-coverage"

noopt:
	make OPTIMIZATION=""

32bitgprof:
	make PROF="-pg" ARCH="-arch i386"
