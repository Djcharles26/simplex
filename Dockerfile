FROM cirrusci/flutter:2.5.0 as builder

WORKDIR '/home/simplex'

COPY . .
RUN flutter clean
RUN flutter pub get
RUN flutter build web


FROM nginx
EXPOSE 3000
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /home/simplex/build/web /usr/share/nginx/html