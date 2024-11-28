# SamuraiCRM
Este repositorio contiene la implementación del proyecto SamuraiCRM presentado en el libro
"Modular Rails - The Complete Guide to Modular Rails Applications" de Thibault Denizet.

[Link al libro](https://www.pdfdrive.com/modular-rails-e196788894.html) del 2015 en la cual se basa este proyecto.

# Desarrollo e Implementación

## Preparación del entorno de desarrollo
Es mejor usar docker porque las versiones son un poco viejas.

Requisitos del proyecto
- Ruby: 2.2
- Rails: 4.2

Ubicarse en un directorio vacío y crear un Gemfile
```sh
mdkir SamuraiCRM
cd SamuraiCRM
touch Gemfile
```

Agregar el siguiente contenido al Gemfile
```yaml
source 'https://rubygems.org'

gem 'rails', '4.2'
```

Crear un Dockerfile
```sh
touch Dockerfile
```

Agregar el siguiente contenido al Dockerfile
```Dockerfile
# Imagen base
FROM ruby:2.2

# Establece el directorio de trabajo
WORKDIR /app

# Copia el Gemfile al directorio de trabajo
COPY Gemfile ./

# Ejecuta el comando bundle para instalar las gemas
RUN bundle check || bundle install

# Se agrega y configura un usuario para evitar problemas de permisos en los archivos compartidos entre el host y el
# contenedor. Dar permisos a /usr/local/bundle es para evitar errores al generar la aplicación Rails.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /usr/local/bundle

USER 1000:1000

# Se ejecuta el siguiente comando para que el contenedor quede activo y no finalice inmediatamente
CMD ["tail", "-f", "/dev/null"]
```

Crear el archivo de configuración de docker compose
```sh
touch compose.yaml
```

Agregar el siguiente contenido a compose.yaml
```yaml
services:
  dev:
    build: .
    volumes:
      - .:/app
```

Levantar el contenedor
```sh
docker compose up -d
```
- `-d`: Para que el contenedor se ejecute en segundo plano.

Ingresar al contenedor en ejecución
```sh
docker compose exec -it dev /bin/bash
```
