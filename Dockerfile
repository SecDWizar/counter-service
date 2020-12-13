FROM python:3.9.1 AS builder
WORKDIR /build
COPY requirements.txt app.py /build/
RUN pip install -r requirements.txt
RUN pyinstaller -w -F --hidden-import='pkg_resources.py2_warn' app.py # hidden import is not needed, TODO

FROM debian:buster-slim
WORKDIR app
COPY --from=builder /build/dist/app .
EXPOSE 8000
CMD ["./app"]  

# sudo docker build -t postcounter:002 .
# sudo docker stack deploy -c stack.yml postcounter
