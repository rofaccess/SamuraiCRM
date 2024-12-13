# Imagen base
FROM ruby:2.2

# Establece el directorio de trabajo
WORKDIR /app

# Copia el Gemfile al directorio de trabajo
COPY Gemfile Gemfile.lock ./

# Evita intalar los modulos porque en este punto todavía no se copiaron los módulos dentro del directorio de trabajo
# Esta variable de entorno se usa dentro del Gemfile para condicionar la instalación de los módulos
ENV INSTALL_MODULES=false
# Ejecuta el comando bundle para instalar las gemas
RUN bundle check || bundle install

# Copia el directorio actual del host dentro del directorio de trabajo del contenedor
COPY . .

# Ahora que ya se copió el código y los módulos se vuelve a instalar las gemas para que instale los módulos
ENV INSTALL_MODULES=true
RUN bundle install

# Se agrega y configura un usuario para evitar problemas de permisos en los archivos compartidos entre el host y el
# contenedor. Dar permisos a /usr/local/bundle es para evitar errores al generar la aplicación Rails.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /usr/local/bundle

USER 1000:1000

# Ejecuta la aplicación al levantar el contendedor
CMD ["rails", "s", "-b", "0.0.0.0"]
