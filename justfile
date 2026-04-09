set shell := ["bash", "-cu"]

default: tool

tool:
	@npm run tool

check-ascii:
	@npm run check:ascii

lint-md:
	@npm run lint:md

check-links:
	@npm run check:links
