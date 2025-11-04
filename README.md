# Dockerized Akeneo & Magento Environment

This repository provides a containerized setup for **Akeneo** and **Magento**, using **Docker Compose** for orchestration. It includes custom Dockerfiles for PHP-FPM builds, configuration templates for Nginx, PHP, and MySQL, and CI/CD workflows for automated image builds.

---

## 🗂️ Project Structure

```
.
├── .git                     # Git version control directory
├── .github
│   └── workflows            # GitHub Actions CI/CD workflows
│       ├── akeneo-build.yml
│       └── magento-build.yml
├── .gitignore               # Git ignore rules
├── bin
│   └── generate-certs.sh    # Helper script for generating SSL certificates
├── docker-compose.yml       # Docker Compose file for multi-service orchestration
├── dockerfiles              # Custom Dockerfiles for application builds
│   ├── akeneo-php-fpm
│   │   ├── Dockerfile
│   │   └── README.md
│   └── magento-php-fpm
│       ├── Dockerfile
│       └── README.md
└── templates                # Configuration templates
    ├── mysql
    │   └── initdb.sql       # Initial database setup script
    ├── nginx
    │   ├── nginx.conf       # Main Nginx configuration
    │   └── templates
    │       ├── akeneo.conf.template
    │       └── magento.conf.template
    └── php
        ├── php              # PHP runtime configurations
        │   ├── akeneo
        │   │   ├── php.ini-development
        │   │   └── php.ini-production
        │   └── magento
        │       ├── php.ini-development
        │       └── php.ini-production
        └── php-fpm.d        # PHP-FPM pool and Docker overrides
            ├── akeneo
            │   ├── www.conf
            │   └── zz-docker.conf
            └── magento
                ├── www.conf
                └── zz-docker.conf
```

---

## ⚙️ Overview

* **Dockerfiles**
  Custom PHP-FPM images for Akeneo and Magento, optimized for performance and maintainability.

* **Templates**
  Modular templates for Nginx, PHP, and MySQL configurations, designed for flexibility across environments (development/production).

* **Workflows**
  GitHub Actions pipelines (`akeneo-build.yml`, `magento-build.yml`) automate image building and publishing.

* **Scripts**
  Utility scripts (like `generate-certs.sh`) simplify setup and SSL certificate management.

---

## 🚀 Usage

1. **Clone the repository:**

   ```bash
   git clone https://github.com/<your-org>/<repo-name>.git
   cd <repo-name>
   ```

2. **Generate certificates (optional):**

   ```bash
   ./bin/generate-certs.sh
   ```

3. **Start the services:**

   ```bash
   docker-compose up -d
   ```

4. **Access Applications:**

   * Akeneo: `http://localhost:8080`
   * Magento: `http://localhost:8090`

---

## 🧩 Customization

* Modify PHP or Nginx templates under `/templates` as needed.
* Update environment variables in `docker-compose.yml` to fit your setup.
* Extend GitHub Actions workflows for CI/CD customization.

---

## 🧱 Notes

* Ensure Docker and Docker Compose are installed.
* Recommended for local development and testing environments.
* Production deployments should include proper volume management and secret handling.
