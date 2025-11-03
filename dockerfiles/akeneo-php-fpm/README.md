# 🐘 PHP 8.3 FPM for Magento 2.4.7

A lightweight, production-ready **PHP-FPM 8.3 Docker image** optimized for running **Magento 2.4.7**.  
It includes all required PHP extensions, Composer, and performance optimizations for reliable Magento deployments.

---

## 📦 Image Overview

**Base Image:** `php:8.3-fpm`  
**Maintainer:** Eric Ngigi (<cloud@ericngigi.com>)  
**Version:** `1.0`  
**Description:** PHP-FPM using version 8.3 for Magento 2.4.7  

---

## 🧰 Installed Components

This image comes with all major system and PHP dependencies needed for Magento 2.4.7.

### 🔧 System Packages
- `build-essential`, `git`, `curl`, `vim`, `zip`, `unzip`, `bash`, `less`, `supervisor`, `gnupg2`, `mycli`
- Image optimization tools: `jpegoptim`, `optipng`, `pngquant`, `gifsicle`
- Libraries: `libpng-dev`, `libjpeg62-turbo-dev`, `libfreetype6-dev`, `libonig-dev`, `libzip-dev`, `libgd-dev`, `libxml2-dev`, `libxslt-dev`, `libssl-dev`, `libmagickwand-dev`

### 🧩 PHP Extensions
| Extension | Purpose |
|------------|----------|
| `bcmath` | Precision math used by Magento pricing |
| `calendar` | Date functions |
| `exif` | Image metadata |
| `gd` | Image processing (JPEG/Freetype support) |
| `gettext` | Internationalization |
| `intl` | Locale/translation |
| `mbstring` | Multibyte string handling |
| `mysqli`, `pdo_mysql` | MySQL database drivers |
| `opcache` | PHP performance cache |
| `pcntl` | Process control |
| `soap` | Magento SOAP APIs |
| `sockets` | Communication support |
| `xsl`, `xml` | XML and XSLT |
| `zip` | Archive management |
| `imagick` *(via PECL)* | Advanced image processing |
| `apcu` *(via PECL)* | Opcode and object caching |

---

## 🎼 Composer

Composer is installed globally:

```bash
composer --version
````

Accessible directly via `PATH`.

---

## 👤 User Configuration

The image runs under a non-root user:

```bash
user: magento (UID 1000)
group: magento (GID 1000)
```

Working directory: `/var/www/html`

---

## ⚙️ Exposed Ports

| Port     | Description          |
| -------- | -------------------- |
| **9100** | PHP-FPM service port |

---

## 🚀 Usage

### Pull from GitHub Container Registry

```bash
docker pull ghcr.io/erikngigi/magento-php-fpm:8.3
```

### Run the container

```bash
docker run -d \
  --name magento-php-fpm \
  -p 9100:9100 \
  -v $(pwd):/var/www/html \
  ghcr.io/erikngigi/magento-php-fpm:8.3
```

### Example Docker Compose

```yaml
version: "3.8"
services:
  php-fpm:
    image: ghcr.io/erikngigi/magento-php-fpm:8.3
    container_name: magento-php-fpm
    ports:
      - "9100:9100"
    volumes:
      - ./src:/var/www/html
```

---

## 🧱 Building Locally

To build your own image from this Dockerfile:

```bash
docker build -t magento-php-fpm:8.3 .
```

---

## 🧩 Integration with Magento 2.4.7

This image is designed to be used alongside:

* **Nginx or Apache** container (e.g., `magento-nginx`)
* **MySQL/MariaDB** for data
* **Redis** for caching
* **Elasticsearch/OpenSearch** for search

Example setup:

```
nginx → php-fpm → mysql/redis
```

---

## 🧼 Maintenance and Cleanup

The image automatically cleans up apt caches to reduce image size.
You can verify installed extensions with:

```bash
php -m
```

---

## 🪪 License

This image and Dockerfile are distributed under the **MIT License**.
Feel free to fork, modify, and use in your Magento setups.

---

### 💡 Maintained by

**Eric Ngigi**
Cloud Engineer & Magento Dockerization Enthusiast
