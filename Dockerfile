# Optimized single-stage build for small image size
# Build with: DOCKER_BUILDKIT=1 docker build -t postarchiv:latest .
#
# This Dockerfile prioritizes:
# 1. Small final image size (~1.4GB or less)
# 2. Fast rebuilds with aggressive cleanup
# 3. Only runtime dependencies included

FROM perl:5.40-bookworm

MAINTAINER jalbersdorfer <jalbersdorfer@gmail.com>

WORKDIR /app

# Install all dependencies in single layer with aggressive cleanup
# Note: DBD::mysql 4.050 (not 5.x) compiles against libmariadb-dev
#       (5.x uses MySQL 8.0-specific constants not present in MariaDB)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libmariadb-dev \
    libmariadb3 \
    libdbi-perl \
    libtemplate-perl \
    poppler-utils \
    ocrmypdf \
    unpaper \
    tesseract-ocr-deu \
    incron \
    img2pdf \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy cpanfile early for better caching
COPY cpanfile .

# Install CPAN modules with persistent cache mount
# Cache mount keeps downloaded/compiled modules across builds (~3x faster rebuilds)
RUN --mount=type=cache,target=/root/.cpanm \
    cpanm --notest --installdeps . && \
    # Cleanup of unnecessary build artifacts (but keep .so compiled modules!)
    find /usr/local/lib/perl5 -type d \( -name '.git' -o -name 't' -o -name 'examples' \) -exec rm -rf {} + 2>/dev/null || true && \
    find /usr/local/lib/perl5 -name '*.bs' -delete && \
    rm -rf /root/.perl5 /usr/local/share/man /usr/local/share/doc /tmp/* /var/tmp/*

# ImageMagick policy fix (allow PDF processing)
RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml

# Create application directories
RUN mkdir -p /app/data /app/public /app/import && \
    ln -s /app/data /app/public/data

# Environment variables
ENV SPHINX_HOST=127.0.0.1
ENV SPHINX_PORT=9306
ENV OVERVIEW_LIMIT=18
ENV OVERVIEW_ORDER=DESC
ENV ELDOAR_HOME=/app

# Copy application code (at the end to leverage caching)
COPY . .

EXPOSE 3000

ENTRYPOINT ["/app/start.sh"]
