MYOS := $(shell uname -s)

OOCFLAGS += -v

ifeq ($(MYOS), MINGW32_NT-6.1)
OOCFLAGS += -I/g/Dev/sdl_mixer/include -L/g/Dev/sdl_mixer/lib/x86 -I/usr/local/include -L/usr/local/lib -I/usr/local/opt/freetype/include -I/usr/local/opt/freetype/include/freetype2 -L/usr/local/opt/freetype/lib -lopengl32 -lglu32 +-mwindows
else ifeq ($(MYOS), Darwin)
OOCFLAGS += -I/usr/local/opt/freetype/include/freetype2 -I/usr/local/opt/freetype/include/ -L/usr/local/opt/freetype/lib/
endif

# usually my other cores are busy and having too many threads is counter-productive
OOCFLAGS += -j4 -g --nolines

all: deck-editor

deck-editor:
	rock $(OOCFLAGS) deck-editor

clean:
	rock -x

