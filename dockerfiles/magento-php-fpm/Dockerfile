# Base image
FROM php:8.3-fpm

# Maintainer details
LABEL Maintainer="Eric Ngigi <cloud@ericngigi.com>"
LABEL Description="PHP-FPM using version 8.3 for Magento 2.4.7"
LABEL Version="1.0"

# Install required system dependencies for PHP extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libxslt-dev \
    libonig-dev \
    libgd-dev \
    libssl-dev \
    libicu-dev \
    libmagickwand-dev \
    git \
    unzip \
    curl \
    gnupg2 \
    bash \
    mycli \
    vim \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install and enable third-party PHP extensions via PECL
RUN pecl install imagick apcu && \
    docker-php-ext-enable imagick apcu

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install \
    bcmath \
    calendar \
    exif \
    gd \
    gettext \
    intl \
    mbstring \
    mysqli \
    opcache \
    pcntl \
    pdo_mysql \
    soap \
    sockets \
    xsl \
    xml \
    zip

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Add Composer to the PATH
ENV PATH="/usr/local/bin:$PATH"

# Configure PHP-FPM port
RUN sed -i 's/^listen = 9000$/listen = 9050/' /usr/local/etc/php-fpm.d/zz-docker.conf

# Create application user
RUN groupadd -g 1000 magento && \
    useradd -u 1000 -ms /bin/bash -g magento magento && \
     echo "magento ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/magento && \
    chmod 0440 /etc/sudoers.d/magento && \
    mkdir -p /home/magento/.config && \
    mkdir -p /home/magento/magento2 && \
    chown -R magento:magento /home/magento

# Set Composer home for magento user
ENV COMPOSER_HOME=/home/magento/.composer
RUN mkdir -p $COMPOSER_HOME && chown -R magento:magento $COMPOSER_HOME

# Switch to non-root user
USER magento

# Set working directory
WORKDIR /home/magento

# Expose port 9050 and start php-fpm
EXPOSE 9050
CMD ["php-fpm"]
