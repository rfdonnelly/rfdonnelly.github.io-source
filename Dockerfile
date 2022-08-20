FROM klakegg/hugo:0.101.0-asciidoctor

RUN \
    gem install --no-document \
        asciidoctor-diagram
