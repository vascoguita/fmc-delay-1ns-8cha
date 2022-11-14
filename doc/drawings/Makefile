EPSIMAGES := $(shell ls *eps)

all: images

clean:
	@rm $(EPSIMAGES:.eps=.png)

images: $(EPSIMAGES:.eps=.png)

%.png: %.eps
	@convert $< $@

.PHONY: all clean images
