# Stage 1: Build the Flutter web app
FROM debian:stable-slim AS build

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
ARG FLUTTER_VERSION=3.32.0
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Pre-cache Flutter web artifacts
RUN flutter precache --web

# Copy source and build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

# Stage 2: Serve with nginx
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

# Support Flutter web deep-linking (HTML5 history routing)
RUN printf 'server {\n\
    listen 80;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
