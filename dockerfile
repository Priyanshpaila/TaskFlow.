# Use a specific Flutter Docker image that matches the required Dart SDK version
FROM cirrusci/flutter:3.1.0 as builder

# Set the working directory
WORKDIR /app

# Create a non-root user
RUN adduser --disabled-password --gecos "" appuser

# Create and set permissions for the .pub-cache directory
RUN mkdir -p /home/appuser/.pub-cache && chown -R appuser:appuser /home/appuser

# Change ownership of the necessary directories
RUN chown -R appuser:appuser /app /sdks/flutter

# Use the created user
USER appuser

# Set environment variable to change the location of the Pub cache
ENV PUB_CACHE=/home/appuser/.pub-cache

# Copy the project files to the Docker image
COPY . .

# Use Nginx to serve the static files
FROM nginx:alpine

# Copy the built project from the Flutter builder
COPY --from=builder /app/build/web /usr/share/nginx/html

# copy nginx file from host to container
COPY ./nginx.conf /etc/nginx/nginx.conf

# Expose port 80 for the web server
EXPOSE 8080

# Start Nginx and keep it running in the foreground
CMD ["nginx", "-g", "daemon off;"]

# building web:
    # flutter build web

# building apk:
    # flutter build apk --release 

# building rr ispat frontend image command:
    # docker build --no-cache -t 192.168.13.72:5000/taskflow_fe .

# push the image:
    # docker push 192.168.13.72:5000/taskflow_fe

# pull the image:
    # docker pull 192.168.13.72:5000/taskflow_fe

# run the image as a container:
    #  docker run --name taskflow_fe -d -p 8080:8080 192.168.13.72:5000/taskflow_fe

# To build smaller size apk    
    # flutter build apk --release --split-per-abi
    # Use app-arm64-v8a-release.apk (All Android version)
    # Use app-armeabi-v7a-release.apk (Android (Go Edition) version)