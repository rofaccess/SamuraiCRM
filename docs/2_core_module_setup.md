# Módulo Core
## Parte 1: Configuración de la aplicación Rails
### Paso 1: Ingresar al contenedor y generar la aplicación
```sh
rails new SamuraiCRM --skip-test-unit # Crear el proyecto Rails
mv SamuraiCRM/* . # Mover el contenido del proyecto creado a la carpeta raiz
mv SamuraiCRM/.gitignore . # Mover archivos ocultos
rmdir SamuraiCRM # Borrar la carpeta del proyecto
```

Actualizar el Gemfile para evitar algunos errores de incompatiblidad entre gemas
```ruby
# Actualizar la versión de sqlite 3
gem 'sqlite3', '~> 1.3.6'
# Habilitar la gema therubyracer
gem 'therubyracer', platforms: :ruby
# Agregar y especificar versiones compatibles de las gemas loofah y execjs 
gem 'loofah', '2.19.1'
gem 'execjs', '2.6'
```

Actualizar las gemas dentro del contenedor y ejecutar la aplicación para comprobar su funcionamiento
```sh
bundle update
rails s
```

Salir del contendor y apagarlo
```sh
exit
docker compose down
```

Ahora se deben hacer algunos cambios para poder ejecutar Rails.

Actualizar el Dockerfile para copiar el proyecto dentro del contenedor.
```Dockerfile
# Imagen base
FROM ruby:2.2

# Establece el directorio de trabajo
WORKDIR /app

# Copia el Gemfile al directorio de trabajo
COPY Gemfile Gemfile.lock ./

# Ejecuta el comando bundle para instalar las gemas
RUN bundle check || bundle install

# Copia el directorio actual del host dentro del directorio de trabajo del contenedor
COPY . .

# Se agrega y configura un usuario para evitar problemas de permisos en los archivos compartidos entre el host y el
# contenedor. Dar permisos a /usr/local/bundle es para evitar errores al generar la aplicación Rails.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /usr/local/bundle

USER 1000:1000

# Ejecuta la aplicación al levantar el contendedor
CMD ["rails", "s", "-b", "0.0.0.0"]
```

Configurar un volumen para las gemas en compose.yaml y mapear el puerto 3000 del contenedor al puerto 3000 del host
```yaml
services:
  dev:
    build: .
    volumes:
      - .:/app
      - gems_data:/usr/local/bundle/gems
    ports:
      - "3000:3000"
volumes:
  gems_data:
```

Levantar el contenedor reconstruyendo la imagen
```sh
docker compose up --build -d
```
- `--build`: Reconstruye la imagen para que tome los cambios del Dockerfile

Acceder a http://localhost:3000/

### Paso 2: Acceder a la carpeta de la aplicación y generar un motor montable
```sh
docker compose up -d
docker compose exec -it dev /bin/bash
rails plugin new core --mountable --skip-test-unit
```

### Paso 3: Crear una carpeta engines y mover la carpeta core adentro
```sh
mkdir engines
mv core engines/
```
Todos los engines se ubicarán en esta carpeta para mantener el código organizado.

### Paso 4: Añadir un nivel más de espacio de nombres
La carpeta SamuraiCRM/engines/core/lib contiene el corazón del engine y debe ser reorganizado para agregar un namespace.
El namespace a utilizar es Samurai. Para esto se requiere crear la carpeta samurai porque es la forma en que se realiza
esto en Ruby.
```sh
cd engines/core/lib
mkdir samurai
mv core core.rb samurai/
touch samurai_core.rb
```

### Paso 5: samurai_core.rb y core.rb
Linkear el engine con la aplicación padre agregando a samurai_core.rb lo siguiente
```ruby
# SamuraiCRM/engines/core/lib/samurai_core.rb
require "samurai/core"
require "samurai/core/engine"
```

Actualizar core.rb agregando el namespace Samurai. En este archivo se cargan los módulos por primera vez antes de que el
engine se cargue
```ruby
# SamuraiCRM/engines/core/lib/samurai/core.rb
module Samurai
  module Core
  end
end
```

### Paso 6: Definir una versión
Agregarle al namespace Samurai a version.rb el cual define la versión del módulo core. Esto permite versionar las gemas
publicadas ya que el módulo core será publicado como gema.
```ruby
# SamuraiCRM/engines/core/lib/samurai/core/version.rb
module Samurai
  module Core
    VERSION = "0.0.1"
  end
end
```
### Paso 7: El archivo Engine
Se agrega el namespace al archivo engine.rb. Este archivo es el corazón del engine. También se quita Core por Samurai en
isolate_namespace.
```ruby
# SamuraiCRM/engines/core/lib/samurai/core/engine.rb
module Samurai
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Samurai
    end
  end
end
```
El método isolate_namespace marca un clara separación entre los controladores, modelos y rutas del motor con el contenido 
de la aplicación padre para evitar conflictos o sobreescrituras.

### Paso 8: Gemspec
Se actualiza el gemspec del engine, renombrandolo a samurai_core.gemspec

También se actualiza el contenido de la siguiente forma
```ruby
# SamuraiCRM/engines/core/samurai_core.gemspec
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "samurai/core/version" # Add samurai namespace

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "samurai_core"            # Rename core to samurai_core
  s.version     = Samurai::Core::VERSION    # Add namespace
  s.authors     = ["Rodrigo Fernandez"]     # Your name
  s.email       = ["rofaccess@gmail.com"]   # Your email
  s.homepage    = "https://github.com/rofaccess/SamuraiCRM"
  s.summary     = "Core features of SamuraiCRM."
  s.description = "Core features of SamuraiCRM."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.2.0"

  s.add_development_dependency "sqlite3"
end
```

### Paso 9: bin/rails
Actualizar el archivo bin/rails
```ruby
# SamuraiCRM/engines/core/bin/rails
# ...
# Changed from 'lib/core/engine'
ENGINE_PATH = File.expand_path('../../lib/samurai/core/engine', __FILE__)
```

### Paso 10: Las rutas del Core
Agregar el namespace Samurai a routes.rb
```ruby
# SamuraiCRM/engines/core/config/routes.rb
Samurai::Core::Engine.routes.draw do
end
```

### Paso 11: Agregar el módulo al Gemfile del padre
Agregar el módulo core al Gemfile de la aplicación padre
```ruby
# SamuraiCRM/Gemfile
# ...
gem 'samurai_core', path: 'engines/core'
```

### Paso 12: bundle install
Comprobar que los cambios realizados funcionen correctamente
```bash
docker compose run --rm -p 3000:3000 dev bash # Levantar el contenedor e ingresar dentro
bundle install # Se ejecuta esto para comprobar que los cambios realizados funcionen correctamente
rails s -b 0.0.0.0 # Probar la ejecución de la aplicación padre
exit
```
Al ejecutar bundle install se actualizará el archivo Gemfile.lock indicando que el módulo core fue instalado.

Se debería poder acceder a [localhost:3000](http://localhost:3000/), sino, verificar si se realizó todos los cambios correctamente.

**Obs.:** Se utilizó el comando run en vez de up, porque es más fácil determinar cualquier problema levantando e
ingresando dentro del contenedor en un mismo comando. Caso contrario habría que usar up y exec, pero si up falla por
algún error, exec ya no se puede usar para acceder a un contenedor que no se pudo levantar.

### Paso 13: Montar el motor
Montar el engine dentro de la aplicación padre agregando esto a routes.rb
```ruby
# SamuraiCRM/config/routes.rb
Rails.application.routes.draw do
  mount Samurai::Core::Engine => "/", as: 'samurai'
end
```

### Paso 14: Probar!
Levantar el contenedor e ingresar a [localhost:3000](http://localhost:3000/)
```bash
docker compose up -d
```

## Parte 2: El primer controlador
Por ahora se muestra la página por defecto de Rails, por lo que se procederá a agregar algún contenido.

### Paso 1: Reorganizar la carpeta controllers
Reestructurar los controladores según el namespace utilizado.
```bash
cd engines/core
mv app/controllers/core app/controllers/samurai
```

Actualizar el archivo ApplicationController.rb
```ruby
# SamuraiCRM/engines/core/app/controllers/samurai/application_controller.rb
module Samurai
  class ApplicationController < ActionController::Base
  end
end
```

## Paso 2: Crear el DashboardController
Crear un dashboard_controller con un index
```bash
touch app/controllers/samurai/dashboard_controller.rb
```

Agregar lo siguiente
```ruby
# SamuraiCRM/engines/core/app/controllers/samurai/dashboard_controller.rb
module Samurai
  class DashboardController < ApplicationController
    def index
    end
  end
end
```

### Paso 3: Agregar la ruta correspondiente
```ruby
# SamuraiCRM/engines/core/config/routes.rb
Samurai::Core::Engine.routes.draw do
  root to: "dashboard#index"
end
```

### Paso 4: Arreglar el layout y agregar un vista index para el dashboard
Reestructurar la carpeta views y agregar una vista. Ejecutar los comandos desde la carpeta engines/core.
```bash
mv app/views/layouts/core app/views/layouts/samurai
mkdir -p app/views/samurai/dashboard
touch app/views/samurai/dashboard/index.html.erb
```

Ejecutar la aplicación y acceder a [localhost:3000](http://localhost:3000/) para comprobar que todo funcione correctamente
```bash
docker compose up -d
```

## Parte 3: Estilizar la aplicación
Agregar la gema bootstrap-sass para estilizar la aplicación, para esto se deben agregar algunas gemas al gemspec del engine.

### Paso1: Agregar las gemas!
```ruby
# SamuraiCRM/engines/core/samurai_core.gemspec
# ...
s.add_dependency "rails", "~> 4.2.0"

s.add_dependency 'sass-rails', "~> 5.0.1"
s.add_dependency 'bootstrap-sass', "~> 3.3.3"
s.add_dependency 'autoprefixer-rails', "~> 5.1.5"
# ...
```
Las gemas usadas dentro de un engine no se cargan automáticamente. Para cargarlos se necesita agregar los correspondientes
require en el archivo core.rb de la gema.
```ruby
# SamuraiCRM/engines/core/lib/samurai/core.rb
require 'sass-rails'
require 'bootstrap-sass'
require 'autoprefixer-rails'

module Samurai
  module Core
  end
end
```

Para instalar estas gemas, se debe realizar unos cambios en el Dockerfile y reconstruir la imagen Docker.
```Dockerfile
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
```

También se requieren estos cambios en el Gemfile de la aplicación padre para condicionar la instalación de los módulos
```ruby
# SamuraiCRM/Gemfile
# ...
# Condición necesaria para construir la imagen Docker
if ENV['INSTALL_MODULES'] == 'true'
  gem 'samurai_core', path: 'engines/core'
end
```

Reconstruir la image docker
```bash
docker volume rm samuraicrm_gems_data # Borrar el volúmen de las gemas
docker compose up --build
```

**Obs.:** Si algo falla, se puede probar instalar las gemas manualmente ingresando al contenedor con docker compose run.
También se puede descomentar la línea command: ["tail", "-f", "/dev/null"] de composable.yml para ejecutar el contenedor
con docker compose up en modo de espera para luego ingresar al contenedor con docker compose exec.

Probar los siguientes comandos dentro del contenedor facilita la detección de problemas si es que no funciona la aplicación
con docker compose up.
```bash
docker compose run --rm -p 3000:3000 dev bash # Levantar el contenedor e ingresar dentro
bundle install # Se ejecuta esto para comprobar que los cambios realizados funcionen correctamente
rails s -b 0.0.0.0 # Probar la ejecución de la aplicación padre
exit
```

### Paso 2: Arreglar la carpeta assets
Reorganizar la carpeta assets. Ejecutar los siguientes comandos desde engines/core
```bash
mv app/assets/images/core app/assets/images/samurai
mv app/assets/javascripts/core app/assets/javascripts/samurai
mv app/assets/stylesheets/core app/assets/stylesheets/samurai
```

Renombrar application.css a application.css.scss y cargar Bootstrap css
```scss
// SamuraiCRM/engines/core/assets/stylesheets/samurai/application.css.scss
@import "bootstrap-sprockets";
@import "bootstrap";
body {
  padding-top: 65px; // For the nav bar
}
```

Cargar los archivos javascript de bootstrap
```js
// SamuraiCRM/engines/core/assets/stylesheets/samurai/application.js
//= require_tree .
//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
```

Ya que se reestructuraron los assets se debe actualizar el layout del módulo reemplazando core por samurai en los links
de los estilos y javascript.
También se agrega un contenido al tag body del layout.
```erb
<!-- SamuraiCRM/engines/core/app/views/layouts/samurai/application.html.erb -->
<!DOCTYPE html>
<html>
<head>
  <title>Core</title>
  <%= stylesheet_link_tag    "samurai/application", media: "all" %>
  <%= javascript_include_tag "samurai/application" %>
  <%= csrf_meta_tags %>
</head>
<body>

  <nav class="navbar navbar-inverse navbar-fixed-top">
    <div class="container">
      <div class="navbar-header">
        <%= link_to 'SamuraiCRM', samurai.root_path, class: 'navbar-brand' %>
   </div>
    </div>
  </nav>

  <div class='container' role='main'>
    <div class='jumbotron'>
      <%= yield %>
   </div>
  </div>

</body>
</html>
```
Es importante el uso de samurai.root_path en vez de solamente root_path. Esto es necesario para que la aplicación no se
rompa al intentar acceder a las vistas de Devise, el cual genera un conflicto al usar Devise dentro de un engine. 
Es recomdable usar el prefijo del namespace (samurai) in todas las rutas para evitar problemas potenciales.

Agrega un título al dashboard
```erb
<!-- SamuraiCRM/engines/core/app/views/samurai/dashboard/index.html.erb -->
<h2>Dashboard</h2>
<hr>
```

Acceder a la aplicación para ver los cambios
