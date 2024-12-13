# Módulo Core
## Generación y configuración del módulo
Generar un motor montable
```sh
docker compose up -d
docker compose exec -it dev /bin/bash
rails plugin new core --mountable --skip-test-unit
```

Crear una carpeta engines y mover la carpeta core adentro
```sh
mkdir engines
mv core engines/
```
Todos los engines se ubicarán en esta carpeta para mantener el código organizado.

La carpeta SamuraiCRM/engines/core/lib contiene el corazón del engine y debe ser reorganizado para agregar un namespace.
El namespace a utilizar es Samurai. Para esto se requiere crear la carpeta samurai porque es la forma en que se realiza
esto en Ruby.
```sh
cd engines/core/lib
mkdir samurai
mv core core.rb samurai/
touch samurai_core.rb
```

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

Actualizar el archivo bin/rails
```ruby
# SamuraiCRM/engines/core/bin/rails
# ...
# Changed from 'lib/core/engine'
ENGINE_PATH = File.expand_path('../../lib/samurai/core/engine', __FILE__)
```

Agregar el namespace Samurai a routes.rb
```ruby
# SamuraiCRM/engines/core/config/routes.rb
Samurai::Core::Engine.routes.draw do
end
```

Agregar el módulo core al Gemfile de la aplicación padre
```ruby
# SamuraiCRM/Gemfile
# ...
gem 'samurai_core', path: 'engines/core'
```

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

Montar el engine dentro de la aplicación padre agregando esto a routes.rb
```ruby
# SamuraiCRM/config/routes.rb
Rails.application.routes.draw do
  mount Samurai::Core::Engine => "/", as: 'samurai'
end
```

Levantar el contenedor e ingresar a [localhost:3000](http://localhost:3000/)
```bash
docker compose up -d
```

## Agregar contenido al módulo
Por ahora se muestra la página por defecto de Rails, por lo que se procederá a agregar algún contenido.

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

Agregar la ruta
```ruby
# SamuraiCRM/engines/core/config/routes.rb
Samurai::Core::Engine.routes.draw do
  root to: "dashboard#index"
end
```

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
