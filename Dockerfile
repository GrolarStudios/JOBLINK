FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa

RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter config --enable-web

WORKDIR /app
COPY . .

RUN flutter pub get

EXPOSE 5000

CMD ["flutter", "run", "-d", "web-server", "--web-port=5000", "--web-hostname=0.0.0.0"]