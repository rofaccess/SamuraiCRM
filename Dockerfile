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
