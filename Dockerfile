 FROM openjdk:17-jdk-slim

 # Đặt working directory
 WORKDIR /app

 # Copy file JAR đã build từ bước trước
 COPY target/spring-petclinic-*.jar app.jar

 # Mở port 8080
 EXPOSE 8080

 # Chạy ứng dụng Spring Boot
 CMD ["java", "-jar", "app.jar"]
