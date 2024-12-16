# Módulo Core (Autenticación)
Agregar la gema devise
```ruby
# SamuraiCRM/engines/core/samurai_core.gemspec
# ...
s.add_dependency 'devise', '~> 3.4.1'
```

Agregar los correspondientes require dentro del engine
```ruby
# SamuraiCRM/engines/core/lib/samurai/core.rb
require 'sass-rails'
require 'bootstrap-sass'
require 'autoprefixer-rails'
require 'devise'
module Samurai
  module Core
  end
end
```

Ejecutar bundle install desde la aplicación padre.
```bash
docker compose run --rm -p 3000:3000 dev bash
bundle install
rails s -b 0.0.0.0
exit
```

Generar los archivos de devise desde el módulo core
```bash
docker compose up
docker compose exec -it dev bash
rails generate devise:install
```
Esto debe generar un archivo de configuración llamado devise.rb en core/config/initializers/
Agregar las siguientes dos líneas al final del archivo mencionado.
```ruby
# SamuraiCRM/engines/core/config/initializers/devise.rb
config.router_name = :samurai
config.parent_controller = 'Samurai::ApplicationController'
```
Esto le dice a Devise que va a ser ejecutado dentro de un engine, en usos normales en una aplicación, los valores por
defecto bastan.

Reorganizar los helpers
```bash
cd engines/core
mv app/helpers/core app/helpers/samurai
```

Agregar el namespace Samurai y un helper para mostrar mensajes flash a application_helper.rb
```ruby
# core/app/helpers/samurai/application_helper.rb
module Samurai
  module ApplicationHelper
    FLASH_CLASSES = {
      notice: "alert alert-info",
      success: "alert alert-success",
      alert: "alert alert-danger",
      error: "alert alert-danger"
    }
    
    def flash_class(level)
      FLASH_CLASSES[level]
    end
  end
end
```

Agregar el código para mostrar mensajes flash en el layout antes del jumbotron
```erb
<!-- SamuraiCRM/engines/core/app/views/layouts/samurai/application.html.erb -->
<!-- ... -->
<% flash.each do |key, value| %>
  <div class="<%= flash_class(key.to_sym) %>"><%= value %></div>
<% end %>
```

Generar el modelo User desde el módulo core
```bash
rails generate devise User
```

Las migraciones fueron generadas dentro del módulo core. Como no es práctico ejecutar las migraciones en cadá módulo. 
Se debe configurar el módulo para que la aplicación padre busque migraciones dentro de los módulos. Para esto se debe
agregar un initalizer dentro de la clase Engine del módulo.
```ruby
# SamuraiCRM/engines/core/lib/samurai/core/engine.rb
initializer :append_migrations do |app|
  unless app.root.to_s.match(root.to_s)
    config.paths["db/migrate"].expanded.each do |p|
      app.config.paths["db/migrate"] << p
    end
  end
end
```

Se deben realizar algunos ajuste para que Devise funcione dentro de otro engine.
Se debe modificar la ruta agregada en routes.rb para que quede así
```ruby
# SamuraiCRM/engines/core/config/routes.rb
devise_for :users, class_name: "Samurai::User", module: :devise
```
class_name le indica a Devise el modelo a utilizar y el parámetro module: :devise le indica que no se está ejecutando 
dentro de una aplicación Rails regular.


Ejecutar las migraciones desde la aplicación padre
```bash
rake db:migrate
```

Generar las vistas de Devise desde el módulo Core.
```bash
rails g devise:views
```

Agregar el método para autenticar usuarios en application_controller.rb
```ruby
# core/app/controllers/samurai/application_controller.rb
module Samurai
  module Core
    class ApplicationController < ActionController::Base
      before_action :authenticate_user!
    end
  end
end
```

Reiniciar la aplicación y acceder a [localhost:3000](http://localhost:3000/). Se realizará una redirección a la vista de login.
