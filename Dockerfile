FROM klakegg/hugo:0.101.0-asciidoctor

RUN \
    apk add --no-cache \
        graphviz

RUN \
    gem install --no-document \
        asciidoctor-kroki
