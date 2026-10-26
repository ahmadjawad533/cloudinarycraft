FROM nginx:1.27-alpine-slim

# Remove default nginx configs
RUN rm -rf /etc/nginx/conf.d/* /etc/nginx/nginx.conf

# Copy custom reverse proxy configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create cache and run dirs with proper permissions
RUN mkdir -p /var/cache/nginx /var/run /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/cache/nginx /var/run/nginx.pid /var/log/nginx

EXPOSE 80

HEALTHCHECK --interval=20s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://127.0.0.1/gateway-health || exit 1

CMD ["nginx", "-g", "daemon off;"]
