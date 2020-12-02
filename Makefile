.PHONY: post
post:
	docker run --rm -it \
	    -v $(PWD):/src \
	    -u $(shell id -u):$(shell id -g) \
	    klakegg/hugo:asciidoctor \
	    new posts/$(NAME).adoc

.PHONY: preview
preview:
	docker run --rm -it \
    	    -v $(PWD):/src \
    	    -p 1313:1313 \
    	    klakegg/hugo:asciidoctor \
    	    serve --bind 0.0.0.0 --buildDrafts

.PHONY: publish
publish:
	docker run --rm -it \
	    -v $(PWD):/src \
	    -v $(PWD)/public:/target \
	    -u $(shell id -u):$(shell id -g) \
	    klakegg/hugo:asciidoctor
	cd public \
	    && git add . \
	    && git commit -m "Publish $(date)" \
	    && git push
