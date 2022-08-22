.PHONY: post
post:
	docker build -t hugo .
	docker run --rm -it \
	    -v $(PWD):/src \
	    -u $(shell id -u):$(shell id -g) \
	    hugo \
	    new posts/$(NAME).adoc

.PHONY: preview
preview:
	docker build -t hugo .
	docker run --rm -it \
    	    -v $(PWD):/src \
    	    -p 1313:1313 \
    	    hugo -v\
    	        serve \
		--bind 0.0.0.0 \
		--buildDrafts

.PHONY: publish
publish:
	docker build -t hugo .
	docker run --rm -it \
	    -v $(PWD):/src \
	    -v $(PWD)/public:/target \
	    -u $(shell id -u):$(shell id -g) \
	    hugo -v
	cd public \
	    && git add . \
	    && git commit -m "Publish $(date)" \
	    && git push
