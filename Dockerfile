FROM php:8.2-fpm

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    git \
    curl \
    zip \
    unzip \
    nginx \
    && docker-php-ext-install pdo_mysql \
    && rm -rf /var/lib/apt/lists/*

# Установка Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Создание директории для приложения
WORKDIR /var/www/html

# Копирование composer файлов для кэширования
COPY composer.json composer.lock* ./

# Установка зависимостей (без dev зависимостей)
RUN composer install --no-interaction --optimize-autoloader --no-dev

# Копирование остальных файлов
COPY . .

# Настройка Nginx
RUN rm -rf /etc/nginx/sites-enabled/default
COPY docker/nginx/render.conf /etc/nginx/sites-available/default
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Настройка прав
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod 777 /var/www/html/storage

# Создание скрипта запуска
RUN echo '#!/bin/bash\n\
service nginx start\n\
php-fpm' > /start.sh && chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
