# FROM perl:latest
#      perl:5.34-bullseye <== does not have incrond (deprecated)
#      perl:5.34-buster   <== would have incrond, but is EOL
#      perl:5.40-bookworm <== has incron in main repo, modern Debian LTS

FROM perl:5.40-bookworm

MAINTAINER jalbersdorfer <jalbersdorfer@gmail.com>

RUN apt-get update \
 && apt-get install -y poppler-utils ocrmypdf tesseract-ocr-deu incron

COPY cpanfile .
RUN cpanm --installdeps --notest .

RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml

RUN mkdir -p /app/data /app/public /app/import
RUN ln -s /app/data /app/public/data
# RUN echo 'root' > /etc/incron.allow
# RUN echo '/app/import/ IN_CLOSE_WRITE /app/importFile.sh $@/$#' >> /etc/incron.d/app-import
RUN apt-get install -y img2pdf

ENV SPHINX_HOST=127.0.0.1
ENV SPHINX_PORT=9306

ENV OVERVIEW_LIMIT=18
ENV OVERVIEW_ORDER=DESC

ENV ELDOAR_HOME=/app

WORKDIR /app
COPY . .

EXPOSE 3000

# ENTRYPOINT ["perl", "/app/dancerApp.pl"]
ENTRYPOINT [ "/app/start.sh" ]

