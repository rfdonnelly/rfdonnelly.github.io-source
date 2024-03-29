FROM klakegg/hugo:0.101.0-asciidoctor

RUN \
    apk add --no-cache \
        graphviz \
        python3 \
        py3-pip

RUN \
    gem install --no-document \
        asciidoctor-html5s \
        asciidoctor-kroki \
        pygments.rb

RUN \
    pip3 install vue-lexer
