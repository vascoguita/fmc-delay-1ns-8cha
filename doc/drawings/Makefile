EPSIMAGES := $(shell ls *eps)

all: images

clean:
	@rm $(EPSIMAGES:.eps=.png)

images: $(EPSIMAGES:.eps=.png)

%.png: %.eps
	@inkscape $< -o $@ || inkscape --without-gui $< -A $@

.PHONY: all clean images
