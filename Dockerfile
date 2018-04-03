FROM python:alpine
RUN pip3 install requests
RUN pip3 install beautifulsoup4
RUN mkdir /app
COPY scrape_reiv.py /app
RUN mkdir /out
WORKDIR /out
CMD ["python", "/app/scrape_reiv.py", "/out/results.csv"]