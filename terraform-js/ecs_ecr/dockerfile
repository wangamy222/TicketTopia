# Dockerfile
FROM nginx:latest

# Nginx 설정 파일 복사
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Nginx 실행
CMD ["nginx", "-g", "daemon off;"]