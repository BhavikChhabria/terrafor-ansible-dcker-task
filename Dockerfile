# Use a lightweight web server image
FROM nginx:alpine

# Copy the HTML file to the default nginx directory
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80
