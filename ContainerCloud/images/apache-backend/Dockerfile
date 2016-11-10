FROM httpd:2.4.23-alpine

# Override the apache start from the base container
COPY start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
